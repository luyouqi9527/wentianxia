import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'shared/hive/hive_service.dart';

/// 应用入口。
///
/// 启动流程：
/// 1. 初始化 Hive（本地存储：API Key / 首次启动标记 / 收藏）。
/// 2. 读取本地持久化的设置（apiKey、selectedCategories、isFirstLaunch）。
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

  // 系统 UI 透明，配合毛玻璃沉浸式界面。
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

  // 初始化 Hive：数据库落在应用私有目录（Android: /data/data/<pkg>/app_flutter）。
  await Hive.initFlutter('wentianxia_db');
  await HiveService.instance.init();

  runApp(
    ProviderScope(
      overrides: <Override>[
        hiveServiceProvider.overrideWithValue(HiveService.instance),
      ],
      child: const WentianxiaApp(),
    ),
  );
}
