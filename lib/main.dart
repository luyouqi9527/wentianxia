import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/liquid_glass.dart';
import 'shared/hive/hive_service.dart';
import 'shared/hive/settings_provider.dart';

/// 应用入口。
///
/// 启动流程：
/// 1. 初始化 Hive（本地存储：API Key / 首启标记 / 收藏 / 材质偏好）。
/// 2. **加载液态玻璃折射着色器**（`shaders/liquid_glass.frag`）。
///    加载失败或引擎不支持（Skia）时返回 null，玻璃自动降级为解析式折射，不会崩。
/// 3. 交给 go_router 的 redirect 决定进入引导页还是主界面。
///
/// 注意：聚合数据 API Key 完全由用户在引导页填写并保存在 Hive 中，
/// 代码里不存在任何硬编码密钥。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 未捕获异常兜底，避免 release 包静默白屏。
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('未捕获异常: $error');
    return true;
  };

  // 系统 UI 透明，配合玻璃沉浸式界面。
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

  // 初始化 Hive：数据库落在应用私有目录（Android: /data/data/<pkg>/app_flutter）。
  await Hive.initFlutter('wentianxia_db');
  await HiveService.instance.init();

  // 加载液态玻璃着色器（真·背景折射）。
  // 必须在 runApp 之前完成：否则首帧会先用解析式折射，
  // 之后切成真折射时能看到一次跳变。
  final FragmentProgram? glassShader = await LiquidGlassShader.load();

  runApp(
    ProviderScope(
      overrides: <Override>[
        hiveServiceProvider.overrideWithValue(HiveService.instance),
        glassShaderProvider.overrideWithValue(glassShader),
      ],
      child: const WentianxiaApp(),
    ),
  );
}
