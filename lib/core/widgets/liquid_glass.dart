import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../shared/hive/app_settings.dart';

// ============================================================================
// 液态玻璃（Liquid Glass）视觉引擎
// ============================================================================
//
// ## 关键能力：真·背景折射（Flutter 3.29+）
// 从 Flutter **3.29** 起 `dart:ui` 提供了 `ImageFilter.shader(FragmentShader)`，
// 而 `BackdropFilter` 接受它。引擎会把**背景纹理**绑到着色器的第 0 个
// `sampler2D`、把纹理尺寸写进第 0 个 `vec2` uniform —— 于是着色器里可以
// `texture(uBackdrop, coord + 位移)` **直接重采样真实背景**，这才是液态玻璃的
// 定义性特征（边缘折射透镜），而不是只有 `blur()` 的毛玻璃。
//
// 本项目在 `shaders/liquid_glass.frag` 里用与文档一致的算法链实现：
// 圆角矩形 SDF → 归一化深度 → 圆形倒角剖面（Snell 近似）→ 法线 × 位移
// → R/G/B 微差采样（色散）→ 边缘高光 → 内阴影 → 提饱和。
//
// ## 三级降级（任何一级失败都不会崩、也不会抖动）
// 1. `ImageFilter.shader` + Impeller → **真折射**；
// 2. 着色器资产加载失败 / `ImageFilter.isShaderFilterSupported == false`
//    （Skia）→ 回退到**解析式折射**（LiquidGlassRefraction，纯 CPU 数学，
//    效果接近但背景不被重采样）；
// 3. 用户把材质切成 GlassMode.blur → 经典高斯模糊毛玻璃。
// ============================================================================

/// 玻璃材质参数（照抄文档推荐值）。
@immutable
class GlassStyle {
  const GlassStyle({
    this.blur = 3,
    this.saturation = 1.35,
    this.tintOpacity = 0.10,
    this.bezelFactor = 0.12,
    this.bezelMin = 6,
    this.bezelMax = 28,
    this.refraction = 0.55,
    this.refractionAmount = 1.8,
    this.specular = 0.42,
    this.lightAngle = math.pi / 4,
    this.dispersion = 1.0,
    this.innerShadow = 0.16,
  });

  /// 高斯模糊 σ（文档：bezel × 0.15，通常 0~4px）。
  final double blur;

  /// 饱和度（文档：1.3~1.6，低了会发灰）。
  final double saturation;

  /// 色调层 alpha（文档：0.06~0.15，超过 0.2 就变成色卡）。
  final double tintOpacity;

  /// 折射带宽 = clamp(min(w,h) × bezelFactor, bezelMin, bezelMax)。
  final double bezelFactor;
  final double bezelMin;
  final double bezelMax;

  /// 折射强度系数（乘在剖面位移上）。
  final double refraction;

  /// 位移上限 = bezel × refractionAmount（文档：1.6~2.0）。
  final double refractionAmount;

  /// 镜面边缘光强度（文档：0.35~0.55）。
  final double specular;

  /// 光源角度（文档默认 45°）。
  final double lightAngle;

  /// 色散强度（0 = 关闭）。
  final double dispersion;

  /// 内阴影 alpha（文档：0.12~0.18）。
  final double innerShadow;

  /// 面板尺寸 → 折射带宽（文档 4.1 节）。
  double bezelFor(Size size) => (math.min(size.width, size.height) * bezelFactor)
      .clamp(bezelMin, bezelMax)
      .toDouble();

  /// 面板尺寸 → 折射带内边界距离（Kyant0 的 `refractionHeight`）。
  ///
  /// Kyant0 的典型取值是 `lens(12dp, 24dp)`，即 `refractionHeight ≈ bezel / 2`；
  /// 这里用 `bezel / refractionAmount`（refractionAmount = 1.8~2.0 → 约 bezel/2）。
  double refractHeightFor(Size size) =>
      bezelFor(size) / math.max(1.0, refractionAmount);

  /// 面板尺寸 → 位移像素上限（文档：bezel × 1.6~2.0）。
  double displacementFor(Size size) => bezelFor(size) * refractionAmount;

  /// 小控件（按钮 / Chip）：折射带与模糊都要按比例收小，否则细节糊掉。
  GlassStyle scaled(double factor) => GlassStyle(
        blur: (blur * factor).clamp(0.0, 6.0),
        saturation: saturation,
        tintOpacity: tintOpacity,
        bezelFactor: bezelFactor,
        bezelMin: (bezelMin * factor).clamp(2.0, 12.0),
        bezelMax: (bezelMax * factor).clamp(4.0, 24.0),
        refraction: refraction,
        refractionAmount: refractionAmount,
        specular: specular,
        lightAngle: lightAngle,
        dispersion: dispersion,
        innerShadow: innerShadow,
      );

  static const GlassStyle panel = GlassStyle();

  /// 顶部 / 底部整条状态栏。
  static const GlassStyle bar = GlassStyle(
    blur: 4,
    tintOpacity: 0.08,
    refraction: 0.42,
    specular: 0.34,
    innerShadow: 0.10,
  );

