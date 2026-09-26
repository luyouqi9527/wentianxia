import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// 本地设置（Hive typeId 1）：
/// * [apiKey] —— 用户在引导页填写的聚合数据新闻 API Key（绝不硬编码在代码中）
/// * [selectedCategories] —— 用户勾选的兴趣频道
/// * [isFirstLaunch] —— 首次启动标记
@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  AppSettings({
    this.apiKey = '',
    List<String>? selectedCategories,
    this.isFirstLaunch = true,
    this.onboardingCompletedAt,
  }) : selectedCategories = selectedCategories ?? <String>[];

  @HiveField(0)
  String apiKey;

  @HiveField(1)
  List<String> selectedCategories;

  @HiveField(2)
  bool isFirstLaunch;

  @HiveField(3)
  DateTime? onboardingCompletedAt;

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
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.apiKey == apiKey &&
      other.isFirstLaunch == isFirstLaunch &&
      other.selectedCategories.join(',') == selectedCategories.join(',');

  @override
  int get hashCode =>
      Object.hash(apiKey, isFirstLaunch, selectedCategories.join(','));
}
