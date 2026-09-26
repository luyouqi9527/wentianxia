# 闻天下 · Flutter 新闻阅读 App

> Material 3 + **液态玻璃（Liquid Glass，真·背景折射）** + 短视频式垂直滑动浏览的新闻阅读应用。
> 数据源为**聚合数据 · 新闻头条 API**；**API Key 由用户在首次启动时填写并只保存在本机**
> （Hive 本地存储），源码中不含任何硬编码密钥。

<p align="left">
  <img alt="version" src="https://img.shields.io/badge/version-3.0.0-2ea44f" />
  <img alt="flutter" src="https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter" />
  <img alt="dart" src="https://img.shields.io/badge/Dart-3.13.4-0175C2?logo=dart" />
  <img alt="platform" src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" />
  <img alt="material" src="https://img.shields.io/badge/Material-3%20%2B%20LiquidGlass-6750A4" />
  <img alt="riverpod" src="https://img.shields.io/badge/State-Riverpod-4B4BFF" />
  <img alt="ci" src="https://img.shields.io/badge/CI-CodeMagic-8B5CF6" />
</p>

---

## 一、版本记录

| 版本 | 说明 |
| --- | --- |
| **3.0.0+5**（当前） | 升级到 **Flutter 3.47.5 / Dart 3.13.4**；液态玻璃改为 **shader 真·背景折射**（`ImageFilter.shader` + `BackdropFilter`，引擎把背景纹理绑到着色器，直接重采样真实背景）；三层降级（真折射 / 解析式折射 / 高斯模糊）；启用 `BackdropGroup` 共享采样 |
| 2.0.1+4 | 修复「安装/更新后首次打开不弹更新内容」（弹窗上下文取在 Navigator 之上）、更新内容溢出玻璃框、玻璃滑动偶发闪烁；首次安装改为展示「使用提示」 |
| 2.0.0+3 | 液态玻璃材质（边缘折射 + 色散 + 45° 边缘高光 + 内阴影）；设置里切换「液态玻璃 / 高斯模糊」；修复全文页自动滚动停不掉且默认关闭；统一 APK 签名；安装/更新后弹出更新内容 |
| 1.0.1+2 | 修复毛玻璃控件下方图像缺失（空白色带）与滑动闪烁；毛玻璃层结构重构；新增回归测试 |
| 1.0.0+1 | 首个版本：引导页 / 新闻流 / 全文阅读 / 收藏 / 设置 / CodeMagic 构建 |

---

## 二、3.0.0 核心技术：shader 真·背景折射

### 2.1 为什么必须升到 Flutter 3.29+

`dart:ui` 从 **Flutter 3.29** 起提供 `ImageFilter.shader(FragmentShader)`，
并且 `BackdropFilter` 接受它。引擎约定（官方文档与引擎注释原文语义）：

> 第 0 个 float uniform **必须是 `vec2`**，由引擎写入被绑定纹理的尺寸；
> 第 1 个 `sampler2D` 由引擎绑定为**滤镜输入（即真实背景）**；
> 这两个值**不要**从 Dart 侧设置。

于是着色器里可以直接 `texture(uBackdrop, coord + 位移)` **重采样真实背景像素** ——
这才是液态玻璃的定义性特征「边缘折射透镜」，而不是 `blur()` 能近似出来的。
本地原基线 3.27.4 没有该 API（`painting.dart` 里只有 `blur/dilate/erode/matrix/compose`），
所以 1.x/2.x 只能用数学等价的「解析式折射」。3.29+ 还带来
`BackdropGroup` / `BackdropFilter.grouped()`（多个玻璃控件共享一次背景采样）。

**现基线：Flutter 3.47.5 / Dart 3.13.4。**

### 2.2 着色器（`shaders/liquid_glass.frag`）

