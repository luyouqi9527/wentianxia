import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/blur_container.dart';
import '../../routes/app_router.dart';
import '../../shared/hive/app_settings.dart';
import '../../shared/hive/settings_provider.dart';
import 'app_changelog.dart';

/// 「更新内容」弹窗：安装 / 更新后首次打开自动展示，也可在设置里手动打开。
///
/// 弹窗本身也使用液态玻璃材质（跟随设置里的材质开关）。
Future<void> showChangelogDialog(
  BuildContext context, {
  AppRelease? release,
  String? title,
}) {
  final AppRelease target = release ?? AppChangelog.current;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (BuildContext context) =>
        ChangelogDialog(release: target, title: title),
  );
}

/// 「更新内容」弹窗内容。
class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key, required this.release, this.title});

  final AppRelease release;

  /// 标题；为空时按是否为「首次安装」自动选择。
  final String? title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // 2.0.1 修复：内容超高时不再溢出玻璃框外。
    // 之前 `Column(mainAxisSize.min) + Flexible(SingleChildScrollView)` 组合会让
    // 滚动区拿不到有界高度，条目一多就把文字挤出圆角边界。
    // 现在给整块内容一个「不超过屏幕 62%」的硬上限，超出部分在框内滚动。
    final double maxBodyHeight =
        MediaQuery.sizeOf(context).height * 0.62;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: BlurContainer(
        borderRadius: BorderRadius.circular(26),
        opacity: 0.16,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        materialize: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                BlurContainer(
                  borderRadius: BorderRadius.circular(14),
                  opacity: 0.22,
                  padding: const EdgeInsets.all(9),
                  child: const Icon(Icons.auto_awesome, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title ?? (release.version.isEmpty ? '欢迎使用 闻天下' : '更新内容'),
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        release.version.isEmpty
                            ? '闻天下 v${AppChangelog.currentVersion} · 使用提示'
                            : '闻天下 v${release.version} · ${release.date}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 有界高度：条目再多也只占屏幕 62%，超出部分在框内滚动，
            // 保证文字永远不会跑到玻璃圆角外面。
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxBodyHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: release.highlights
                      .map(
                        (String item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('开始使用'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 启动闸门：如果本地记录的 `lastSeenVersion` 与当前版本不一致，
/// 就在首帧之后弹出「更新内容」，用户关闭后才写入记录。
///
/// ## 2.0.1 修复
/// 2.0.0 把这个闸门挂在 `MaterialApp.router` 的 `builder` 里，而 **builder 位于
/// Navigator 之上**，于是 `showDialog` 抛
/// `Navigator operation requested with a context that does not include a Navigator`，
/// 异常又被 `main.dart` 的全局兜底吞掉 —— 表现就是「首次打开什么都没弹」。
///
/// 现在改用 go_router 的根 navigator（[AppRoutes.rootNavigatorKey]）取 context，
/// 并且**在任何 await 之前**先把需要的状态读出来（避免异步里再用 ref）。
class AppChangelogGate extends ConsumerStatefulWidget {
  const AppChangelogGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppChangelogGate> createState() => _AppChangelogGateState();
}

class _AppChangelogGateState extends ConsumerState<AppChangelogGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_done || !mounted) return;
    _done = true;

    // ① 全部同步读取：await 之后不再碰 ref / context
    final SettingsActions actions = ref.read(settingsActionsProvider);
    final AppSettings settings = ref.read(currentSettingsProvider);
    final String seen = settings.lastSeenVersion;
    debugPrint('[changelog] seen=$seen current=${AppChangelog.currentVersion} '
        'firstLaunch=${settings.isFirstLaunch}');
    if (seen == AppChangelog.currentVersion) return;

    final NavigatorState? navigator = AppRoutes.rootNavigatorKey.currentState;
    debugPrint('[changelog] navigator=$navigator');
    if (navigator == null) return;

    // 首次安装（还没走过引导）→ 展示「使用提示」；
    // 已经用过老版本 → 展示本版本「更新内容」。
    final bool firstInstall = settings.isFirstLaunch || seen.isEmpty;
    final AppRelease release =
        firstInstall ? AppChangelog.welcome : AppChangelog.current;
    final String dialogTitle = firstInstall ? '欢迎使用 闻天下' : '更新内容';

    // ② 等首帧稳定，避免与启动时的路由跳转抢帧
    await Future<void>.delayed(const Duration(milliseconds: 400));
    debugPrint('[changelog] delay done, presenting...');

    // ③ 弹窗（所有 BuildContext 都在 _present 内同步取用）
    await _present(navigator, release, dialogTitle);
    debugPrint('[changelog] dialog closed, marking seen');
    await actions.markVersionSeen(AppChangelog.currentVersion);
    debugPrint('[changelog] marked seen');
  }

  /// 用根 Navigator 的 overlay context 弹窗。
  ///
  /// `MaterialApp.router` 的 builder context 位于 Navigator **之上**，
  /// 在那种 context 上 `showDialog` 会抛
  /// `Navigator operation requested with a context that does not include a Navigator`。
  Future<void> _present(
    NavigatorState navigator,
    AppRelease release,
    String title,
  ) {
    final BuildContext? dialogContext = navigator.overlay?.context;
    if (dialogContext == null) return Future<void>.value();
    return showChangelogDialog(dialogContext, release: release, title: title);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
