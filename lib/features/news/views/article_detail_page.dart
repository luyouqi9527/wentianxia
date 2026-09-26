import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/share_service.dart';
import '../../../core/widgets/blur_container.dart';
import '../../../core/widgets/news_network_image.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../data/news_channels.dart';
import '../models/article_content.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';

/// 全文阅读页。
///
/// * 进入后自动滚动（[Timer] + [ScrollController]），速度可调（0.5x / 1x / 2x）；
/// * 页内至少展示一张图片；
/// * 显示作者 / 来源 / 时间；
/// * 底部毛玻璃操作栏：「阅读原文」（url_launcher）、收藏、分享。
class ArticleDetailPage extends ConsumerStatefulWidget {
  const ArticleDetailPage({super.key, this.article, this.articleId});

  /// 从列表页直接传入（最快，无需再查）。
  final NewsArticle? article;

  /// 深链 / 降级情况下的文章 id。
  final String? articleId;

  @override
  ConsumerState<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends ConsumerState<ArticleDetailPage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _autoScrollEnabled = true;

  /// 自动滚动基准速度：40 像素/秒（每 25ms 滚动 1px）。
  static const double _basePixelsPerTick = 1.0;
  static const int _tickMs = 25;
  double _speedMultiplier = 1.0;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double max = _scrollController.position.maxScrollExtent;
    final double offset = _scrollController.offset;
    final double next = max <= 0 ? 0 : (offset / max).clamp(0.0, 1.0);
    if ((next - _progress).abs() > 0.01 && mounted) {
      setState(() => _progress = next);
    }
    // 滚到底部自动停止。
    if (max > 0 && offset >= max - 1 && _autoScrollTimer != null) {
      _stopAutoScroll();
    }
  }

  /// 首帧渲染完成后再启动自动滚动（此时布局/滚动范围才可用）。
  void _scheduleAutoScroll() {
    if (_autoScrollTimer != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _autoScrollTimer == null) _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      if (!_scrollController.hasClients) return;
      final double max = _scrollController.position.maxScrollExtent;
      final double next =
          _scrollController.offset + _basePixelsPerTick * _speedMultiplier;
      if (next >= max) {
        _scrollController.jumpTo(max);
        _stopAutoScroll();
        return;
      }
      _scrollController.jumpTo(next);
    });
    if (mounted) setState(() => _autoScrollEnabled = true);
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (mounted) setState(() => _autoScrollEnabled = false);
  }

  void _toggleAutoScroll() {
    if (_autoScrollTimer == null) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _cycleSpeed() {
    const List<double> speeds = <double>[0.5, 1.0, 1.5, 2.0];
    final int index = speeds.indexOf(_speedMultiplier);
    setState(() => _speedMultiplier = speeds[(index + 1) % speeds.length]);
  }

  /// 优先使用列表页传入的文章；深链时从收藏 / 当前列表中回查。
  NewsArticle? _resolveArticle(WidgetRef ref) {
    if (widget.article != null) return widget.article;
    final String? id = widget.articleId;
    if (id == null) return null;
    final List<NewsArticle> favorites = ref.read(favoritesProvider);
    for (final NewsArticle a in favorites) {
      if (a.key == id) return a;
    }
    final NewsFeedState feed = ref.read(newsFeedControllerProvider);
    for (final NewsArticle a in feed.articles) {
      if (a.key == id) return a;
    }
    return null;
  }

  Future<void> _openOriginal(NewsArticle article) async {
    final Uri? uri = Uri.tryParse(article.url.trim());
    if (uri == null || !uri.hasScheme) {
      _snack('这条新闻没有可用的原文链接');
      return;
    }
    try {
      final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _snack('未能打开浏览器，请稍后重试');
    } on Object {
      _snack('未能打开浏览器，请稍后重试');
    }
  }

  Future<void> _toggleFavorite(NewsArticle article) async {
    final bool favorite =
        await ref.read(favoritesProvider.notifier).toggle(article);
    if (!mounted) return;
    _snack(favorite ? '已加入收藏（可在「收藏」Tab 查看）' : '已取消收藏');
  }

  Future<void> _share(NewsArticle article) async {
    final bool ok = await ShareService.shareText(
      title: article.title,
      text: '${article.title}\n${article.url}',
    );
    if (!mounted) return;
    if (!ok) _snack('分享失败，已复制链接到剪贴板');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final NewsArticle? article = _resolveArticle(ref);
    if (article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('全文阅读')),
        body: const Center(child: Text('未找到这篇新闻，请返回列表重试')),
      );
    }

    final AsyncValue<ArticleContent> contentAsync =
        ref.watch(articleContentProvider(article));
    final bool favorite = ref.watch(isFavoriteProvider(article.key));

    // 内容就绪后自动开始滚动（`articleContentProvider` 有缓存，二次进入时
    // listen 不会触发，因此这里单独处理“已有数据”的情况）。
    ref.listen<AsyncValue<ArticleContent>>(
      articleContentProvider(article),
      (AsyncValue<ArticleContent>? previous, AsyncValue<ArticleContent> next) {
        if (next.hasValue && !(previous?.hasValue ?? false)) {
          _scheduleAutoScroll();
        }
      },
    );
    if (contentAsync.hasValue) _scheduleAutoScroll();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Stack(
        children: <Widget>[
          // ① 兜底玻璃底：保证顶部/底部毛玻璃条下方永远有像素可采样
          //    （正文不足一屏时也不会出现图像缺失的空白带）
          const GlassBackdrop(
            colors: <Color>[Color(0xFF12121A), Color(0xFF0D0D12), Color(0xFF17142A)],
          ),
          // ② 正文内容（毛玻璃的真实采样源）。
          //    用 RepaintBoundary 把「整块滚动内容」作为一个稳定的层，
          //    而不是包在模糊控件外面——后者会截断 backdrop 采样（1.0.1 修复）。
          Positioned.fill(
            child: RepaintBoundary(
              child: contentAsync.when(
                loading: () => _buildLoading(article),
                error: (Object error, StackTrace stack) =>
                    _buildError(article, error),
                data: (ArticleContent content) =>
                    _buildContent(article, content),
              ),
            ),
          ),
          // ③ 顶部：返回 + 阅读进度。
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopProgressBar(
              progress: _progress,
              autoScrolling: _autoScrollEnabled,
              speed: _speedMultiplier,
              onToggleAutoScroll: _toggleAutoScroll,
              onCycleSpeed: _cycleSpeed,
            ),
          ),
          // ④ 底部毛玻璃操作栏。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(
              favorite: favorite,
              onOpenOriginal: () => _openOriginal(article),
              onToggleFavorite: () => _toggleFavorite(article),
              onShare: () => _share(article),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ 内容构建

  Widget _buildContent(NewsArticle article, ArticleContent content) {
    final ThemeData theme = Theme.of(context);
    final List<String> images = content.images.isNotEmpty
        ? content.images
        : article.images;
    final String author = article.author.isNotEmpty
        ? article.author
        : (content.author.isNotEmpty ? content.author : '未知来源');
    final String source = content.source.isNotEmpty ? content.source : author;
    final NewsChannel channel = channelOf(article.category);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 132),
      children: <Widget>[
        // 至少一张新闻图片。
        Hero(
          tag: 'article-image-${article.key}',
          child: NewsNetworkImage(
            url: images.isNotEmpty ? images.first : '',
            height: MediaQuery.sizeOf(context).height * 0.32,
            fallbackLabel: article.title,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  BlurContainer(
                    borderRadius: BorderRadius.circular(8),
                    blur: 8,
                    opacity: 0.18,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '${channel.icon} ${channel.label}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!content.fromNetwork)
                    BlurContainer(
                      borderRadius: BorderRadius.circular(8),
                      blur: 8,
                      opacity: 0.18,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: const Text('摘要模式', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(article.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.edit_note, size: 16, color: Colors.white54),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '作者：$author',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.public, size: 15, color: Colors.white54),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      source,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const Icon(Icons.schedule, size: 15, color: Colors.white38),
                  const SizedBox(width: 5),
                  Text(
                    article.publishedAt.isEmpty
                        ? '发布时间未知'
                        : article.publishedAt,
                    style: const TextStyle(color: Colors.white38, fontSize: 12.5),
                  ),
                  const Spacer(),
                  Text(
                    '${content.charCount} 字 · 约 ${_readingMinutes(content)} 分钟',
                    style: const TextStyle(color: Colors.white38, fontSize: 12.5),
                  ),
                ],
              ),
              const Divider(height: 34, color: Colors.white12),
            ],
          ),
        ),
        // 正文段落（中间穿插剩余图片）。
        ..._buildParagraphs(theme, content.paragraphs, images.skip(1).toList()),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
          child: Row(
            children: <Widget>[
              const Expanded(child: Divider(color: Colors.white12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '—— 全文完 ——',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white38),
                ),
              ),
              const Expanded(child: Divider(color: Colors.white12)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParagraphs(
    ThemeData theme,
    List<String> paragraphs,
    List<String> extraImages,
  ) {
    final List<Widget> widgets = <Widget>[];
    for (int i = 0; i < paragraphs.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Text(
            paragraphs[i],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      );
      // 每 4 段插一张正文图片。
      if (extraImages.isNotEmpty && (i + 1) % 4 == 0) {
        final String url = extraImages.removeAt(0);
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: NewsNetworkImage(url: url, height: 200),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  String _readingMinutes(ArticleContent content) {
    final int chars = content.charCount;
    if (chars <= 0) return '1';
    return (chars / 400).ceil().toString();
  }

  Widget _buildLoading(NewsArticle article) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        NewsNetworkImage(
          url: article.thumbnailUrl,
          height: MediaQuery.sizeOf(context).height * 0.32,
          fallbackLabel: article.title,
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(article.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 14),
              const Text(
                '正在抓取原文并生成全文…（离线时自动切换为摘要模式）',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(NewsArticle article, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 46, color: Colors.white54),
            const SizedBox(height: 12),
            Text('全文加载失败：$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 18),
            BlurButton(
              label: '重试',
              icon: Icons.refresh,
              opacity: 0.22,
              foregroundColor: Colors.white,
              onPressed: () =>
                  ref.invalidate(articleContentProvider(article)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部：返回按钮 + 阅读进度条 + 自动滚动控制。
class _TopProgressBar extends StatelessWidget {
  const _TopProgressBar({
    required this.progress,
    required this.autoScrolling,
    required this.speed,
    required this.onToggleAutoScroll,
    required this.onCycleSpeed,
  });

  final double progress;
  final bool autoScrolling;
  final double speed;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onCycleSpeed;

  @override
  Widget build(BuildContext context) {
    // 1.0.1：整条顶栏一次模糊 + 矩形裁剪（Clip.hardEdge），
    // 且顶部渐隐底色保证文字可读、模糊采样稳定。
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.68),
                Colors.black.withValues(alpha: 0.34),
              ],
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 6,
            left: 10,
            right: 10,
            bottom: 8,
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  // 顶栏内部的小按钮：静态半透明填充，避免嵌套 backdrop 层
                  GlassTint(
                    borderRadius: BorderRadius.circular(14),
                    opacity: 0.2,
                    tint: Colors.white,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  BlurButton(
                    label: autoScrolling ? '暂停自动滚动' : '自动滚动',
                    icon: autoScrolling ? Icons.pause : Icons.play_arrow,
                    opacity: 0.2,
                    flat: true,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: onToggleAutoScroll,
                  ),
                  const SizedBox(width: 8),
                  BlurButton(
                    label: '${speed}x',
                    icon: Icons.speed,
                    opacity: 0.2,
                    flat: true,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: onCycleSpeed,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部毛玻璃操作栏：阅读原文 / 收藏 / 分享。
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.favorite,
    required this.onOpenOriginal,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final bool favorite;
  final VoidCallback onOpenOriginal;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // 1.0.1：整条操作栏只做一次模糊；栏内按钮改用静态半透明填充（GlassTint），
    // 避免同一条 bar 上嵌套多个 backdrop 层导致滑动时色带/闪烁。
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.72),
                Colors.black.withValues(alpha: 0.38),
              ],
            ),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenOriginal,
                  icon: const Icon(Icons.open_in_browser, size: 19),
                  label: const Text('阅读原文'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GlassTint(
                borderRadius: BorderRadius.circular(16),
                opacity: 0.18,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onToggleFavorite,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: favorite ? const Color(0xFFFF5C8A) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GlassTint(
                borderRadius: BorderRadius.circular(16),
                opacity: 0.18,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onShare,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Icon(Icons.share_outlined,
                          size: 21, color: scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 收藏时间格式化（收藏页复用）。
String formatFavoriteTime(DateTime? time) {
  if (time == null) return '未知时间';
  return DateFormat('yyyy-MM-dd HH:mm').format(time);
}