```glsl
#include <flutter/runtime_effect.glsl>

// 引擎自动填充（禁止 Dart 设置）
uniform vec2 uSize;          // 索引 0,1：被绑定纹理的尺寸
uniform sampler2D uBackdrop; // 索引 0（sampler 空间）：真实背景

// Dart 设置（从索引 2 开始，按声明顺序占位）
uniform float uRadius;        // 2
uniform float uRefractHeight; // 3：折射带内边界 = bezel / refractionAmount
uniform float uRefractAmount; // 4：位移像素上限 = bezel × 1.8~2.0
uniform float uSpecular;      // 5
uniform float uLightAngle;    // 6：默认 45°
uniform float uDispersion;    // 7
uniform float uInnerShadow;   // 8
uniform float uSaturation;    // 9：1.35（低了发灰）
uniform float uTintAlpha;     // 10

float sdRoundRect(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - (halfSize - vec2(radius));
    return length(max(q, 0.0)) - radius + min(max(q.x, q.y), 0.0);
}

float circleMap(float x) { float t = clamp(x, 0.0, 1.0); return 1.0 - sqrt(1.0 - t * t); }

void main() {
    vec2 coord = FlutterFragCoord().xy;
    vec2 halfSize = uSize * 0.5;
    vec2 centered = coord - halfSize;
    float depth = -sdRoundRect(centered, halfSize, radius);   // 内部为正

    if (depth > 0.0 && uRefractHeight > 0.5 && uRefractAmount > 0.0) {
        float t = clamp(depth / uRefractHeight, 0.0, 1.0);   // 0=带内边界 1=边缘
        float d = circleMap(t) * uRefractAmount;             // 位移量（Snell 近似）
        // 文档坑位 4：梯度半径必须 min(r×1.5, min(halfW,halfH)) 否则圆角放射状折痕
        float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y) * 0.5);
        vec2 grad = gradRoundRect(centered, halfSize, gradRadius);  // 法线 = ∇SDF
        vec2 sampleCoord = coord + grad * d;                 // ← 重采样真实背景
        vec3 warped = vec3(
            texture(uBackdrop, (sampleCoord + grad * dispPx) / uSize).r,  // 色散
            texture(uBackdrop,  sampleCoord / uSize).g,
            texture(uBackdrop, (sampleCoord - grad * dispPx) / uSize).b);
        float spec = pow(abs(dot(grad, vec2(cos(uLightAngle), sin(uLightAngle)))), 2.5);
        warped += spec * uSpecular;                          // 45° 双面边缘高光
        // 内阴影 + 提饱和（saturation）+ 中心压暗（保证文字对比度）
    }
    fragColor = color;
}
```

算法链完全对应项目内《液态玻璃实现技术文档》第 1 章与 Kyant0 的 AGSL 实现：
**圆角矩形 SDF → 归一化深度 → 圆形倒角剖面（Snell 近似）→ 法线 × 位移 → 重采样 → 色散 → 高光 → 内阴影**。

### 2.3 三层降级（任何一层失败都不会崩、也不会跳变）

| 条件 | 走哪条路 | 效果 |
| --- | --- | --- |
| Impeller + 着色器加载成功 + 材质=液态玻璃 | `ImageFilter.shader` | **真·背景折射**（边缘弯折 + 色散 + 高光） |
| Skia / 着色器加载失败 / `isShaderFilterSupported == false` | 解析式折射（`_LiquidGlassPainter`） | 近似折射（亮度带 + 冷彩色边 + 高光） |
| 设置里选「高斯模糊」 | `ImageFilter.blur(σ=10)` | 经典毛玻璃（1.x 行为） |

```dart
// lib/core/widgets/glass_widgets.dart
final bool useShader = program != null && material.isLiquid;
...
// 两层 BackdropFilter 叠加：下层背景模糊（σ 很小，避免抹平折射细节），上层 shader 折射。
// 刻意不塞进 ImageFilter.compose —— 叠两层是官方文档与 liquid_glass_renderer 的稳妥做法。
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: style.blur, sigmaY: style.blur),
  child: BackdropFilter(
    filter: ImageFilter.shader(shader),
    child: child,
  ),
)
```

着色器在 `main()` 里**只加载一次**并覆盖 Provider，保证首帧就是真折射（不会先闪毛玻璃再变）：

```dart
final FragmentProgram? glassShader = await LiquidGlassShader.load(); // 失败返回 null
runApp(ProviderScope(overrides: <Override>[
  hiveServiceProvider.overrideWithValue(HiveService.instance),
  glassShaderProvider.overrideWithValue(glassShader),
], child: const WentianxiaApp()));
```

