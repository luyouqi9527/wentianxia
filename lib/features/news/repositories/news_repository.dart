import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/news_api_exception.dart';
import '../../../shared/hive/app_settings.dart';
import '../../../shared/hive/hive_service.dart';
import '../data/news_channels.dart';
import '../models/article_content.dart';
import '../models/news_article.dart';
import '../services/article_html_parser.dart';

/// 聚合数据新闻头条接口地址。
const String kJuheToutiaoEndpoint = 'https://v.juhe.cn/toutiao/index';

/// 备选方案：The News API（免费额度更大，支持中文检索）。
const String kTheNewsApiEndpoint = 'https://api.thenewsapi.com/v1/news/top';

/// 请求新闻列表的超时时间。
const Duration kRequestTimeout = Duration(seconds: 15);

/// Dio 单例（带统一超时、UA 与 JSON 头）。
final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: kRequestTimeout,
      receiveTimeout: kRequestTimeout,
      sendTimeout: kRequestTimeout,
      responseType: ResponseType.json,
      headers: const <String, dynamic>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
      },
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }
  ref.onDispose(dio.close);
  return dio;
});

/// 抓取原文正文用的 Dio（HTML 文本）。
final Provider<Dio> htmlDioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 12),
      responseType: ResponseType.plain,
      headers: const <String, dynamic>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'zh-CN,zh;q=0.9',
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// 新闻数据仓库：读取 Hive 中的 API Key → 请求聚合数据接口 → 映射为 [NewsArticle]。
///
/// 说明：API Key 只在运行时从 Hive 读取，源码中不存在任何硬编码密钥。
class NewsRepository {
  NewsRepository({
    required Dio dio,
    required Dio htmlDio,
    required HiveService hive,
  })  : _dio = dio,
        _htmlDio = htmlDio,
        _hive = hive;

  final Dio _dio;
  final Dio _htmlDio;
  final HiveService _hive;

  static const int _htmlCacheLimit = 24;
  final Map<String, ArticleContent> _htmlCache = <String, ArticleContent>{};

  /// 当前使用的 API Key（来自本地存储）。
  String get apiKey => _hive.apiKey;

  AppSettings get settings => _hive.readSettings();

  /// 拉取新闻列表。
  ///
  /// [categories] 为空时使用引导页保存的兴趣频道（最多 3 个，控制每日请求次数）。
  Future<List<NewsArticle>> fetchArticles({List<String>? categories}) async {
    final String key = apiKey;
    if (key.isEmpty) {
      throw const NewsApiException('尚未配置聚合新闻 API Key，请先完成引导设置。');
    }

    final List<String> types = _resolveCategories(categories);

    // 备选方案：Key 写成 `thenewsapi:<token>` 时切换到 The News API。
    if (key.toLowerCase().startsWith('thenewsapi:')) {
      final List<NewsArticle> alt = await _fetchTheNewsApi(
        key.substring('thenewsapi:'.length).trim(),
        types.first,
      );
      await _hive.setLastRefresh(DateTime.now());
      return alt;
    }

    final List<List<NewsArticle>> results = <List<NewsArticle>>[];
    NewsApiException? lastError;

    for (final String type in types) {
      try {
        results.add(await _fetchJuhe(type, key));
      } on NewsApiException catch (e) {
        lastError = e;
      }
    }

    // 全部频道都失败 → 抛出最后一个错误（UI 展示 SnackBar + 重试）。
    if (results.isEmpty) {
      throw lastError ??
          const NewsApiException('新闻接口暂时不可用，请稍后重试。', isRateLimited: false);
    }

    final List<NewsArticle> merged = _mergeInterleaved(results);
    await _hive.setLastRefresh(DateTime.now());
    return merged;
  }

