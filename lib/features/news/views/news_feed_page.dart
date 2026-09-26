import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/blur_container.dart';
import '../../../routes/app_router.dart';
import '../data/news_channels.dart';
import '../providers/news_provider.dart';
import 'news_card.dart';

/// 「新闻」Tab：PageView 垂直滑动切换新闻（短视频式浏览体验）。
///
/// 刷新机制：在第一条新闻处继续向下拖拽（overscroll）即触发下拉刷新，
/// 重新调用聚合数据接口获取最新新闻列表。
class NewsFeedPage extends ConsumerStatefulWidget {
  const NewsFeedPage({super.key});

  @override
  ConsumerState<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends ConsumerState<NewsFeedPage> {
  final PageController _pageController = PageController();
  bool _refreshTriggered = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 首条新闻继续下滑 → 触发刷新。
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is! OverscrollNotification) return false;
    final bool pullingDown = notification.overscroll < 0;
    if (!pullingDown || _refreshTriggered) return false;
    if (_pageController.hasClients && _pageController.page != null) {
      if (_pageController.page!.round() != 0) return false;
    }
    _refreshTriggered = true;
    _refresh();
    return false;
  }

  Future<void> _refresh() async {
    await ref.read(newsFeedControllerProvider.notifier).refresh();
    _refreshTriggered = false;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: '重试',
            onPressed: () =>
                ref.read(newsFeedControllerProvider.notifier).refresh(),
          ),
        ),
      );
  }

  Future<void> _openChannelPicker() async {
    final String current = ref.read(selectedChannelProvider);
    final NewsChannel? picked = await showModalBottomSheet<NewsChannel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _ChannelSheet(current: current),
    );
    if (picked == null || !mounted) return;
    ref.read(selectedChannelProvider.notifier).state = picked.type;
    await ref
        .read(newsFeedControllerProvider.notifier)
        .loadCategory(picked.type);
  }

  @override
  Widget build(BuildContext context) {
    final NewsFeedState state = ref.watch(newsFeedControllerProvider);
    ref.listen<String?>(
      newsFeedControllerProvider.select((NewsFeedState s) => s.error),
      (String? previous, String? next) {
        if (next != null && next != previous) {
          _showSnack(next);
          ref.read(newsFeedControllerProvider.notifier).consumeError();
        }
      },
    );

    final String channel = ref.watch(selectedChannelProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // 主体：垂直 PageView。
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: _buildBody(state),
              ),
            ),
          ),
          // 顶部毛玻璃信息栏。
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              channelLabel: channelOf(channel).label,
              index: state.articles.isEmpty ? 0 : state.currentIndex + 1,
              total: state.articles.length,
              onTapChannel: _openChannelPicker,
              onRefresh: _refresh,
              onSettings: () => context.push(AppRoutes.settings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NewsFeedState state) {
    if (state.isLoading && state.articles.isEmpty) {
      return const _FeedSkeleton();
    }
    if (state.articles.isEmpty) {
      return _EmptyFeed(
        message: state.error ?? '暂时没有获取到新闻',
        onRetry: () => ref.read(newsFeedControllerProvider.notifier).load(),
      );
    }
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: state.articles.length,
      onPageChanged: (int index) {
        _refreshTriggered = false;
        ref.read(newsFeedControllerProvider.notifier).onPageChanged(index);
      },
      itemBuilder: (BuildContext context, int index) {
        return NewsCard(
          key: ValueKey<String>(state.articles[index].key),
          article: state.articles[index],
          index: index,
        );
      },
    );
  }
}

/// 顶部毛玻璃栏：应用名 / 频道切换 / 刷新 / 设置。
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.channelLabel,
    required this.index,
    required this.total,
    required this.onTapChannel,
    required this.onRefresh,
    required this.onSettings,
  });

  final String channelLabel;
  final int index;
  final int total;
  final VoidCallback onTapChannel;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.18),
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 14,
            right: 14,
            bottom: 10,
          ),
          child: Row(
            children: <Widget>[
              Text(
                '闻天下',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              BlurButton(
                label: channelLabel,
                icon: Icons.tune,
                opacity: 0.22,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                foregroundColor: Colors.white,
                onPressed: onTapChannel,
              ),
              const Spacer(),
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '$index / $total',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              _IconBlurButton(
                icon: Icons.refresh,
                tooltip: '刷新新闻',
                onPressed: onRefresh,
              ),
              const SizedBox(width: 8),
              _IconBlurButton(
                icon: Icons.settings_outlined,
                tooltip: '设置',
                onPressed: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBlurButton extends StatelessWidget {
  const _IconBlurButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlurContainer(
        borderRadius: BorderRadius.circular(14),
        blur: 10,
        opacity: 0.2,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// 频道选择弹窗（毛玻璃）。
class _ChannelSheet extends StatelessWidget {
  const _ChannelSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: BlurContainer(
          borderRadius: BorderRadius.circular(22),
          blur: 10,
          opacity: 0.28,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('切换频道', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllChannels
                    .map(
                      (NewsChannel c) => ActionChip(
                        label: Text('${c.icon} ${c.label}'),
                        backgroundColor: c.type == current
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                        onPressed: () => Navigator.of(context).pop(c),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 8),
              Text(
                '提示：聚合数据免费额度为 50 次/天，切换频道会增加一次请求。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首屏骨架屏。
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final double imageHeight = MediaQuery.sizeOf(context).height * 0.38;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              height: imageHeight,
              color: Colors.white10,
            ),
            const CircularProgressIndicator(),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '正在获取最新新闻…',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                '首次加载会依次请求你在引导页选择的兴趣频道。',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 空状态 / 错误状态。
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // 用可滚动容器包裹，保证 RefreshIndicator 在空状态下依然可用。
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        const Icon(Icons.cloud_off, size: 56, color: Colors.white38),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: BlurButton(
            label: '重新加载',
            icon: Icons.refresh,
            opacity: 0.22,
            foregroundColor: Colors.white,
            onPressed: onRetry,
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            '也可以在「设置」中检查 API Key 是否正确',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