---

## 三、功能清单

| 模块 | 实现 |
| --- | --- |
| 首次启动引导 | 两步引导：①「聚合新闻API Key」输入（非空 + 长度校验、一键粘贴、官网入口）②兴趣类别多选（Material 3 `Chip` + 液态玻璃）。保存 `isFirstLaunch=false` / `apiKey` / `selectedCategories` 到 Hive |
| 启动判断 | `main()` 初始化 Hive → `settingsProvider` 推送设置 → `go_router.redirect` 决定引导页/主界面 |
| 新闻滑动浏览 | `PageView` + `scrollDirection: Axis.vertical`；每页：图片（约 38% 屏高，`CachedNetworkImage`）→ 标题（`headlineSmall`）→ 简介（`bodyMedium`，2~3 句）→「观看全文」玻璃按钮 |
| 上滑刷新 | 在第一条继续向下拖拽（`OverscrollNotification`）触发接口重拉；另有毛玻璃刷新按钮 + `RefreshIndicator` |
| 全文阅读 | `CustomTransitionPage` + Slide/Fade 过渡；**默认不自动滚动**，点顶部按钮才滚动（0.5x~2x 可调、可暂停、到底自停）；顶部阅读进度条；页内至少一张图片；显示作者/来源/时间/字数 |
| 阅读原文 | `url_launcher` 外部浏览器（已声明 Android `<queries>`） |
| 收藏 | 心形图标切换；Hive `Box<NewsArticle>` 持久化；收藏 Tab 显示缩略图/标题/收藏时间，左滑删除（带撤销）、一键清空；空状态「还没有收藏的新闻」 |
| 设置 | 修改 API Key / 兴趣频道；**磨砂材质切换（液态玻璃 / 高斯模糊，即时生效）**；应用版本；手动打开更新内容 |
| 更新内容弹窗 | 安装/更新后首次打开自动弹出（首次安装展示「使用提示」） |
| 错误处理 | Material 3 `SnackBar` + 重试；聚合数据错误码（10001 无效 Key、10012 额度用尽…）转中文 |
| 分享 / 跳转 | 全文页底部玻璃操作栏：阅读原文 / 收藏 / 分享（原生 `MethodChannel`） |

---

## 四、技术栈

| 类别 | 选型 |
| --- | --- |
| 框架 | Flutter **3.47.5**（Dart 3.13.4，Material 3 默认启用） |
| 状态管理 | Riverpod (`flutter_riverpod ^2.6.1`) |
| 网络 | Dio (`^5.7.0`) |
| 本地存储 | Hive + hive_flutter（`wentianxia_settings` / `wentianxia_favorites` / `wentianxia_meta`） |
| 路由 | go_router (`^14.6.2`)，`StatefulShellRoute.indexedStack` 做底部 Tab |
| 模型 | Freezed 2.5.7 + json_serializable 6.9.0 + hive_generator 2.0.1 |
| 跳转 / 图片 | url_launcher `^6.3.0`、cached_network_image `^3.4.1` |
| 图形 | **自定义 fragment shader**（`shaders/liquid_glass.frag`）+ `ImageFilter.shader` |

> ⚠️ `freezed` 固定为 `2.5.7`：`hive_generator 2.0.1` 依赖 `source_gen ^1.x`，
> `freezed >= 2.5.8` 依赖 `source_gen ^2.x`，两者不能共存。

---

## 五、目录结构

