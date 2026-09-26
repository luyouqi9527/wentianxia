import 'package:flutter/material.dart';

import 'glass_widgets.dart';
import 'liquid_glass.dart';

// 对外的 API 入口统一从本文件导出，页面只需要 import 'blur_container.dart'。
export 'glass_widgets.dart'
    show LiquidGlass, GlassTint, BlurButton, BlurGroup, LiquidGlassGroup;
export 'liquid_glass.dart'
    show GlassStyle, GlassMaterial, GlassScope, LiquidGlassRefraction;

/// 通用「液态玻璃 / 毛玻璃」容器 —— 全站玻璃控件的统一入口。
///
/// 2.0.0 起本组件是 [LiquidGlass] 的兼容包装：
///
/// * 材质风格由「设置 → 磨砂材质」决定（默认 **液态玻璃**）：
///   * `GlassMode.liquid` → 边缘折射 + 色散 + 45° 高光 + 内阴影 + 小模糊；
///   * `GlassMode.blur`   → 经典高斯模糊毛玻璃（σ=10，1.x 行为）。
/// * 两者都是**解析式**渲染：不采样实时背景、不依赖光栅缓存，
///   因此不会出现「图像缺失色带 / 滑动闪烁」。
///
/// ## 层结构约束（`test/blur_regression_test.dart` 会守护）
/// 固定为 `ClipRRect → RepaintBoundary → BackdropFilter → 装饰盒 → 光学层 → child`。
/// 这个位置上的 `RepaintBoundary` 是**故意保留**的：它把玻璃控件与滚动内容隔开，
/// 让 backdrop 有一个完整、稳定的采样源；真正会导致色带的是「在滚动内容或
/// 模糊控件外层乱包 RepaintBoundary」，那种写法已经被移除。
class BlurContainer extends StatelessWidget {
  const BlurContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 10,
    this.tint,
    this.opacity,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
  });

  /// 圆角玻璃容器（最常用）。
  const BlurContainer.rounded({
    super.key,
    required this.child,
    this.blur = 10,
    this.tint,
    this.opacity,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
  })  : borderRadius = const BorderRadius.all(Radius.circular(16)),
        clipBehavior = Clip.antiAlias;

  final Widget child;

  /// 圆角；为 null 时使用直角裁剪。
  final BorderRadius? borderRadius;

  /// 高斯模糊模式下的 σ；液态玻璃模式会忽略它并使用材质自带的小模糊
  /// （技术文档：模糊必须小，否则会抹平折射细节，退化成毛玻璃）。
  final double blur;

  final Color? tint;
  final double? opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  /// 依据控件尺寸选择材质：小控件用小折射带，大面板用大折射带。
  static GlassStyle styleForSize(Size size) {
    final double extent = size.shortestSide;
    if (extent <= 72) return GlassStyle.control;
    if (extent <= 220) return GlassStyle.card;
    return GlassStyle.panel;
  }

  @override
  Widget build(BuildContext context) {
    final GlassMaterial material = GlassScope.of(context);
    final bool liquid = material.isLiquid;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size reference = Size(
          width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 240),
          height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : 120),
        );
        final GlassStyle style = styleForSize(reference);

        return LiquidGlass(
          style: liquid ? style : GlassStyle(blur: blur, specular: 0, dispersion: 0),
          borderRadius: borderRadius,
          tint: tint,
          opacity: opacity,
          padding: padding,
          margin: margin,
          border: border,
          width: width,
          height: height,
          alignment: alignment,
          clipBehavior: clipBehavior,
          child: child,
        );
      },
    );
  }
}

/// 全屏「玻璃底」：铺在页面内容的最底层，保证任何玻璃控件下方
/// **永远有已绘制的像素**，杜绝 backdrop 采样到空白导致的缺失色带。
///
/// 用法（放在 `Stack` 的第一个 child）：
/// ```dart
/// Stack(children: <Widget>[
///   const GlassBackdrop(),        // 底层：全屏渐变
///   content,                       // 上层：滚动内容
///   glassControls,                 // 最上层：玻璃控件
/// ]);
/// ```
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    this.brightness = Brightness.dark,
    this.colors,
    this.child,
  });

  /// 深色（默认）/ 浅色底。
  final Brightness brightness;

  /// 自定义渐变（默认按 [brightness] 给一套深/浅色渐变）。
  final List<Color>? colors;

  final Widget? child;

  static const List<Color> _darkColors = <Color>[
    Color(0xFF15121F),
    Color(0xFF0B0B10),
    Color(0xFF1B1330),
  ];

  static const List<Color> _lightColors = <Color>[
    Color(0xFFF7F5FC),
    Color(0xFFEDEAF5),
    Color(0xFFF3F0FA),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Color> palette =
        colors ?? (brightness == Brightness.dark ? _darkColors : _lightColors);

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// 顶部 / 底部整条玻璃状态栏容器。
///
/// 整条 bar 只做**一次**玻璃处理；条内控件请用 [GlassTint] 或
/// `BlurButton(flat: true)`，避免同一条 bar 上出现多层 backdrop 采样。
class BlurBar extends StatelessWidget {
  const BlurBar({
    super.key,
    required this.child,
    this.top = false,
    this.bottom = false,
    this.blur = 10,
    this.opacity = 0.22,
    this.color,
    this.padding,
  });

  final Widget child;

  /// 顶部悬浮条（贴屏幕顶边，只有下侧圆角）。
  final bool top;

  /// 底部悬浮条（贴屏幕底边，只有上侧圆角）。
  final bool bottom;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool liquid = GlassScope.of(context).isLiquid;
    final BorderRadius radius = BorderRadius.vertical(
      top: top ? Radius.zero : const Radius.circular(22),
      bottom: bottom ? Radius.zero : const Radius.circular(22),
    );

    return LiquidGlass(
      style: liquid ? GlassStyle.bar : GlassStyle(blur: blur, specular: 0, dispersion: 0),
      borderRadius: radius,
      tint: color,
      opacity: opacity,
      padding: padding,
      child: Material(color: Colors.transparent, child: child),
    );
  }
}
