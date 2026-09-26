import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/blur_container.dart';
import '../../../core/widgets/news_network_image.dart';
import '../../../routes/app_router.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../data/news_channels.dart';
import '../models/news_article.dart';

/// 单条新闻卡片（PageView 的一页）。
///
/// 布局：图片（约 38% 屏高）→ 标题（headlineSmall）→ 简介（bodyMedium）→
/// 「观看全文」毛玻璃按钮 + 收藏 / 分享 / 浏览器打开。
class NewsCard extends ConsumerWidget {
  const NewsCard({super.key, required this.article, required this.index});

  final NewsArticle article;
  final int index;

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final bool favorite =
        await ref.read(favoritesProvider.notifier).toggle(article);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(favorite ? '已加入收藏' : '已取消收藏'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final double imageHeight = size.height * 0.38;
    final bool favorite = ref.watch(isFavoriteProvider(article.key));
    final NewsChannel channel = channelOf(article.category);

    // 1.0.1：整张卡片不再包 RepaintBoundary。
    // 卡片内的毛玻璃按钮（观看全文 / 收藏）依赖 BackdropFilter 采样卡片自身的
    // 图片与渐变，若把卡片提升为独立层，采样会被截断 → 滑动时按钮下方出现
    // 图像缺失的空白带并闪烁。
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // 卡片底色：保证任何情况下都有不透明像素（图片加载失败时兜底）
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFF0E0E12)),
          ),
        ),
        // 顶部新闻图片。
        Hero(
          tag: 'article-image-${article.key}',
          child: NewsNetworkImage(
            url: article.thumbnailUrl,
            height: imageHeight,
            fallbackSeed: index,
            fallbackLabel: channel.label,
          ),
        ),
        // 从图片到底部的暗色渐变，保证文字可读。
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const <double>[0, 0.28, 0.55, 1],
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.88),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        // 文字与操作区。
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CategoryTag(channel: channel, publishedAt: article.publishedAt),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    shadows: const <Shadow>[
                      Shadow(blurRadius: 12, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(Icons.account_circle_outlined,
                        size: 15, color: Colors.white60),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        article.author.isEmpty ? '未知来源' : article.author,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.displaySummary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    BlurButton(
                      label: '观看全文',
                      icon: Icons.menu_book_outlined,
                      opacity: 0.2,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      onPressed: () => context.push(
                        '${AppRoutes.article}?id=${article.key}',
                        extra: article,
                      ),
                    ),
                    const Spacer(),
                    _RoundIconButton(
                      icon: favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? const Color(0xFFFF5C8A) : Colors.white,
                      tooltip: favorite ? '取消收藏' : '收藏',
                      onPressed: () => _toggleFavorite(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 分类 / 时间标签。
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.channel, required this.publishedAt});

  final NewsChannel channel;
  final String publishedAt;

  @override
  Widget build(BuildContext context) {
    final String time = publishedAt.length > 16
        ? publishedAt.substring(5, 16)
        : publishedAt;
    return BlurContainer(
      borderRadius: BorderRadius.circular(10),
      blur: 8,
      opacity: 0.16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      border: Border.all(color: Colors.white24, width: 0.6),
      child: Text(
        time.isEmpty
            ? '${channel.icon} ${channel.label}'
            : '${channel.icon} ${channel.label} · $time',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 圆形毛玻璃图标按钮。
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // 1.0.1：去掉 RepaintBoundary，避免 BackdropFilter 采样被截断（滑动时白带/闪烁）。
    final Widget button = BlurContainer(
      borderRadius: BorderRadius.circular(26),
      blur: 10,
      opacity: 0.2,
      border: Border.all(color: Colors.white24, width: 0.6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Icon(icon, size: 22, color: color ?? Colors.white),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