  /// 拉取全文内容：优先抓取原文 HTML，失败时退化为接口摘要。
  Future<ArticleContent> fetchArticleContent(NewsArticle article) async {
    final String url = article.url.trim();
    if (url.isEmpty) return _fallbackContent(article);

    final ArticleContent? cached = _htmlCache[url];
    if (cached != null) return cached;

    try {
      final Response<String> res = await _htmlDio.get<String>(url);
      final String html = res.data ?? '';
      final ArticleContent parsed =
          ArticleHtmlParser.parse(html, fallbackTitle: article.title);
      if (parsed.charCount >= 160) {
        final ArticleContent content = parsed.copyWith(
          title: parsed.title.isEmpty ? article.title : parsed.title,
          source: parsed.source.isEmpty ? article.author : parsed.source,
          author: article.author,
          publishedAt: article.publishedAt,
          images: _mergeImages(parsed.images, article.images),
        );
        _remember(url, content);
        return content;
      }
    } on Object catch (e) {
      debugPrint('原文抓取失败($url): $e');
    }

    final ArticleContent fallback = _fallbackContent(article);
    _remember(url, fallback);
    return fallback;
  }

  // ------------------------------------------------------------------ 内部

  List<String> _resolveCategories(List<String>? categories) {
    final List<String> source = (categories == null || categories.isEmpty)
        ? settings.effectiveCategories
        : categories;
    final Iterable<String> normalized = source
        .map<String>(normalizeChannelType)
        .where((String t) => t.trim().isNotEmpty);
    final List<String> unique = normalized.toSet().toList(growable: false);
    return unique.isEmpty ? <String>['top'] : unique.take(3).toList();
  }