```
lib/
├── main.dart                          # Hive 初始化 + 着色器加载 + ProviderScope
├── app.dart                           # MaterialApp.router（M3 主题 + GlassScope 注入）
├── routes/
│   ├── app_router.dart                # go_router + redirect（首启判断）+ 根 navigator key
│   └── main_shell.dart                # 玻璃 NavigationBar（新闻 / 收藏）
├── core/
│   ├── errors/news_api_exception.dart
│   ├── services/share_service.dart    # 原生分享 MethodChannel
│   ├── theme/app_theme.dart           # ColorScheme.fromSeed(deepPurple)
│   └── widgets/
│       ├── liquid_glass.dart          # 材质参数 / SDF / 折射数学 / 着色器加载与能力探测
│       ├── glass_widgets.dart         # LiquidGlass（真折射 + 解析式降级）/ GlassTint / BlurGroup
│       ├── blur_container.dart        # 兼容层：BlurContainer / BlurBar / GlassBackdrop
│       └── news_network_image.dart    # CachedNetworkImage + 占位 + 失败兜底
├── features/
│   ├── changelog/                     # 更新内容（app_changelog + changelog_dialog 闸门）
│   ├── onboarding/                    # 引导页（API Key + 兴趣 Chip）
│   ├── news/                          # 频道 / 模型 / 仓库 / 正文抽取 / provider / 视图
│   ├── favorites/                     # 收藏（Hive watch → 自动刷新）
│   └── settings/                      # 设置（材质开关 / Key / 频道）
└── shared/hive/                       # HiveService / AppSettings / settings_provider
shaders/
└── liquid_glass.frag                  # 液态玻璃折射着色器（引擎绑定背景纹理）
```

---

## 六、快速开始

> ⚠️ **Windows 用户：工程路径必须是纯 ASCII。**
> 路径含中文（如 `D:\文件\代码\...`）时 `flutter build apk` 会在最后一步失败：
> * Dart AOT：`Unable to read file: D:\???\????\...\app.dill`
> * `impellerc`：`Could not write file to D:\?...\shaders/ink_sparkle.frag`
>
> 两种解法（`android.overridePathCheck=true` 只能消掉 AGP 的**警告**，消不掉这两个真实报错）：
> 1. 把工程放到 ASCII 路径（推荐，例如 `D:\dev\wentianxia`）；
> 2. 复制到 ASCII 路径构建：
>    ```powershell
>    robocopy "D:\文件\代码\news\wentianxia" C:\wentianxia_build /E /XD build .dart_tool .git .gradle /XF local.properties
>    cd C:\wentianxia_build; flutter build apk --release
>    ```
> CodeMagic 的构建机路径本身是 ASCII，不受影响。

```bash
flutter --version    # 需 3.29+，本项目基线 3.47.5
flutter pub get
# 代码生成（*.freezed.dart / *.g.dart；仓库已提交生成结果，可跳过）
dart run build_runner build --delete-conflicting-outputs
flutter analyze      # 期望：No issues found!
flutter test         # 期望：All tests passed!
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

首次启动 App → 粘贴聚合数据 API Key → 选兴趣频道 → 进入新闻流。

---

## 七、聚合数据 API 说明

1. 打开 <https://www.juhe.cn/docs/api/id/235> 注册并申请「新闻头条」接口；
2. 复制个人中心的 API Key；
3. 首次启动时粘贴到引导页（或之后在「设置」里修改）。

| 项目 | 说明 |
| --- | --- |
| 接口 | `https://v.juhe.cn/toutiao/index` |
| 参数 | `type`（频道）、`key`（**来自 Hive**）、`page`、`page_size`、`is_filter` |
| 免费额度 | 50 次/天 → 首页最多请求 3 个频道（`unique.take(3)`） |
| 频道 | 头条 / 国内 / 国际 / 娱乐 / 体育 / 军事 / 科技 / 财经 / 游戏 / 汽车 / 健康 / 时尚 / 教育 / 旅游 |
| 字段映射 | `title` `author_name` `thumbnail_pic_s` `url` `date` `description` `uniquekey` → `NewsArticle` |
| 备选方案 | Key 写成 `thenewsapi:<token>` → 自动改用 `https://api.thenewsapi.com/v1/news/top?api_token=…&language=zh` |

---

## 八、CodeMagic 构建

仓库根目录已包含 `codemagic.yaml`：

| 组件 | 版本 |
| --- | --- |
| Flutter / Dart | **3.47.5 / 3.13.4**（必须 ≥ 3.29，否则没有 `ImageFilter.shader`） |
| Java | 17 |
| Gradle / AGP / Kotlin | 8.7 / 8.6.0 / 1.9.24 |
| compileSdk / targetSdk / minSdk | 35 / 35 / 23 |
| applicationId | `com.wentianxia.news` |

