import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/hive/app_settings.dart';
import '../../../shared/hive/settings_provider.dart';
import '../models/article_content.dart';
import '../models/news_article.dart';
import '../repositories/news_repository.dart';

/// 新闻列表状态。
@immutable
class NewsFeedState {
  const NewsFeedState({
    this.articles = const <NewsArticle>[],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final List<NewsArticle> articles;
  final int currentIndex;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  bool get isEmpty => articles.isEmpty && !isLoading;

  NewsArticle? get current => (currentIndex >= 0 && currentIndex < articles.length)
      ? articles[currentIndex]
      : null;

  NewsFeedState copyWith({
    List<NewsArticle>? articles,
    int? currentIndex,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return NewsFeedState(
      articles: articles ?? this.articles,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 新闻流控制器：加载 / 刷新 / 手动切换频道。
class NewsFeedController extends StateNotifier<NewsFeedState> {
  NewsFeedController(this._ref) : super(const NewsFeedState()) {
    // 构造即加载首屏。
    load();
  }

  final Ref _ref;

  NewsRepository get _repo => _ref.read(newsRepositoryProvider);

  /// 首屏加载（仅在还没有数据时显示骨架屏）。
  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<NewsArticle> articles = await _repo.fetchArticles();
      state = state.copyWith(
        articles: articles,
        currentIndex: 0,
        isLoading: false,
        clearError: true,
      );
    } on Object catch (e) {
      debugPrint('新闻加载失败: $e');
      state = state.copyWith(isLoading: false, error: _message(e));
    }
  }

  /// 下拉刷新：在第一条新闻处继续向上滑动时触发。
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final List<NewsArticle> articles = await _repo.fetchArticles();
      state = state.copyWith(
        articles: articles,
        currentIndex: 0,
        isRefreshing: false,
        clearError: true,
      );
    } on Object catch (e) {
      debugPrint('刷新失败: $e');
      state = state.copyWith(isRefreshing: false, error: _message(e));
    }
  }

  /// 指定频道重新加载（首页频道切换）。
  Future<void> loadCategory(String type, {bool keepCurrent = false}) async {
    state = state.copyWith(
      isLoading: !keepCurrent && state.articles.isEmpty,
      isRefreshing: keepCurrent,
      clearError: true,
    );
    try {
      final List<NewsArticle> articles =
          await _repo.fetchArticles(categories: <String>[type]);
      state = state.copyWith(
        articles: articles,
        currentIndex: 0,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } on Object catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _message(e),
      );
    }
  }

  void onPageChanged(int index) {
    if (index == state.currentIndex) return;
    state = state.copyWith(currentIndex: index);
  }

  /// 消费掉错误（SnackBar 只提示一次）。
  void consumeError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  String _message(Object e) {
    final String raw = e.toString();
    if (raw.contains('10012')) {
      return '今日接口调用次数已用完（免费额度 50 次/天），请明天再试。';
    }
    if (raw.contains('10001') || raw.contains('10002')) {
      return 'API Key 无效，请到「设置」中重新填写聚合数据密钥。';
    }
    return raw.replaceFirst('Exception: ', '').replaceFirst('NewsApiException', '提示');
  }
}

/// 新闻流 Provider。
final StateNotifierProvider<NewsFeedController, NewsFeedState>
    newsFeedControllerProvider =
    StateNotifierProvider<NewsFeedController, NewsFeedState>((Ref ref) {
  return NewsFeedController(ref);
});

/// 当前展示的新闻（详情页需要）。
final Provider<NewsArticle?> currentArticleProvider =
    Provider<NewsArticle?>((Ref ref) {
  return ref.watch(newsFeedControllerProvider).current;
});

/// 当前选中的频道（默认取用户兴趣的第一个）。
final StateProvider<String> selectedChannelProvider =
    StateProvider<String>((Ref ref) {
  final AppSettings settings = ref.watch(currentSettingsProvider);
  return settings.effectiveCategories.first;
});

/// 全文内容（按文章缓存；`autoDispose` + 5 分钟 keepAlive 防止重复抓取）。
final AutoDisposeFutureProviderFamily<ArticleContent, NewsArticle>
    articleContentProvider =
    FutureProvider.autoDispose.family<ArticleContent, NewsArticle>(
  (Ref ref, NewsArticle article) async {
    final KeepAliveLink link = ref.keepAlive();
    final Timer timer = Timer(const Duration(minutes: 5), link.close);
    ref.onDispose(timer.cancel);
    return ref.watch(newsRepositoryProvider).fetchArticleContent(article);
  },
);
