import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:wentianxia/features/news/models/article_content.dart';
import 'package:wentianxia/features/news/models/news_article.dart';
import 'package:wentianxia/features/news/services/article_html_parser.dart';
import 'package:wentianxia/shared/hive/app_settings.dart';
import 'package:wentianxia/shared/hive/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init('.dart_tool/test_hive');
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(NewsArticleAdapter());
    }
    await HiveService.instance.init();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('Hive 本地存储', () {
    test('引导页保存 API Key / 兴趣类别，并把 isFirstLaunch 置为 false', () async {
      final AppSettings settings = await HiveService.instance.completeOnboarding(
        apiKey: '  demo-key-123456  ',
        categories: <String>['keji', 'tiyu'],
      );

      expect(settings.apiKey, 'demo-key-123456');
      expect(settings.isFirstLaunch, isFalse);
      expect(settings.selectedCategories, <String>['keji', 'tiyu']);
      expect(settings.isReady, isTrue);

      // 重新读取（模拟下次启动）依然有效。
      final AppSettings reloaded = HiveService.instance.readSettings();
      expect(reloaded.apiKey, 'demo-key-123456');
      expect(reloaded.effectiveCategories.first, 'keji');
    });

    test('收藏写入 / 取消收藏会同步到 Hive Box', () async {
      const NewsArticle article = NewsArticle(
        id: 'article-1',
        title: '测试新闻标题',
        author: '测试来源',
        url: 'https://example.com/a',
        summary: '测试摘要',
      );

      expect(await HiveService.instance.toggleFavorite(article), isTrue);
      expect(HiveService.instance.favorites().length, 1);
      expect(HiveService.instance.favorites().first.isFavorite, isTrue);

      expect(await HiveService.instance.toggleFavorite(article), isFalse);
      expect(HiveService.instance.favorites(), isEmpty);
    });
  });

  group('HTML 全文抽取', () {
    test('优先使用 <p> 段落并提取正文图片', () {
      const String html = '''
        <html><head>
          <title>文章标题 - 示例网</title>
          <meta property="og:title" content="文章标题" />
          <meta property="og:site_name" content="示例网" />
          <meta property="og:image" content="https://img.example.com/cover.jpg" />
        </head><body>
          <script>var a = 1;</script>
          <nav>导航栏内容不应该出现在正文里</nav>
          <div class="article-content">
            <p>这是第一段正文内容，长度足够被抽取出来。</p>
            <p>这是第二段正文内容，同样足够长以便通过长度阈值。</p>
            <img src="https://img.example.com/p1.jpg" />
          </div>
        </body></html>
      ''';

      final ArticleContent content =
          ArticleHtmlParser.parse(html, fallbackTitle: '兜底标题');

      expect(content.title, '文章标题');
      expect(content.source, '示例网');
      expect(content.paragraphs.length, 2);
      expect(content.paragraphs.first.startsWith('这是第一段'), isTrue);
      expect(content.images.contains('https://img.example.com/p1.jpg'), isTrue);
      expect(content.paragraphs.join().contains('导航栏'), isFalse);
      expect(content.charCount, greaterThan(20));
      expect(content.fromNetwork, isTrue);
    });

    test('空 HTML 时返回兜底标题而不是崩溃', () {
      final ArticleContent content =
          ArticleHtmlParser.parse('', fallbackTitle: '只有标题');
      expect(content.title, '只有标题');
      expect(content.isEmpty, isTrue);
    });
  });

  group('新闻模型', () {
    test('从聚合数据返回结构反序列化并生成简介', () {
      // id 由 NewsRepository 在归一化阶段写入（uniquekey / uuid / 兜底哈希）。
      final NewsArticle article = NewsArticle.fromJson(<String, dynamic>{
        'id': 'abc123',
        'uniquekey': 'abc123',
        'title': '某地发布新政策',
        'author_name': '新华网',
        'date': '2024-05-01 10:20',
        'category': 'top',
        'thumbnail_pic_s': 'https://img.example.com/a.jpg',
        'url': 'https://example.com/news/1',
        'description': '这是接口返回的简介内容。',
      });

      expect(article.key, 'abc123');
      expect(article.author, '新华网');
      expect(article.hasImage, isTrue);
      expect(article.displaySummary, '这是接口返回的简介内容。');
      expect(article.isFavorite, isFalse);
    });

    test('缺少简介时截取正文前 200 字符（需求条目 5）', () {
      const NewsArticle article = NewsArticle(
        id: 'x',
        title: '标题',
        url: 'https://example.com',
        summary: '',
      );
      final String body = List<String>.filled(500, '甲').join();
      final String summary = article.defaultSummary(body);
      expect(summary.length, 201); // 200 字符 + 省略号
      expect(summary.endsWith('…'), isTrue);
    });

    test('没有 url 时使用稳定哈希 id', () {
      final String a = NewsArticle.fallbackId('', '同一个标题');
      final String b = NewsArticle.fallbackId('', '同一个标题');
      expect(a, b);
      expect(a.startsWith('a'), isTrue);
    });
  });

  testWidgets('Material 3 主题下渲染基础组件不报错', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(body: Center(child: Text('闻天下'))),
      ),
    );
    expect(find.text('闻天下'), findsOneWidget);
  });
}
