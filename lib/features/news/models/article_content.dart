/// 全文页展示所需的内容结构（纯 Dart，无需代码生成）。
class ArticleContent {
  const ArticleContent({
    this.title = '',
    this.source = '',
    this.author = '',
    this.publishedAt = '',
    this.images = const <String>[],
    this.paragraphs = const <String>[],
    this.fromNetwork = false,
  });

  final String title;

  /// 原文来源（站点名 / 媒体名）。
  final String source;
  final String author;
  final String publishedAt;

  /// 正文中的图片（至少取第一张用于展示）。
  final List<String> images;

  /// 正文段落。
  final List<String> paragraphs;

  /// 内容是否来自真实抓取（false 表示用了接口摘要兜底）。
  final bool fromNetwork;

  bool get isEmpty => paragraphs.isEmpty && images.isEmpty;

  int get charCount =>
      paragraphs.fold<int>(0, (int sum, String p) => sum + p.length);

  ArticleContent copyWith({
    String? title,
    String? source,
    String? author,
    String? publishedAt,
    List<String>? images,
    List<String>? paragraphs,
    bool? fromNetwork,
  }) {
    return ArticleContent(
      title: title ?? this.title,
      source: source ?? this.source,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      images: images ?? this.images,
      paragraphs: paragraphs ?? this.paragraphs,
      fromNetwork: fromNetwork ?? this.fromNetwork,
    );
  }

  static const ArticleContent empty = ArticleContent();
}
