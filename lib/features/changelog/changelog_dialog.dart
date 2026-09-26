import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/blur_container.dart';
import '../../shared/hive/settings_provider.dart';
import 'app_changelog.dart';

/// 「更新内容」弹窗：安装 / 更新后首次打开自动展示，也可在设置里手动打开。
///
/// 2.0.0 起，弹窗本身也使用液态玻璃材质（跟随设置里的材质开关）。
Future<void> showChangelogDialog(
  BuildContext context, {
  AppRelease? release,
}) {
  final AppRelease target = release ?? AppChangelog.current;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (BuildContext context) => ChangelogDialog(release: target),
  );
}

/// 「更新内容」弹窗内容。
class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key, required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
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
                      Text('更新内容', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '闻天下 v${release.version} · ${release.date}',
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
            Flexible(
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
class AppChangelogGate extends ConsumerStatefulWidget {
  const AppChangelogGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppChangelogGate> createState() => _AppChangelogGateState();
}

class _AppChangelogGateState extends ConsumerState<AppChangelogGate> {
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_scheduled || !mounted) return;
    _scheduled = true;

    final String seen = ref.read(currentSettingsProvider).lastSeenVersion;
    if (seen == AppChangelog.currentVersion) return;

    // 等首帧稳定后再弹，避免与路由跳转抢帧
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    await showChangelogDialog(context, release: AppChangelog.current);
    if (!mounted) return;
    await ref
        .read(settingsActionsProvider)
        .markVersionSeen(AppChangelog.currentVersion);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
