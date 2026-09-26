import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/liquid_glass.dart';
import 'features/changelog/changelog_dialog.dart';
import 'routes/app_router.dart';
import 'shared/hive/settings_provider.dart';

/// 应用根组件：Material 3 + go_router + 全局玻璃材质注入。
class WentianxiaApp extends ConsumerWidget {
  const WentianxiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouterConfig config = ref.watch(appRouterProvider);
    // 磨砂材质（液态玻璃 / 高斯模糊）在这里注入，
    // 设置里切换后全站玻璃控件即时重建，无需重启。
    final GlassMaterial material = ref.watch(glassMaterialProvider);

    return MaterialApp.router(
      title: '闻天下',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: config.router,
      builder: (BuildContext context, Widget? child) {
        // 锁定文字缩放上限，避免超大字号破坏卡片布局。
        final MediaQueryData mq = MediaQuery.of(context);
        return GlassScope(
          material: material,
          child: MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.3,
              ),
            ),
            // 2.0.0：安装/更新后首次打开弹出「更新内容」
            child: AppChangelogGate(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
