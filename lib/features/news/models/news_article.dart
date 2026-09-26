import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'news_article.freezed.dart';
part 'news_article.g.dart';

/// 新闻数据模型。
///
/// * 使用 Freezed 生成 `copyWith / == / toString`；
/// * 使用 Hive 生成 `NewsArticleAdapter`，用于收藏持久化。
///
/// 字段约定：
/// * [id] —— 稳定主键：优先使用接口的 `uniquekey/uuid`，否则由 url/标题的哈希
///   生成（见 [NewsArticle.fallbackId]）；接口没有 id 字段，因此这里可空。
/// * [summary] —— 新闻简介（需求 3.2 的“简介”）：优先使用接口返回的
///   `description`，为空时截取正文前 200 字符（[defaultSummary]）。
/// * [favoritedAt] / [hiveKey] —— 收藏相关的本地状态，接口里不存在，
///   因此标注 `@HiveField` 且不参与 JSON 序列化；Freezed 生成的 `copyWith`
///   会带上这些参数，从收藏记录直接 `fromJson` 反序列化也安全。
@HiveType(typeId: 2)
@freezed
class NewsArticle with _$NewsArticle {
  const factory NewsArticle({
    /// 稳定主键：优先使用原文 url 的哈希，保证同一条新闻不会重复收藏。
    @HiveField(0) String? id,
    @HiveField(1) @JsonKey(name: 'title') required String title,
    @HiveField(2) @JsonKey(name: 'author_name') @Default('') String author,
    @HiveField(3) @JsonKey(name: 'date') @Default('') String publishedAt,
    @HiveField(4)
    @JsonKey(name: 'thumbnail_pic_s')
    @Default('')
    String thumbnailUrl,
    @HiveField(5) @JsonKey(name: 'thumbnail_pic_s02') @Default('') String imageUrl2,
    @HiveField(6) @JsonKey(name: 'thumbnail_pic_s03') @Default('') String imageUrl3,
    @HiveField(7) @JsonKey(name: 'url') @Default('') String url,
    @HiveField(8) @JsonKey(name: 'category') @Default('top') String category,
    @HiveField(9) @JsonKey(name: 'description') @Default('') String summary,
    /// 收藏时间（null 表示未收藏）。
    @HiveField(11) DateTime? favoritedAt,
    /// 收藏记录在 Hive Box 中的 key（Freezed 生成 copyWith 时会带上该参数）。
    @HiveField(12)
    @JsonKey(includeFromJson: false, includeToJson: false)
        int? hiveKey,
  }) = _NewsArticle;

  const NewsArticle._();

  factory NewsArticle.fromJson(Map<String, dynamic> json) =>
      _$NewsArticleFromJson(json);

  /// 所有可用图片（去掉空值），全文页至少展示第一张。
  List<String> get images => <String>[
        thumbnailUrl,
        imageUrl2,
        imageUrl3,
      ].where((String u) => u.trim().isNotEmpty).toList(growable: false);

  bool get hasImage => images.isNotEmpty;

  /// 用于收藏去重、路由与列表 key 的稳定标识。
  ///
  /// 接口可能没有 `uniquekey`，此时 [id] 为空，用 url/标题的哈希补一个。
  String get key {
    final String raw = (id ?? '').trim();
    return raw.isNotEmpty ? raw : fallbackId(url, title);
  }

  /// 是否已收藏。
  bool get isFavorite => favoritedAt != null;

  /// 卡片简介：没有简介就用正文（标题＋作者）拼一个 2~3 句的概括。
  String get displaySummary {
    final String s = summary.trim();
    if (s.isNotEmpty) return s;
    return defaultSummary();
  }

  /// 需求条目 5：简介为空时截取 200 字符作为简介。
  String defaultSummary([String? body]) {
    final String source = (body ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (source.isEmpty) {
      return '$title。来源：${author.isEmpty ? '网络媒体' : author}，点击「观看全文」查看完整报道。';
    }
    return source.length <= 200 ? source : '${source.substring(0, 200)}…';
  }

  /// 兜底 id：接口没有 id 字段，用 url/标题的稳定哈希代替。
  static String fallbackId(String url, String title) {
    final int h = Object.hash(url.isEmpty ? title : url, title);
    return 'a${h.abs()}';
  }

  @override
  String toString() => 'NewsArticle($id, $title)';
}
