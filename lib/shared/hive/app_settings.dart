import 'package:hive_ce/hive.dart';

part 'app_settings.g.dart';

/// 磨砂材质风格（2.0.0 起新增，可在「设置」里实时切换）。
enum GlassMode {
  /// 2.0.0 默认：液态玻璃（边缘折射 + 色散 + 边缘高光 + 内阴影）
  liquid('液态玻璃', '边缘折射 / 色散 / 高光 / 内阴影'),

  /// 1.x 的高斯模糊毛玻璃
  blur('高斯模糊', '经典毛玻璃，最省性能');

  const GlassMode(this.label, this.description);

  final String label;
  final String description;

  static GlassMode fromName(String? name) {
    for (final GlassMode mode in GlassMode.values) {
      if (mode.name == name) return mode;
    }
    return GlassMode.liquid;
  }
}

/// 本地设置（Hive typeId 1）：
/// * [apiKey] —— 用户在引导页填写的聚合数据新闻 API Key（绝不硬编码在代码中）
/// * [selectedCategories] —— 用户勾选的兴趣频道
/// * [isFirstLaunch] —— 首次启动标记
/// * [glassMode] —— 磨砂材质风格（液态玻璃 / 高斯模糊）
/// * [lastSeenVersion] —— 最近一次已阅读「更新内容」弹窗的版本号
@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  AppSettings({
    this.apiKey = '',
    List<String>? selectedCategories,
    this.isFirstLaunch = true,
    this.onboardingCompletedAt,
    this.glassMode = GlassMode.liquid,
    this.lastSeenVersion = '',
  }) : selectedCategories = selectedCategories ?? <String>[];

  @HiveField(0)
  String apiKey;

  @HiveField(1)
  List<String> selectedCategories;

  @HiveField(2)
  bool isFirstLaunch;

  @HiveField(3)
  DateTime? onboardingCompletedAt;

  @HiveField(4)
  GlassMode glassMode;

  @HiveField(5)
  String lastSeenVersion;

  /// 是否已经具备进入主界面的条件。
  bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// 是否已完成引导。
  bool get isReady => !isFirstLaunch && hasApiKey;

  /// 真正用于请求的频道：为空时回退到“头条”。
  List<String> get effectiveCategories =>
      selectedCategories.isEmpty ? const <String>['top'] : selectedCategories;

  AppSettings copyWith({
    String? apiKey,
    List<String>? selectedCategories,
    bool? isFirstLaunch,
    DateTime? onboardingCompletedAt,
    GlassMode? glassMode,
    String? lastSeenVersion,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      glassMode: glassMode ?? this.glassMode,
      lastSeenVersion: lastSeenVersion ?? this.lastSeenVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.apiKey == apiKey &&
      other.isFirstLaunch == isFirstLaunch &&
      other.glassMode == glassMode &&
      other.lastSeenVersion == lastSeenVersion &&
      other.selectedCategories.join(',') == selectedCategories.join(',');

  @override
  int get hashCode => Object.hash(
        apiKey,
        isFirstLaunch,
        glassMode,
        lastSeenVersion,
        selectedCategories.join(','),
      );
}
