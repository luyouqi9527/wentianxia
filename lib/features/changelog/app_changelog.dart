/// 版本更新内容（2.0.0 起：安装/更新后首次打开自动弹出）。
///
/// 约定：每次发版在 [releases] 顶部加一条，`version` 必须与 `pubspec.yaml`
/// 的版本号一致（只比较 `+` 之前的部分）。
class AppRelease {
  const AppRelease({
    required this.version,
    required this.date,
    required this.highlights,
  });

  final String version;
  final String date;

  /// 更新要点（每条一句话，尽量具体到用户能感知的变化）。
  final List<String> highlights;
}

class AppChangelog {
  const AppChangelog._();

  /// 当前版本号（与 pubspec.yaml 保持一致）。
  static const String currentVersion = '3.0.0';

  /// 首次安装时的引导内容（不是「更新」，所以单独一套文案）。
  static const AppRelease welcome = AppRelease(
    version: '',
    date: '',
    highlights: <String>[
      '首次使用：在引导页填入「聚合数据」新闻头条接口的 API Key（免费 50 次/天），再挑几个感兴趣的频道。',
      '上下滑动即可切换新闻；在第一条继续下滑会重新拉取最新内容。',
      '点「观看全文」进入全文阅读，默认不会自动滚动，需要时点顶部「自动滚动」。',
      '心形按钮收藏，收藏内容保存在本机，离线也能看标题与摘要。',
      '「设置 → 磨砂材质」可在「液态玻璃」和「高斯模糊」之间切换，随时改回来。',
    ],
  );

  static const List<AppRelease> releases = <AppRelease>[
    AppRelease(
      version: '3.0.0',
      date: '2026-02',
      highlights: <String>[
        '液态玻璃升级为「真·背景折射」：改用着色器直接重采样玻璃背后的真实内容，边缘放大/弯折是真的（不再是数学近似）',
        '同步升级到 Flutter 3.47.5，拿到 BackdropGroup 共享采样，多个玻璃控件只采样一次背景',
        '保留三级降级：设备不支持着色器时自动回退到近似折射 / 高斯模糊，不会崩也不会跳变',
        '玻璃滑动时的闪烁进一步减少（新版引擎修掉了滚动纹理错位问题）',
      ],
    ),
    AppRelease(
      version: '2.0.1',
      date: '2026-02',
      highlights: <String>[
        '修复：安装/更新后首次打开现在会正常弹出本弹窗（2.0.0 把弹窗上下文取在 Navigator 之上，导致静默失效）',
        '修复：更新内容过多时不再溢出玻璃框外，超长内容改为框内滚动',
        '修复：玻璃控件在滑动时的偶发闪烁（减掉一层 Opacity+Transform 合成，玻璃回归单层 backdrop）',
        '首次安装改为展示「使用提示」，升级才展示版本更新内容',
      ],
    ),
    AppRelease(
      version: '2.0.0',
      date: '2026-02',
      highlights: <String>[
        '全新「液态玻璃」材质：边缘折射 + 色散 + 45° 边缘高光 + 内阴影，质感接近 iOS 26',
        '设置里可一键切换「液态玻璃 / 高斯模糊」，切换即时生效、无需重启',
        '修复毛玻璃控件下方图像缺失与滑动闪烁（解析式渲染，不再依赖实时背景采样）',
        '全文阅读默认不再自动滚动；播放/暂停按钮现在可以真正停住滚动',
        '统一 APK 签名：本地与 CodeMagic 构建使用同一密钥，覆盖安装不再提示签名不一致',
        '安装/更新后首次打开会展示本页更新内容',
      ],
    ),
    AppRelease(
      version: '1.0.1',
      date: '2026-01',
      highlights: <String>[
        '修复毛玻璃控件下方出现图像缺失的空白带与滑动闪烁',
        '新增毛玻璃层结构回归测试，防止问题复发',
      ],
    ),
    AppRelease(
      version: '1.0.0',
      date: '2026-01',
      highlights: <String>[
        '首个版本：首次启动填写聚合新闻 API Key + 选择兴趣频道',
        '短视频式垂直滑动浏览新闻、上滑刷新',
        '全文阅读（自动滚动 / 阅读原文 / 收藏 / 分享）',
        '收藏管理、Material 3 主题、毛玻璃交互',
      ],
    ),
  ];

  /// 取指定版本的更新条目。
  static AppRelease? forVersion(String version) {
    for (final AppRelease release in releases) {
      if (release.version == version) return release;
    }
    return null;
  }

  /// 当前版本的更新条目。
  static AppRelease get current =>
      forVersion(currentVersion) ?? releases.first;
}
