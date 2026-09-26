import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../features/news/models/news_article.dart';
import 'app_settings.dart';

/// Hive 初始化与本地读写封装（单例）。
///
/// 负责三类数据：
/// 1. [settingsBox] —— `AppSettings`（API Key / 兴趣类别 / 首次启动标记）
/// 2. [favoritesBox] —— `Box<NewsArticle>` 收藏列表
/// 3. [metaBox] —— 简单键值对（最后刷新时间等）
///
/// 所有写操作都会 `flush()`，保证进程被杀死后数据仍然可读。
class HiveService {
  HiveService._();

  static final HiveService instance = HiveService._();

  static const String settingsBoxName = 'wentianxia_settings';
  static const String favoritesBoxName = 'wentianxia_favorites';
  static const String metaBoxName = 'wentianxia_meta';
  static const String settingsKey = 'app_settings';

  late Box<AppSettings> settingsBox;
  late Box<NewsArticle> favoritesBox;
  late Box<dynamic> metaBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 在 `runApp` 之前调用（main.dart）。
  ///
  /// 说明：这里显式注册 `NewsArticleAdapter`，即使 `hive_generator` 已经生成了
  /// `NewsArticleAdapter`，也只会注册一次，不会重复。
  Future<void> init() async {
    if (_initialized) return;

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(NewsArticleAdapter());
    }

    settingsBox = await Hive.openBox<AppSettings>(settingsBoxName);
    favoritesBox = await Hive.openBox<NewsArticle>(favoritesBoxName);
    metaBox = await Hive.openBox<dynamic>(metaBoxName);

    // 老版本升级兜底：确保存在一条设置记录。
    if (settingsBox.get(settingsKey) == null) {
      await settingsBox.put(settingsKey, AppSettings());
    }
    _initialized = true;
  }

  // ---------------------------------------------------------------- 设置

  AppSettings readSettings() =>
      settingsBox.get(settingsKey) ?? AppSettings();

  /// 关闭全部 Box 并重置初始化标记。
  ///
  /// 主要给测试用（用例之间需要重新打开同一份数据库）。
  /// 之前只调用 `Hive.deleteFromDisk()` 而不关闭 Box，会让后续
  /// `readSettings()` 抛 `Box has already been closed`。
  Future<void> close() async {
    if (!_initialized) return;
    await settingsBox.close();
    await favoritesBox.close();
    await metaBox.close();
    _initialized = false;
  }

  Future<void> saveSettings(AppSettings settings) async {
    await settingsBox.put(settingsKey, settings);
    await settingsBox.flush();
  }

  /// 引导页完成时调用：写入 API Key、兴趣类别，并把 isFirstLaunch 置为 false。
  Future<AppSettings> completeOnboarding({
    required String apiKey,
    required List<String> categories,
  }) async {
    final AppSettings next = readSettings().copyWith(
      apiKey: apiKey.trim(),
      selectedCategories: List<String>.of(categories),
      isFirstLaunch: false,
      onboardingCompletedAt: DateTime.now(),
    );
    await saveSettings(next);
    return next;
  }

  /// 请求新闻时从这里读取 API Key（不硬编码在任何地方）。
  String get apiKey => readSettings().apiKey.trim();

  List<String> get selectedCategories => readSettings().effectiveCategories;

  // ---------------------------------------------------------------- 收藏

  /// 收藏列表（按收藏时间倒序）。
  List<NewsArticle> favorites() {
    final List<NewsArticle> list = favoritesBox.values.toList();
    list.sort((NewsArticle a, NewsArticle b) {
      final DateTime da = a.favoritedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime db = b.favoritedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return list;
  }

  /// 收藏变化流（供 Riverpod 监听刷新）。
  Stream<void> watchFavorites() => favoritesBox.watch().map((BoxEvent event) => event.key).map((_) {});

  bool isFavorite(String id) => findFavoriteKey(id) != null;

  int? findFavoriteKey(String id) {
    for (final dynamic key in favoritesBox.keys) {
      final NewsArticle? a = favoritesBox.get(key);
      if (a != null && a.key == id) return key as int;
    }
    return null;
  }

  /// 收藏 / 取消收藏，返回收藏后的状态。
  Future<bool> toggleFavorite(NewsArticle article) async {
    final int? existingKey = findFavoriteKey(article.key);
    if (existingKey != null) {
      await favoritesBox.delete(existingKey);
      await favoritesBox.flush();
      return false;
    }
    final NewsArticle stored = article.copyWith(
      favoritedAt: DateTime.now(),
      hiveKey: null,
    );
    final int key = await favoritesBox.add(stored);
    await favoritesBox.put(key, stored.copyWith(hiveKey: key));
    await favoritesBox.flush();
    return true;
  }

  Future<void> removeFavorite(NewsArticle article) async {
    final int? key = findFavoriteKey(article.key);
    if (key != null) {
      await favoritesBox.delete(key);
      await favoritesBox.flush();
    }
  }

  // ---------------------------------------------------------------- 元数据

  Future<void> setLastRefresh(DateTime time) async {
    await metaBox.put('lastRefreshAt', time.toIso8601String());
  }

  DateTime? get lastRefreshAt {
    final Object? raw = metaBox.get('lastRefreshAt');
    return raw is String ? DateTime.tryParse(raw) : null;
  }
}

/// 供 Provider 覆盖 / 注入使用（main.dart 中覆盖为单例）。
final Provider<HiveService> hiveServiceProvider =
    Provider<HiveService>((Ref ref) => throw UnimplementedError(
          'hiveServiceProvider 必须在 ProviderScope 中覆盖为 HiveService.instance',
        ));
