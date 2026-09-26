import '../models/article_content.dart';

/// 极简 HTML 正文抽取器（不引入第三方 HTML 解析依赖，保证 CodeMagic 构建零风险）。
///
/// 抽取顺序：
/// 1. 去掉 `script / style / nav / footer / iframe` 等噪声块；
/// 2. 优先取 `<article>` 或 class 命中正文关键词的容器；
/// 3. 从容器里收集 `<p>` 文本（长度 >= [minParagraphLength]）与 `<img src>`；
/// 4. 文本不足时退化为“整页最长文本块”。
class ArticleHtmlParser {
  const ArticleHtmlParser._();

  static const int minParagraphLength = 12;

  /// 引号字符类（`["']`）。
  static const String _q = '["\']';

  /// 属性值：`[^"']+` —— 不跨越引号。
  static const String _qv = '[^"\']';

  static final RegExp _pTag = RegExp(
    '<p[^>]*>(.*?)</p>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _imgTag = RegExp(
    '<img[^>]+?(?:data-src|data-original|src)\\s*=\\s*$_q($_qv+)',
    caseSensitive: false,
  );
  /// `<meta>` 标签（property/content 顺序不固定，用 [metaContent] 取内容）。
  static final RegExp _metaTag = RegExp(
    '<meta\\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _propertyAttr = RegExp(
    'property\\s*=\\s*$_q($_qv+)',
    caseSensitive: false,
  );
  static final RegExp _contentAttr = RegExp(
    'content\\s*=\\s*$_q($_qv+)',
    caseSensitive: false,
  );
  static final RegExp _h1 = RegExp(
    '<h1[^>]*>(.*?)</h1>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _titleTag = RegExp(
    '<title[^>]*>(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _articleTag = RegExp(
    '<article[^>]*>(.*?)</article>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _noiseBlock = RegExp(
    r'<(script|style|noscript|nav|footer|header|form|svg|iframe|aside)\b[^>]*>.*?</\1>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _container = RegExp(
    '<(?:article|div|section)[^>]*(?:id|class)\\s*=\\s*$_q$_qv*'
    '(?:article-?content|artical-?content|articleContent|content-?body|news-?content'
    '|main-?content|post-?content|rich_?media|detail-?content|content)'
    '$_qv*$_q[^>]*>(.*?)</(?:article|div|section)>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _tag = RegExp(r'<[^>]+>');
  static final RegExp _whitespace = RegExp(r'[ \t\u00A0\u3000]+');
  static final RegExp _breaks = RegExp(r'\n{3,}');
  static final RegExp _sentenceBreak = RegExp(r'(?<=[。！？!?])');

  /// 解析 HTML，得到全文页所需的标题 / 来源 / 图片 / 段落。
  static ArticleContent parse(String html, {String? fallbackTitle}) {
    if (html.trim().isEmpty) {
      return ArticleContent(title: fallbackTitle ?? '');
    }

    final String cleaned = html
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
        .replaceAll(_noiseBlock, ' ');

    // 标题：og:title → <h1> → <title>
    final String? ogTitle = _metaContent(cleaned, 'og:title');
    final String? h1 = _firstGroup(_h1, cleaned);
    final String? docTitle = _firstGroup(_titleTag, cleaned);
    final String title =
        _cleanText(ogTitle ?? h1 ?? docTitle ?? fallbackTitle ?? '');

    // 正文容器
    final String? container =
        _firstGroup(_container, cleaned) ?? _firstGroup(_articleTag, cleaned);

    final List<String> scopes = <String>[
      if (container != null && container.trim().isNotEmpty) container,
      cleaned,
    ];

    List<String> paragraphs = <String>[];
    for (final String scope in scopes) {
      paragraphs = _paragraphsOf(scope);
      final int chars =
          paragraphs.fold<int>(0, (int s, String p) => s + p.length);
      if (chars >= 200) break;
    }

    if (paragraphs.isEmpty) {
      final String longest = _longestTextBlock(cleaned);
      if (longest.isNotEmpty) paragraphs = <String>[longest];
    }

    // 图片：正文图片优先，其次 og:image。
    final String? ogImage = _metaContent(cleaned, 'og:image');
    final List<String> images = <String>[
      ..._imagesOf(scopes.first),
      ..._imagesOf(cleaned),
      if (ogImage != null) ogImage,
    ];

    return ArticleContent(
      title: title,
      source: _cleanText(_metaContent(cleaned, 'og:site_name') ?? ''),
      images: _dedupe(images).take(6).toList(growable: false),
      paragraphs: _dedupe(paragraphs),
      fromNetwork: paragraphs.isNotEmpty,
    );
  }

  static List<String> _paragraphsOf(String scope) {
    final List<String> out = <String>[];
    for (final RegExpMatch m in _pTag.allMatches(scope)) {
      final String text = _cleanText(m.group(1) ?? '');
      if (text.length >= minParagraphLength) out.add(text);
    }
    if (out.isEmpty) {
      // 有些站点用 <br> 分段，退化为按句切分。
      final String text = _cleanText(scope);
      if (text.length >= 80) {
        out.addAll(
          text
              .split(_sentenceBreak)
              .map((String s) => s.trim())
              .where((String s) => s.length >= minParagraphLength),
        );
      }
    }
    return out;
  }

  static List<String> _imagesOf(String scope) {
    final List<String> out = <String>[];
    for (final RegExpMatch m in _imgTag.allMatches(scope)) {
      final String src = (m.group(1) ?? '').trim();
      if (src.startsWith('http') && !src.contains('logo')) out.add(src);
    }
    return out;
  }

  static String _longestTextBlock(String html) {
    final String text = _cleanText(html);
    if (text.length < 80) return '';
    return text.length <= 4000 ? text : text.substring(0, 4000);
  }

  static String? _firstGroup(RegExp re, String input) {
    final RegExpMatch? m = re.firstMatch(input);
    final String? v = m?.group(1);
    return (v == null || v.trim().isEmpty) ? null : v;
  }

  /// 读取 `<meta property="..." content="...">` 的内容。
  ///
  /// 站点写法不统一，`content` 可能出现在 `property` 之前，因此逐个 `<meta>`
  /// 标签解析属性，而不是拼一条固定顺序的正则。
  static String? _metaContent(String html, String property) {
    for (final RegExpMatch m in _metaTag.allMatches(html)) {
      final String tag = m.group(0) ?? '';
      final String? prop = _firstGroup(_propertyAttr, tag);
      if (prop == null || prop.trim().toLowerCase() != property) continue;
      final String? content = _firstGroup(_contentAttr, tag);
      if (content != null) return content;
    }
    return null;
  }

  /// 去标签 + 反转义 + 压缩空白。
  static String _cleanText(String raw) {
    String s = raw
        .replaceAll(_tag, '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&hellip;', '…')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');

    // 数字实体
    s = s.replaceAllMapped(
      RegExp(r'&#(\d{2,6});'),
      (Match m) {
        final int? code = int.tryParse(m.group(1)!);
        if (code == null || code <= 0 || code > 0x10FFFF) return '';
        return String.fromCharCode(code);
      },
    );
    s = s.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]{2,6});'),
      (Match m) {
        final int? code = int.tryParse(m.group(1)!, radix: 16);
        if (code == null || code <= 0 || code > 0x10FFFF) return '';
        return String.fromCharCode(code);
      },
    );

    s = s.replaceAll(_whitespace, ' ').replaceAll(_breaks, '\n');
    return s
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  static List<String> _dedupe(List<String> input) {
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final String item in input) {
      final String key = item.trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(key);
    }
    return out;
  }
}
