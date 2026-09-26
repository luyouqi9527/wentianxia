import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/widgets/liquid_glass.dart';
import '../../features/news/providers/news_provider.dart';
import '../../features/news/repositories/news_repository.dart';
import 'app_settings.dart';
import 'hive_service.dart';

/// 本地设置流：Hive Box 变化 → 新的 [AppSettings]。
/// 路由 redirect 依赖它判断是否需要进入引导页。
final StreamProvider<AppSettings> settingsProvider =
    StreamProvider<AppSettings>((Ref ref) {
  final HiveService hive = ref.watch(hiveServiceProvider);

  Stream<AppSettings> watch() async* {
    yield hive.readSettings();
    yield* hive.settingsBox
        .watch()
        .map((BoxEvent _) => hive.readSettings());
  }

  return watch();
});

/// 高频访问的同步只读视图，避免在 build 中反复 await。
final Provider<AppSettings> currentSettingsProvider =
    Provider<AppSettings>((Ref ref) {
  final AsyncValue<AppSettings> async = ref.watch(settingsProvider);
  return async.valueOrNull ?? ref.watch(hiveServiceProvider).readSettings();
});

/// 当前磨砂材质风格（设置里可切换：液态玻璃 / 高斯模糊）。
final Provider<GlassMode> glassModeProvider = Provider<GlassMode>((Ref ref) {
  return ref.watch(currentSettingsProvider).glassMode;
});

/// 由 [GlassMode] 解析出的实际渲染材质，注入到根部的 [GlassScope]。
final Provider<GlassMaterial> glassMaterialProvider =
    Provider<GlassMaterial>((Ref ref) {
  final GlassMode mode = ref.watch(glassModeProvider);
  return mode == GlassMode.liquid
      ? GlassMaterial.liquid()
      : GlassMaterial.blur();
});

/// 更新 API Key / 兴趣频道（设置页使用），同时刷新新闻数据。
final Provider<SettingsActions> settingsActionsProvider =
    Provider<SettingsActions>((Ref ref) => SettingsActions(ref));

class SettingsActions {
  SettingsActions(this._ref);

  final Ref _ref;

  Future<void> save({
    required String apiKey,
    required List<String> categories,
  }) async {
    final HiveService hive = _ref.read(hiveServiceProvider);
    final AppSettings current = hive.readSettings();
    await hive.saveSettings(
      await hive.completeOnboarding(
        apiKey: apiKey,
        categories: categories,
      ).then((AppSettings s) => s.copyWith(glassMode: current.glassMode)),
    );
    // API Key / 频道变化后强制重新拉取新闻。
    _ref.invalidate(newsRepositoryProvider);
    await _ref.read(newsFeedControllerProvider.notifier).refresh();
  }

  /// 切换磨砂材质（无需重启，界面即时重建）。
  Future<void> setGlassMode(GlassMode mode) async {
    final HiveService hive = _ref.read(hiveServiceProvider);
    await hive.saveSettings(hive.readSettings().copyWith(glassMode: mode));
  }

  /// 标记「更新内容」弹窗已阅读。
  Future<void> markVersionSeen(String version) async {
    final HiveService hive = _ref.read(hiveServiceProvider);
    await hive.saveSettings(
      hive.readSettings().copyWith(lastSeenVersion: version),
    );
  }
}
