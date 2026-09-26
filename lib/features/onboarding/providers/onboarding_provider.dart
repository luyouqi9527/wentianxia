import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/hive/hive_service.dart';
import '../../news/data/news_channels.dart';
import '../views/onboarding_page.dart';

/// 引导页状态。
@immutable
class OnboardingState {
  const OnboardingState({
    this.selectedCategories = const <String>{},
    this.saving = false,
    this.error,
  });

  final Set<String> selectedCategories;
  final bool saving;
  final String? error;

  OnboardingState copyWith({
    Set<String>? selectedCategories,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 引导页控制器：勾选兴趣 + 保存到 Hive。
class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._hive) : super(const OnboardingState());

  final HiveService _hive;

  /// 切换某个兴趣类别（默认预置「头条」，保证任何时候都有内容可看）。
  void toggleCategory(String type) {
    final Set<String> next = Set<String>.of(state.selectedCategories);
    if (!next.remove(type)) next.add(type);
    state = state.copyWith(selectedCategories: next, clearError: true);
  }

  /// 校验 + 持久化：
  /// 写入 apiKey、selectedCategories，并把 isFirstLaunch 置为 false。
  Future<bool> complete({required String apiKey}) async {
    final String key = apiKey.trim();
    if (key.isEmpty) {
      state = state.copyWith(error: 'API Key 不能为空');
      return false;
    }

    final Set<String> selected = state.selectedCategories.isEmpty
        ? <String>{kAllChannels.first.type}
        : state.selectedCategories;

    state = state.copyWith(saving: true, clearError: true);
    try {
      await _hive.completeOnboarding(
        apiKey: key,
        categories: selected.toList(growable: false),
      );
      state = state.copyWith(saving: false, selectedCategories: selected);
      return true;
    } on Object catch (e) {
      debugPrint('保存引导设置失败: $e');
      state = state.copyWith(saving: false, error: '保存失败：$e');
      return false;
    }
  }
}

/// 引导页 Provider。
final StateNotifierProvider<OnboardingController, OnboardingState>
    onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((Ref ref) {
  return OnboardingController(ref.watch(hiveServiceProvider));
});

/// 引导页要展示的官方帮助链接（供测试/分享使用）。
const String onboardingHelpUrl = kJuheApplyUrl;