  Future<List<NewsArticle>> _fetchJuhe(String type, String key) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      kJuheToutiaoEndpoint,
      queryParameters: <String, dynamic>{
        'type': type,
        'key': key,
        'page': 1,
        'page_size': 30,
        'is_filter': 1,
      },
    );

    final Map<String, dynamic>? body = _asMap(res.data);
    if (body == null) {
      throw const NewsApiException('新闻接口返回了无法解析的数据。');
    }

    final int? code = _asInt(body['error_code']);
    if (code != 0) {
      final String reason = (body['reason'] ?? '请求失败').toString();
      throw NewsApiException(
        _friendlyMessage(code, reason),
        code: code,
        isRateLimited: code == 10012 || code == 10001 || code == 10002,
      );
    }

    final Map<String, dynamic>? result = _asMap(body['result']);
    final List<dynamic> list = _asList(result?['data']);
    return _mapArticles(list, type);
  }

  /// 备选方案：The News API（在设置页把 API Key 写成 `thenewsapi:<token>`）。
  Future<List<NewsArticle>> _fetchTheNewsApi(String token, String type) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      kTheNewsApiEndpoint,
      queryParameters: <String, dynamic>{
        'api_token': token,
        'language': 'zh',
        'limit': 30,
      },
    );
    final Map<String, dynamic>? body = _asMap(res.data);
    final List<dynamic> list = _asList(body?['data']);
    return _mapArticles(list, type);
  }

  List<NewsArticle> _mapArticles(List<dynamic> raw, String type) {
    final List<NewsArticle> out = <NewsArticle>[];
    final Set<String> seen = <String>{};

    for (final dynamic item in raw) {
      final Map<String, dynamic>? json = _asMap(item);
      if (json == null) continue;

      final Map<String, dynamic> normalized = <String, dynamic>{
        ...json,
        'category': type,
        'url':
            (json['url'] ?? json['link'] ?? json['source_url'] ?? '').toString(),
        'title': (json['title'] ?? json['headline'] ?? '').toString(),
      };

      final String title = (normalized['title'] as String).trim();
      final String url = (normalized['url'] as String).trim();
      if (title.isEmpty && url.isEmpty) continue;

      final String id = _idOf(normalized, url, title);
      if (!seen.add(id)) continue;

      normalized['id'] = id;
      normalized['thumbnail_pic_s'] =
          (json['thumbnail_pic_s'] ?? json['image_url'] ?? json['image'] ?? '')
              .toString();
      normalized['author_name'] =
          (json['author_name'] ?? json['source'] ?? json['author'] ?? '')
              .toString();
      normalized['date'] = json['date'] ?? json['published_at'] ?? '';
      normalized['description'] =
          (json['description'] ?? json['snippet'] ?? json['summary'] ?? '')
              .toString();

      final NewsArticle article = NewsArticle.fromJson(normalized);
      if (article.title.isEmpty) {
        out.add(article.copyWith(title: _titleFromUrl(article.url)));
      } else {
        out.add(article);
      }
    }

    // 有图的新闻排前面，首屏体验更好。
    out.sort((NewsArticle a, NewsArticle b) {
      final int byImage = (b.hasImage ? 1 : 0) - (a.hasImage ? 1 : 0);
      if (byImage != 0) return byImage;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return out;
  }

  /// 多频道交替合并，避免同一频道的新闻扎堆。
  List<NewsArticle> _mergeInterleaved(List<List<NewsArticle>> groups) {
    final List<NewsArticle> out = <NewsArticle>[];
    final Set<String> seen = <String>{};
    int index = 0;
    bool hasMore = true;
    while (hasMore) {
      hasMore = false;
      for (final List<NewsArticle> group in groups) {
        if (index < group.length) {
          hasMore = true;
          final NewsArticle a = group[index];
          if (seen.add(a.key)) out.add(a);
        }
      }
      index++;
    }
    return out;
  }

  void _remember(String url, ArticleContent content) {
    if (_htmlCache.length >= _htmlCacheLimit) {
      _htmlCache.remove(_htmlCache.keys.first);
    }
    _htmlCache[url] = content;
  }

  ArticleContent _fallbackContent(NewsArticle article) {
    final String summary = article.summary.trim();
    final List<String> paragraphs = <String>[];
    if (summary.isNotEmpty) {
      paragraphs.addAll(
        summary
            .split(RegExp(r'(?<=[。！？!?])'))
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty),
      );
    }
    paragraphs.add(article.defaultSummary());
    paragraphs.add(
      '（本条内容来源于「${article.author.isEmpty ? '网络媒体' : article.author}」，'
      '受站点限制未能抓取到完整正文，可点击底部「阅读原文」查看完整报道。）',
    );
    return ArticleContent(
      title: article.title,
      source: article.author,
      author: article.author,
      publishedAt: article.publishedAt,
      images: article.images,
      paragraphs: paragraphs,
      fromNetwork: false,
    );
  }

  List<String> _mergeImages(List<String> a, List<String> b) {
    final List<String> out = <String>[...a, ...b];
    return out.toSet().toList(growable: false);
  }

  String _idOf(Map<String, dynamic> json, String url, String title) {
    final Object? raw = json['uniquekey'] ?? json['uuid'] ?? json['id'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }
    return NewsArticle.fallbackId(url, title);
  }

  String _titleFromUrl(String url) {
    if (url.isEmpty) return '未命名新闻';
    final Uri? uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : '未命名新闻';
  }

  String _friendlyMessage(int? code, String reason) {
    switch (code) {
      case 10001:
      case 10002:
      case 10003:
      case 10004:
        return 'API Key 无效或已过期（$reason），请到「设置」中重新填写聚合数据密钥。';
      case 10012:
        return '今日接口调用次数已用完（免费额度 50 次/天），请明天再试。';
      case 10020:
        return '接口维护中，请稍后再试。';
      default:
        return '新闻获取失败：$reason';
    }
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  List<dynamic> _asList(Object? value) => value is List ? value : <dynamic>[];

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// 仓库 Provider：自动从 Hive 读取 API Key。
final Provider<NewsRepository> newsRepositoryProvider =
    Provider<NewsRepository>((Ref ref) {
  return NewsRepository(
    dio: ref.watch(dioProvider),
    htmlDio: ref.watch(htmlDioProvider),
    hive: ref.watch(hiveServiceProvider),
  );
});
