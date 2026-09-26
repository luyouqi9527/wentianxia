import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主界面外壳：Material 3 [NavigationBar]（新闻 / 收藏）+ 毛玻璃背景。
///
/// 使用 [StatefulShellRoute] 的 `indexedStack`，切换 Tab 时保留各自页面状态
/// （新闻列表的滑动位置不会因为切到收藏而丢失）。
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onDestinationSelected(int index) {
    // 再次点击当前 Tab 时回到该分支的根页面。
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true, // 内容延伸到 NavigationBar 之下，毛玻璃才有背景可采样
      body: shell,
      bottomNavigationBar: RepaintBoundary(
        child: ClipRect(
          child: BackdropFilter(
            // 高斯模糊：sigmaX / sigmaY = 10
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: scheme.surface.withValues(alpha: 0.30),
              child: SafeArea(
                top: false,
                child: NavigationBar(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.article_outlined),
                      selectedIcon: Icon(Icons.article),
                      label: '新闻',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: '收藏',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
