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
  static const String currentVersion = '2.0.0';

  static const List<AppRelease> releases = <AppRelease>[
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