  /// 按钮 / Chip / 小图标钮。
  static const GlassStyle control = GlassStyle(
    blur: 2,
    tintOpacity: 0.14,
    refraction: 0.5,
    specular: 0.5,
    innerShadow: 0.14,
  );

  /// 卡片。
  static const GlassStyle card = GlassStyle(
    blur: 3,
    tintOpacity: 0.09,
    refraction: 0.5,
    specular: 0.38,
    innerShadow: 0.14,
  );

  @override
  bool operator ==(Object other) =>
      other is GlassStyle &&
      other.blur == blur &&
      other.saturation == saturation &&
      other.tintOpacity == tintOpacity &&
      other.bezelFactor == bezelFactor &&
      other.bezelMin == bezelMin &&
      other.bezelMax == bezelMax &&
      other.refraction == refraction &&
      other.refractionAmount == refractionAmount &&
      other.specular == specular &&
      other.lightAngle == lightAngle &&
      other.dispersion == dispersion &&
      other.innerShadow == innerShadow;

  @override
  int get hashCode => Object.hash(
        blur,
        saturation,
        tintOpacity,
        bezelFactor,
        bezelMin,
        bezelMax,
        refraction,
        refractionAmount,
        specular,
        lightAngle,
        dispersion,
        innerShadow,
      );
}

/// 折射剖面：圆形倒角 `circleMap`（与 Kyant0 的 AGSL 实现等价）。
///
/// Kyant0 原式（`RoundedRectRefractionShaderString`）：
/// ```glsl
/// if (-sd >= refractionHeight) return content.eval(coord);   // 超出折射带 → 不动
/// float d = circleMap(1.0 - -sd / refractionHeight) * refractionAmount;
/// ```
/// 即 `depth/refractHeight = 0`（折射带内边界）→ 位移 0；
/// `depth/refractHeight = 1`（边缘）→ 位移最大。
/// 这是**解析式降级路径**用的实现（着色器路径在 `shaders/liquid_glass.frag`）。
class LiquidGlassRefraction {
  const LiquidGlassRefraction._();

  /// 圆形倒角剖面 `circleMap(x) = 1 - sqrt(1 - x²)`，x∈[0,1]。
  static double circleMap(double x) {
    final double t = x.clamp(0.0, 1.0);
    return 1 - math.sqrt(1 - t * t);
  }

  /// 归一化深度 → 位移量：0 = 中心/折射带内边界（不动），1 = 边缘（最大）。
  static double profile(double normalizedDepth) {
    return circleMap(normalizedDepth.clamp(0.0, 1.0));
  }
}

/// 圆角矩形 SDF 工具（与 Kyant0 / 文档 1.3 节逐行一致）。
class LiquidGlassSdf {
  const LiquidGlassSdf._();

  /// `sdRoundedRect(coord, halfSize, radius)`：< 0 内部、0 边界、> 0 外部。
  static double sdRoundedRect(Offset p, Size halfSize, double radius) {
    final double qx = p.dx.abs() - (halfSize.width - radius);
    final double qy = p.dy.abs() - (halfSize.height - radius);
    final double outside = math.sqrt(
      math.max(qx, 0) * math.max(qx, 0) + math.max(qy, 0) * math.max(qy, 0),
    );
    final double inside = math.min(math.max(qx, qy), 0);
    return outside + inside - radius;
  }

  /// 中心点归一化深度（驱动折射剖面）。
  ///
  /// 返回值 `0..1`：`0` = 不折射（折射带以内，含面板中心），
  /// `1` = 位移最大（已到面板边缘）。
  ///
  /// 文档坑位 4：梯度半径必须用 `min(r × 1.5, min(halfW, halfH))`，
  /// 否则圆角处会出现放射状折痕。
  static double normalizedDepth(
    Offset centered,
    Size size, {
    required double refractHeight,
    required double radius,
  }) {
    if (refractHeight <= 0) return 0;
    final Size half = Size(size.width / 2, size.height / 2);
    final double gradRadius =
        math.min(radius * 1.5, math.min(half.width, half.height));
    final double sd = sdRoundedRect(centered, half, gradRadius);
    final double depth = -sd; // 内部为正
    if (depth <= 0) return 1; // 面板外沿 → 最强
    if (depth >= refractHeight) return 0; // 折射带以内（含中心）→ 不动
    return (1 - depth / refractHeight).clamp(0.0, 1.0);
  }
}

/// 玻璃材质分辨率：把 [GlassMode] 转成实际参数。
///
/// * [GlassMode.liquid] → 液态玻璃（折射 + 色散 + 高光 + 内阴影）
/// * [GlassMode.blur] → 经典高斯模糊毛玻璃（1.x 行为）
@immutable
class GlassMaterial {
  const GlassMaterial({
    required this.mode,
    required this.style,
    required this.enableRefraction,
    required this.enableDispersion,
    required this.enableSpecular,
    required this.enableInnerShadow,
    required this.blurSigma,
    required this.saturation,
  });

  final GlassMode mode;
  final GlassStyle style;
  final bool enableRefraction;
  final bool enableDispersion;
  final bool enableSpecular;
  final bool enableInnerShadow;
  final double blurSigma;
  final double saturation;

