import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

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

/// 更新 API Key（设置页使用），同时刷新新闻数据。
final Provider<SettingsActions> settingsActionsProvider =
    Provider<SettingsActions>((Ref ref) => SettingsActions(ref));

class SettingsActions {
  SettingsActions(this._ref);

  final Ref _ref;

  Future<void> save({
    required String apiKey,
    required List<String> categories,
  }) async {
    await _ref.read(hiveServiceProvider).completeOnboarding(
          apiKey: apiKey,
          categories: categories,
        );
    // API Key / 频道变化后强制重新拉取新闻。
    _ref.invalidate(newsRepositoryProvider);
    await _ref.read(newsFeedControllerProvider.notifier).refresh();
  }
}
