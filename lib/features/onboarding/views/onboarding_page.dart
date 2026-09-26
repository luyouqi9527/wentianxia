import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/blur_container.dart';
import '../../../shared/hive/hive_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/interest_selector.dart';

/// 聚合数据申请 API Key 的页面。
const String kJuheApplyUrl = 'https://www.juhe.cn/docs/api/id/235';

/// 首次启动引导页：
/// 第 1 步 —— 填写「聚合新闻 API Key」（非空校验，保存在 Hive，不硬编码）；
/// 第 2 步 —— 勾选感兴趣的新闻类别（Material 3 Chip + 高斯模糊）。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _controller = PageController();
  final TextEditingController _keyController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // 若本地已有 Key（例如升级安装），预填方便修改。
    _keyController.text = ref.read(hiveServiceProvider).apiKey;
  }

  @override
  void dispose() {
    _controller.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _controller.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onNext() {
    if (_step == 0) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      FocusScope.of(context).unfocus();
      _goToStep(1);
      return;
    }
    _finish();
  }

  Future<void> _finish() async {
    // 需求：必须至少勾选一个感兴趣的类别。
    if (ref.read(onboardingProvider).selectedCategories.isEmpty) {
      _snack('请至少选择一个感兴趣的类别');
      return;
    }
    final OnboardingController controller =
        ref.read(onboardingProvider.notifier);
    final bool ok = await controller.complete(apiKey: _keyController.text);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个感兴趣的类别')),
      );
      return;
    }
    // 保存成功后 settingsProvider 会推送新值，go_router 的 redirect 自动进入主界面。
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存，正在为你加载新闻…')),
    );
  }

  Future<void> _openHelp() async {
    final Uri uri = Uri.parse(kJuheApplyUrl);
    try {
      final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('无法打开浏览器，请手动访问：$kJuheApplyUrl');
    } on Object {
      if (mounted) _snack('无法打开浏览器，请手动访问：$kJuheApplyUrl');
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OnboardingState state = ref.watch(onboardingProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          // 背景光斑，让毛玻璃有内容可采样。
          const _OnboardingBackdrop(),
          SafeArea(
            child: Column(
              children: <Widget>[
                _Header(step: _step),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      _buildApiKeyStep(theme),
                      _buildInterestStep(theme, state),
                    ],
                  ),
                ),
                // 1.0.1：底部毛玻璃条撑满整行宽度，
                // 避免 Column 居中布局导致宽度收缩、模糊区域下方无像素可采样。
                SizedBox(
                  width: double.infinity,
                  child: _BottomBar(
                    step: _step,
                    loading: state.saving,
                    onNext: _onNext,
                    onBack: _step == 0 ? null : () => _goToStep(0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ 第 1 步

  Widget _buildApiKeyStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('欢迎使用 闻天下', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '首次使用需要填写「聚合数据」新闻头条接口的 API Key。\n'
              '密钥只保存在本机（Hive 本地存储），不会上传到任何服务器。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            BlurContainer(
              borderRadius: BorderRadius.circular(18),
              blur: 10,
              opacity: 0.14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextFormField(
                controller: _keyController,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                style: const TextStyle(letterSpacing: 0.4),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: '聚合新闻API Key',
                  hintText: '例如：a1b2c3d4e5f6...',
                  helperText: '申请地址：juhe.cn（新闻头条 API，免费 50 次/天）',
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    tooltip: '粘贴',
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      final String? text = data?.text?.trim();
                      if (text == null || text.isEmpty) {
                        _snack('剪贴板中没有文本');
                        return;
                      }
                      _keyController.text = text;
                    },
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'API Key 不能为空，请输入聚合数据密钥';
                  }
                  if (value.trim().length < 8) {
                    return 'API Key 长度过短，请检查是否复制完整';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            BlurContainer(
              borderRadius: BorderRadius.circular(18),
              blur: 10,
              opacity: 0.10,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.help_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('如何获取 API Key', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '1. 打开聚合数据官网并注册账号；\n'
                    '2. 在「数据服务」中搜索“新闻头条”；\n'
                    '3. 免费申请后，在个人中心复制 API Key；\n'
                    '4. 粘贴到上方输入框即可（50 次/天免费额度）。',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BlurButton(
                      label: '前往聚合数据申请',
                      icon: Icons.open_in_new,
                      opacity: 0.22,
                      onPressed: _openHelp,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '提示：也可以填入 The News API 的密钥（格式：thenewsapi:你的token）作为备选数据源。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 第 2 步

  Widget _buildInterestStep(ThemeData theme, OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('选择你感兴趣的内容', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '已选 ${state.selectedCategories.length} 个类别，'
            '新闻流会优先展示这些频道（建议 2~4 个）。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          InterestSelector(
            selected: state.selectedCategories,
            onToggle: (String type) =>
                ref.read(onboardingProvider.notifier).toggleCategory(type),
          ),
        ],
      ),
    );
  }
}

/// 顶部标题 + 步骤指示。
class _Header extends StatelessWidget {
  const _Header({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: <Widget>[
          BlurContainer(
            borderRadius: BorderRadius.circular(14),
            blur: 10,
            opacity: 0.2,
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.newspaper, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '闻天下',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                step == 0 ? '第 1 步 / 2 · 填写 API Key' : '第 2 步 / 2 · 选择兴趣',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 底部主按钮（毛玻璃 FilledButton）。
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.loading,
    required this.onNext,
    this.onBack,
  });

  final int step;
  final bool loading;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BlurContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      blur: 10,
      opacity: 0.18,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (onBack != null) ...<Widget>[
                BlurButton(
                  label: '上一步',
                  icon: Icons.arrow_back,
                  onPressed: loading ? null : onBack,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : onNext,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          step == 0
                              ? Icons.arrow_forward
                              : Icons.check_circle_outline,
                        ),
                  label: Text(
                    step == 0 ? '下一步：选择兴趣' : '完成，开始阅读',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '所有数据仅保存在本机，可随时在「设置」中修改。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 引导页背景：深色渐变 + 色斑（给毛玻璃提供采样内容）。
class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF141026),
            Color(0xFF0C0C11),
            Color(0xFF1A1230),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            left: -60,
            child: _Blob(color: Color(0xFF6D4AFF), size: 260),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _Blob(color: Color(0xFF00A6A6), size: 300),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