  bool get isLiquid => mode == GlassMode.liquid;

  /// 液态玻璃：小模糊（保留折射细节）+ 全部光学层。
  factory GlassMaterial.liquid([GlassStyle style = GlassStyle.panel]) =>
      GlassMaterial(
        mode: GlassMode.liquid,
        style: style,
        enableRefraction: style.refraction > 0,
        enableDispersion: style.dispersion > 0,
        enableSpecular: style.specular > 0,
        enableInnerShadow: style.innerShadow > 0,
        blurSigma: style.blur,
        saturation: style.saturation,
      );

  /// 高斯模糊：1.x 行为（σ=10，无折射）。
  factory GlassMaterial.blur([double sigma = 10]) => GlassMaterial(
        mode: GlassMode.blur,
        style: GlassStyle(
          blur: sigma,
          specular: 0,
          dispersion: 0,
          innerShadow: 0.10,
        ),
        enableRefraction: false,
        enableDispersion: false,
        enableSpecular: false,
        enableInnerShadow: true,
        blurSigma: sigma,
        saturation: 1,
      );

  GlassMaterial copyWith({GlassMode? mode, double? blurSigma}) => GlassMaterial(
        mode: mode ?? this.mode,
        style: style,
        enableRefraction: enableRefraction,
        enableDispersion: enableDispersion,
        enableSpecular: enableSpecular,
        enableInnerShadow: enableInnerShadow,
        blurSigma: blurSigma ?? this.blurSigma,
        saturation: saturation,
      );
}

/// 屏幕/环境级设置：由 Riverpod 在根部注入，供所有玻璃组件读取。
///
/// 使用 `InheritedWidget` 而不是让每个组件都 `ref.watch`，
/// 是为了让 `Glass*` 组件在测试与预览中也能脱离 Riverpod 单独使用。
class GlassScope extends InheritedWidget {
  const GlassScope({
    super.key,
    required this.material,
    this.shaderProgram,
    required super.child,
  });

  final GlassMaterial material;

  /// 液态玻璃着色器程序（`shaders/liquid_glass.frag`）。
  ///
  /// 为 null 表示不可用（Skia / 资产加载失败 / 旧版本 Flutter），
  /// 此时自动降级到解析式折射。
  final FragmentProgram? shaderProgram;

  /// 当前场景能否使用 shader 真折射。
  bool get refractive =>
      shaderProgram != null && material.isLiquid;

  static GlassMaterial of(BuildContext context) {
    final GlassScope? scope =
        context.dependOnInheritedWidgetOfExactType<GlassScope>();
    return scope?.material ?? GlassMaterial.liquid();
  }

  /// 取着色器程序（可能为 null → 走解析式降级）。
  static FragmentProgram? programOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GlassScope>()
        ?.shaderProgram;
  }

  /// 取当前材质并把样式替换为指定风格（面板 / 按钮 / 条 / 卡片）。
  static GlassStyle styleOf(BuildContext context, GlassStyle style) {
    final GlassMaterial material = of(context);
    if (material.isLiquid) {
      return style;
    }
    // 高斯模糊模式：沿用 1.x 的视觉（σ=10、无折射、保留内阴影）
    return GlassStyle(
      blur: 10,
      saturation: 1,
      tintOpacity: style.tintOpacity,
      refraction: 0,
      specular: 0,
      dispersion: 0,
      innerShadow: 0.10,
    );
  }

  @override
  bool updateShouldNotify(GlassScope oldWidget) =>
      oldWidget.material.mode != material.mode ||
      oldWidget.material.blurSigma != material.blurSigma ||
      oldWidget.shaderProgram != shaderProgram;
}

/// 液态玻璃着色器的加载与能力探测。
///
/// * 资产路径：`shaders/liquid_glass.frag`（见 pubspec.yaml 的 `flutter: shaders:`）
/// * 只在 [FragmentProgram] 可用且引擎支持 shader 型 ImageFilter 时返回程序，
///   否则返回 null 让调用方降级。
class LiquidGlassShader {
  const LiquidGlassShader._();

  /// 着色器资产路径。
  static const String assetPath = 'shaders/liquid_glass.frag';

  static FragmentProgram? _cached;
  static bool _attempted = false;

  /// 当前引擎是否支持「用着色器做 ImageFilter」（Impeller）。
  static bool get isSupported {
    try {
      return ImageFilter.isShaderFilterSupported;
    } on Object {
      return false;
    }
  }

  /// 加载着色器（幂等，只真正加载一次）。
  ///
  /// 任何失败都返回 null，绝不抛出 —— 玻璃会自动走解析式降级。
  static Future<FragmentProgram?> load() async {
    if (_attempted) return _cached;
    _attempted = true;
    if (!isSupported) return null;
    try {
      _cached = await FragmentProgram.fromAsset(assetPath);
    } on Object catch (error) {
      debugPrint('[liquid_glass] 着色器加载失败，降级为解析式折射: $error');
      _cached = null;
    }
    return _cached;
  }

  /// 供测试使用：重置缓存。
  @visibleForTesting
  static void resetForTest() {
    _cached = null;
    _attempted = false;
  }
}
