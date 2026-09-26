import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/blur_container.dart';
import '../../../core/widgets/news_network_image.dart';
import '../../../routes/app_router.dart';
import '../../news/models/news_article.dart';
import '../../news/views/article_detail_page.dart';
import '../providers/favorites_provider.dart';

/// 「收藏」Tab：展示 Hive 中持久化的收藏新闻。
///
/// * 每条显示缩略图、标题、收藏时间；
/// * 支持左滑删除（[Dismissible]）；
/// * 数据来自 Hive，任何收藏变化自动刷新。
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    NewsArticle article,
  ) async {
    await ref.read(favoritesProvider.notifier).remove(article);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('已删除收藏'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(article),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<NewsArticle> favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: <Widget>[
          if (favorites.isNotEmpty)
            IconButton(
              tooltip: '清空收藏',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // 1.0.1：兜底玻璃底 —— 收藏为空或不足一屏时，底部毛玻璃导航栏
          // 下方依然有已绘制的像素，不会出现图像缺失的空白带/闪烁。
          const GlassBackdrop(
            colors: <Color>[
              Color(0xFF15121F),
              Color(0xFF0B0B10),
              Color(0xFF1B1330),
            ],
          ),
          Positioned.fill(
            child: favorites.isEmpty
                ? const _EmptyFavorites()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                    itemCount: favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final NewsArticle article = favorites[index];
                      return Dismissible(
                        key: ValueKey<String>('fav-${article.key}'),
                        direction: DismissDirection.endToStart,
                        background: _dismissBackground(theme),
                        onDismissed: (_) => _remove(context, ref, article),
                        child: _FavoriteTile(article: article),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dismissBackground(ThemeData theme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('清空收藏'),
        content: const Text('确定要删除全部收藏的新闻吗？该操作不可撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(favoritesProvider.notifier).clearAll();
    }
  }
}

/// 单条收藏项。
class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BlurContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      opacity: 0.12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(
            '${AppRoutes.article}?id=${article.key}',
            extra: article,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: NewsNetworkImage(
                    url: article.thumbnailUrl,
                    width: 96,
                    height: 72,
                    fallbackLabel: article.author,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.displaySummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(Icons.favorite,
                              size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            formatFavoriteTime(article.favoritedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (article.author.isNotEmpty)
                            Flexible(
                              child: Text(
                                article.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 空状态：占位图 + 提示文字。
class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BlurContainer(
              borderRadius: BorderRadius.circular(28),
              blur: 10,
              opacity: 0.14,
              padding: const EdgeInsets.all(26),
              child: Icon(
                Icons.bookmark_border,
                size: 54,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text('还没有收藏的新闻', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '在「新闻」中点击心形图标即可收藏，\n收藏内容会保存在本机，离线也能查看标题与摘要。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            BlurButton(
              label: '去浏览新闻',
              icon: Icons.article_outlined,
              opacity: 0.2,
              onPressed: () => context.go(AppRoutes.news),
            ),
          ],
        ),
      ),
    );
  }
}
