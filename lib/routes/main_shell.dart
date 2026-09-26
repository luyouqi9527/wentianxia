import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/blur_container.dart';

/// 主界面外壳：Material 3 [NavigationBar]（新闻 / 收藏）+ 毛玻璃背景。
///
/// 使用 [StatefulShellRoute] 的 `indexedStack`，切换 Tab 时保留各自页面状态
/// （新闻列表的滑动位置不会因为切到收藏而丢失）。
///
/// ## 1.0.1 修复说明
/// 这里原先给 `bottomNavigationBar` 包了一层 `RepaintBoundary`，导致
/// `BackdropFilter` 的采样范围被截断在独立层内 —— 滑动时 NavigationBar
/// 下方会出现**图像缺失的空白带并闪烁**。
/// 现在：
/// * 去掉 `RepaintBoundary`，让 `BackdropFilterLayer` 直接挂在 Scaffold 层上，
///   从而能采样到 `body`（`extendBody: true`，页面内容铺满整屏）；
/// * 用 [GlassBackdrop] 兜底铺满全屏，即使当前 Tab 内容不足一屏，
///   导航栏下方也永远有已绘制的像素可采样。
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
      body: Stack(
        children: <Widget>[
          // ① 兜底玻璃底：保证导航栏下方永远有像素（内容不足一屏时也不会出现空白带）
          const GlassBackdrop(),
          // ② 页面内容（铺满整屏，是毛玻璃真正的采样源）
          Positioned.fill(child: shell),
        ],
      ),
      bottomNavigationBar: ClipRect(
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
    );
  }
}
