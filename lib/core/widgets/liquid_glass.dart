/// 液态玻璃（Liquid Glass）视觉引擎。
///
/// 设计依据来自项目内的《液态玻璃实现技术文档》/《AI 速查卡》：
///
/// * **定义性特征**：液态玻璃 ≠ 毛玻璃。它的灵魂是**边缘折射透镜**
///   （edge lensing）——面板边缘把背后的内容按 SDF 法线方向重采样并放大，
///   中心保持不动；只有 `blur()` 的方案只能叫 glassmorphism（毛玻璃）。
/// * **算法链**：圆角矩形 SDF → 归一化深度 `t = depth / bezel` → 位移剖面
///   （凸超椭圆 `(1-(1-x)^4)^(1/4)` + Snell 2D 近似）→ 法线 `normalize(∇SDF)`
///   → `sampleCoord = coord + normal × profile × scale` → 重采样。
/// * **六层堆叠**（自下而上）：折射 → 模糊(saturate) → tint → 高光 →
///   边缘光/色边 → 内容。**顺序铁律：折射在底层、模糊在其上，且模糊必须小
///   （0~4px），否则会把折射细节抹平退化成毛玻璃。**
/// * **参数默认值**：`bezel = clamp(min(w,h) × 0.12, 6, 28)`、
///   位移 `= bezel × 1.6~2.0`、`blur = bezel × 0.15`、`saturation 1.3~1.6`、
///   `tint alpha 0.06~0.15`、高光 45°/白 0.35~0.55、内阴影 alpha 0.12~0.18。
///
/// ## 本文件在 Flutter 上的落地方式（重要，避免“伪液态玻璃”）
/// Flutter 的 `dart:ui` 只提供 `ImageFilter.blur/dilate/erode/matrix/compose`，
/// **没有**开放的“采样 backdrop 纹理的自定义 ImageFilter”入口，因此
/// `BackdropFilter` 无法直接把背景按位移场重采样。
/// 本实现采用 **解析式折射** 路线（`LiquidGlassRefraction`）：
///
/// 1. 用与文档完全相同的 **圆角矩形 SDF** 计算每个像素的归一化深度 `t`；
/// 2. 用文档里 `buildProfile()` 的同一套数学（凸超椭圆 + Snell n=1.5）
///    算出边缘的位移量剖面；
/// 3. 把“位移 → 采样偏移”这一物理结果**解析地**还原成视觉层：
///    * 边缘放大/弯折 → 用径向渐变（`_LensEdgePainter`）在包围带内做出
///      被放大、被弯折的亮度增量（凸透镜汇聚光 → 边缘更亮）；
///    * 色散 → 冷暖双色 1px 描边（文档 1.5 节的“廉价替代方案”）；
///    * 高光 → 由 `∇SDF` 与 45° 光源做点积得到的单侧镜面反射；
///    * 内阴影 → 上暗下亮的 inset 渐变（玻璃厚度感）。
///
/// 这套实现是**纯解析、逐帧确定**的：不采样实时背景、不依赖光栅缓存，
/// 因此天然不会出现“图像缺失色带 / 滑动闪烁”。
/// 它也提供了 [GlassMode.blur] 作为经典高斯模糊回退（设置里可切换）。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/hive/app_settings.dart';

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

  /// 色散强度（0 = 关闭；Android 侧 7 次采样很贵，这里用冷暖描边近似）。
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
  /// `1` = 位移最大（已到面板边缘）。等价于 Kyant0 shader 里的
  /// `circleMap` 参数：`位移 = circleMap(归一化深度) × refractionAmount`。
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
        style: GlassStyle(blur: sigma, specular: 0, dispersion: 0, innerShadow: 0.10),
        enableRefraction: false,
        enableDispersion: false,
        enableSpecular: false,
        enableInnerShadow: true,
        blurSigma: sigma,
        saturation: 1,
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
    required super.child,
  });

  final GlassMaterial material;

  static GlassMaterial of(BuildContext context) {
    final GlassScope? scope =
        context.dependOnInheritedWidgetOfExactType<GlassScope>();
    return scope?.material ?? GlassMaterial.liquid();
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
      oldWidget.material.blurSigma != material.blurSigma;
}
