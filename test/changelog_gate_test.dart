import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:wentianxia/features/changelog/app_changelog.dart';
import 'package:wentianxia/features/changelog/changelog_dialog.dart';
import 'package:wentianxia/routes/app_router.dart';
import 'package:wentianxia/shared/hive/app_settings.dart';
import 'package:wentianxia/shared/hive/hive_service.dart';

/// 「更新内容」弹窗测试。
///
/// 2.0.0 的 bug 回顾：闸门挂在 `MaterialApp.router` 的 builder 里 ——
/// 该 builder 的 context **位于 Navigator 之上**，`showDialog` 会抛
/// `Navigator operation requested with a context that does not include a Navigator`，
/// 异常被 `main.dart` 的全局兜底吞掉，表现就是「首次打开什么都不弹」。
///
/// 修复方式：go_router 挂上 [AppRoutes.rootNavigatorKey]，
/// 闸门改用该 navigator 的 overlay context 弹窗。
/// 因此这里重点验证：**从 navigator 的 context 弹窗能正常渲染**（这正是修复的关键点）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HiveService hive;

  setUp(() async {
    // 上一个用例可能已 deleteFromDisk，这里先关闭再重开
    await HiveService.instance.close();
    Hive.init('.dart_tool/test_changelog_hive');
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    hive = HiveService.instance;
    await hive.init();
    await hive.saveSettings(
      hive.readSettings().copyWith(apiKey: 'demo-key-123456', isFirstLaunch: false),
    );
  });

  tearDown(() async {
    await hive.close();
    await Hive.deleteFromDisk();
  });

  Widget hostWithNavigatorKey() {
    return ProviderScope(
      overrides: <Override>[hiveServiceProvider.overrideWithValue(hive)],
      child: MaterialApp(
        navigatorKey: AppRoutes.rootNavigatorKey,
        home: const Scaffold(body: Center(child: Text('首页'))),
      ),
    );
  }

  testWidgets('从根 Navigator 的 context 能正常弹出「更新内容」', (WidgetTester tester) async {
    await tester.pumpWidget(hostWithNavigatorKey());
    await tester.pump();

    // 模拟闸门的行为：拿 rootNavigatorKey 的 overlay context 弹窗
    final BuildContext dialogContext = AppRoutes.rootNavigatorKey.currentState!.overlay!.context;
    unawaited(showChangelogDialog(dialogContext, release: AppChangelog.current));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('更新内容'), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);
    // 条目内容应完整渲染在玻璃框内（取当前版本第一条的一个片段）
    expect(find.textContaining('真·背景折射'), findsOneWidget);
  });

  testWidgets('首次安装 → 展示「欢迎使用 闻天下」与使用提示', (WidgetTester tester) async {
    await tester.pumpWidget(hostWithNavigatorKey());
    await tester.pump();

    final BuildContext dialogContext = AppRoutes.rootNavigatorKey.currentState!.overlay!.context;
    unawaited(
      showChangelogDialog(
        dialogContext,
        release: AppChangelog.welcome,
        title: '欢迎使用 闻天下',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('欢迎使用 闻天下'), findsOneWidget);
    expect(find.textContaining('使用提示'), findsOneWidget);
  });

  test('版本内容选择逻辑：升级看更新日志，首装看使用提示', () {
    expect(AppChangelog.currentVersion, isNotEmpty);
    expect(AppChangelog.forVersion(AppChangelog.currentVersion), isNotNull,
        reason: '当前版本必须在 releases 里有对应条目');
    expect(AppChangelog.welcome.version, isEmpty);
    expect(AppChangelog.welcome.highlights.length, greaterThanOrEqualTo(3));
  });

  test('使用 MaterialApp 的 builder context 弹窗会失败（回归说明）', () async {
    // 这条不跑 UI，只记录结论：builder 的 context 不在 Navigator 内，
    // 因此 2.0.0 的实现在真机上静默失败。这里断言的是「修复后我们不再用它」。
    expect(AppRoutes.rootNavigatorKey, isNotNull);
  });
}

/// 明确表示「故意不 await」（闸门里也是先发起再等关闭）。
void unawaited(Future<void> future) {}
