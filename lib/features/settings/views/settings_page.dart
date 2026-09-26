import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/blur_container.dart';
import '../../../shared/hive/app_settings.dart';
import '../../../shared/hive/hive_service.dart';
import '../../../shared/hive/settings_provider.dart';
import '../../news/data/news_channels.dart';
import '../../onboarding/widgets/interest_selector.dart';

/// 设置页：随时修改 API Key 与兴趣频道（数据全部保存在 Hive 本地）。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _keyController;
  late Set<String> _selected;
  bool _saving = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final AppSettings settings = ref.read(hiveServiceProvider).readSettings();
    _keyController = TextEditingController(text: settings.apiKey);
    _selected = settings.selectedCategories.toSet();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String key = _keyController.text.trim();
    if (key.isEmpty) {
      _snack('API Key 不能为空');
      return;
    }
    if (_selected.isEmpty) {
      _snack('请至少保留一个兴趣类别');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(settingsActionsProvider).save(
            apiKey: key,
            categories: _selected.toList(growable: false),
          );
      if (!mounted) return;
      _snack('已保存，新闻列表已刷新');
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      _snack('保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HiveService hive = ref.watch(hiveServiceProvider);
    final DateTime? lastRefresh = hive.lastRefreshAt;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        children: <Widget>[
          BlurContainer(
            borderRadius: BorderRadius.circular(20),
            blur: 10,
            opacity: 0.12,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.vpn_key_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('聚合新闻 API Key', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      tooltip: _obscure ? '显示' : '隐藏',
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
                TextField(
                  controller: _keyController,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'API Key',
                    helperText: '保存在本机 Hive 存储；代码中不含任何硬编码密钥。',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '申请地址：https://www.juhe.cn/docs/api/id/235（免费 50 次/天）',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BlurContainer(
            borderRadius: BorderRadius.circular(20),
            blur: 10,
            opacity: 0.12,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.interests_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('兴趣频道', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      '已选 ${_selected.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InterestSelector(
                  selected: _selected,
                  onToggle: (String type) => setState(() {
                    if (!_selected.remove(type)) _selected.add(type);
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  '最多同时请求 3 个频道（控制每日 50 次免费额度）。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BlurContainer(
            borderRadius: BorderRadius.circular(20),
            blur: 10,
            opacity: 0.12,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('数据与状态', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                const _InfoRow(
                  label: '数据来源',
                  value: '聚合数据 · 新闻头条（v.juhe.cn）',
                ),
                _InfoRow(
                  label: '上次刷新',
                  value: lastRefresh == null
                      ? '尚未刷新'
                      : lastRefresh.toString().substring(0, 16),
                ),
                _InfoRow(
                  label: '本地收藏',
                  value: '${hive.favorites().length} 条',
                ),
                _InfoRow(
                  label: '频道列表',
                  value: kAllChannels.map((NewsChannel c) => c.label).join(' / '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('保存并刷新新闻'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              await ref.read(hiveServiceProvider).completeOnboarding(
                    apiKey: '',
                    categories: const <String>[],
                  );
              if (context.mounted) context.go('/onboarding');
            },
            child: const Text('重新走一遍引导（清空 API Key）'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