工作流除了 `pub get` → `analyze` → `test` → `build apk --release`，
还加了一步**校验着色器是否真的打进包**：

```bash
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -i "shaders/liquid_glass.frag"
```

失败即中断，避免出现「构建成功但玻璃没有折射」的静默降级。

### 签名（覆盖安装不再报「签名不一致」）

1.x 用的是 AGP 默认 debug 签名（随环境变化），本机与 CodeMagic 产生的密钥不同，
覆盖安装时系统安装器会要求先卸载。现在仓库内固定一把密钥
`android/app/wentianxia-release.jks`，**debug 与 release 共用**：

```gradle
def wentianxiaKeystore = file('wentianxia-release.jks')
signingConfigs { if (wentianxiaKeystore.exists()) { wentianxia { ... } } }
buildTypes {
  release { signingConfig = signingConfigs.wentianxia }
  debug   { signingConfig = signingConfigs.wentianxia }
}
```

证书指纹（SHA-1，可与 `apksigner verify --print-certs` 比对）：

```
10:A4:3D:BA:0D:66:30:48:09:A0:1A:58:C3:63:E6:C5:84:5C:8F:D6
```

> 想换自有密钥：把 jks 移出仓库，改从 `key.properties` / 环境变量读取即可。

---

## 九、测试

```bash
flutter test
```

| 文件 | 覆盖内容 |
| --- | --- |
| `test/widget_test.dart` | Hive 持久化、HTML 正文抽取、模型映射、200 字简介截断、稳定 id、M3 渲染冒烟 |
| `test/blur_regression_test.dart` | **玻璃层结构约束**（`BackdropFilter` 祖先链上不得乱包 `RepaintBoundary`）、`GlassTint` 不新增 backdrop 层、`GlassBackdrop` 兜底、SDF/`circleMap`/`normalizedDepth`/bezel 公式、材质映射、**着色器缺失时自动降级**、全文页默认不自动滚动 |
| `test/changelog_gate_test.dart` | 「更新内容」弹窗能从根 Navigator 的 context 正常弹出；首次安装展示使用提示；版本条目选择逻辑 |

---

## 十、常见问题与取舍

**1. 玻璃为什么有时是真折射、有时不是？**
看 `ImageFilter.isShaderFilterSupported`（Impeller 才为 true）。Skia 或着色器加载失败时
自动降级为解析式折射，界面不会崩、也不会跳变。设置里切「高斯模糊」则完全不用 shader。

**2. 为什么用两层 `BackdropFilter` 而不是 `ImageFilter.compose`？**
`blur` 与 `shader` 放在同一个 filter 里在 3.38 之前是坏的（官方 issue #170820），
叠两层是官方文档与 `liquid_glass_renderer` 都在用的稳妥写法。

**3. `flutter pub get` 报版本冲突？**
不要升级 `freezed`。本项目用 `freezed 2.5.7` + `hive_generator ^2.0.1`，
这是唯一能同时生成 Freezed 与 Hive Adapter 的组合。

**4. 全文页显示「摘要模式」？**
部分站点 JS 动态渲染或反抓取，`ArticleHtmlParser` 拿不到 ≥160 字正文时会用接口
`description` 拼出可读内容并标注；底部「阅读原文」仍可跳转查看完整报道。

**5. 刷新提示「今日接口调用次数已用完」？**
聚合数据免费额度 50 次/天，单次刷新最多 3 个频道。可等次日或改用备选数据源。

**6. 收藏能离线看吗？**
标题/摘要/来源/收藏时间都在 Hive，离线可读；正文需要联网抓取。

**7. 玻璃控件很多会不会卡？**
一屏只构建当前页；一条 bar 只做一次玻璃，条内按钮用 `GlassTint` 静态填充
（对应文档「永远避免 glass on glass」）；`BlurGroup` 已启用 `BackdropGroup`
共享采样。注意：**重叠的玻璃不要共享同一个 backdrop key**，否则重叠区看起来只应用了一次滤镜。

---

## License

仅供学习与个人使用。新闻内容版权归各原媒体所有，本应用仅做聚合展示与跳转。
