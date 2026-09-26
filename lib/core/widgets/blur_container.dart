import 'dart:ui';

import 'package:flutter/material.dart';

/// 通用高斯模糊（毛玻璃）容器。
///
/// ## 实现要点
/// * `BackdropFilter.filter` 使用 `ImageFilter.blur(sigmaX: 10, sigmaY: 10)`；
/// * `BackdropFilter` 的 child 必须是一个可见的 `Container`/装饰盒，否则看不到模糊；
/// * 用 `ClipRRect` / `ClipRect` 包裹，模糊只在控件范围内生效；
///
/// ## ⚠️ 1.0.1 修复：为什么这里不能再包 `RepaintBoundary`
/// `BackdropFilter` 属于 **backdrop 层**：它必须采样「自己下方已经画好的画面」。
/// 一旦在它外面套一个 `RepaintBoundary`，Flutter 会把该子树提升为独立的
/// `OffsetLayer`，同时把 backdrop 采样范围**截断在这个独立层内**——
/// 于是模糊只能拿到该层内部的（往往只有半透明控件的）像素，
/// 表现为控件下方出现一条**图像缺失的空白/灰白色带**；滑动时该层又被
/// 光栅缓存复用，就进一步表现为**闪烁**。
///
/// 因此 1.0.1 起：
/// * 模糊控件**不再**包裹 `RepaintBoundary`；
/// * 需要隔离重绘时，把 `RepaintBoundary` 包在**整块可滚动内容的上一层**
///   （例如 `Stack` 中的页面内容），让 backdrop 有完整且稳定的采样源；
/// * 每个界面用 [GlassBackdrop] 铺一层全屏底，确保模糊区域下方**永远有像素**。
///
/// 多个模糊控件共享同一背景时放进 [BlurGroup]（升级 Flutter 3.35+ 可获得
/// `BackdropGroup` 的共享采样优化）。
class BlurContainer extends StatelessWidget {
  const BlurContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 10,
    this.tint,
    this.opacity = 0.15,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
  });

  /// 圆角模糊容器（最常用）。
  const BlurContainer.rounded({
    super.key,
    required this.child,
    this.blur = 10,
    this.tint,
    this.opacity = 0.15,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
  })  : borderRadius = const BorderRadius.all(Radius.circular(16)),
        clipBehavior = Clip.antiAlias;

  final Widget child;

  /// 圆角；为 null 时使用 `ClipRect`（矩形局部模糊）。
  final BorderRadius? borderRadius;
  final double blur;
  final Color? tint;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color baseTint = tint ?? scheme.surface;

    final Widget content = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        // 半透明底色：让模糊“看得见”。
        color: baseTint.withValues(alpha: opacity),
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
              width: 0.8,
            ),
      ),
      child: child,
    );

    // 注意：这里刻意不包 RepaintBoundary（原因见类文档）。
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}

/// 全屏「玻璃底」：铺在页面内容的最底层，保证任何毛玻璃控件下方
/// **永远有已绘制的像素**，杜绝 backdrop 采样到空白导致的缺失色带。
///
/// 用法（放在 `Stack` 的第一个 child）：
/// ```dart
/// Stack(children: <Widget>[
///   const GlassBackdrop(),        // 底层：全屏渐变
///   content,                       // 上层：滚动内容
///   blurredControls,               // 最上层：毛玻璃控件
/// ]);
/// ```
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    this.brightness = Brightness.dark,
    this.colors,
    this.imageUrl,
    this.child,
  });

  /// 深色（默认）/ 浅色底。
  final Brightness brightness;

  /// 自定义渐变（默认按 [brightness] 给一套深/浅色渐变）。
  final List<Color>? colors;

  /// 可选：底图（会填满全屏，作为毛玻璃的真实采样内容）。
  final String? imageUrl;

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

/// 半透明「玻璃填充」：不产生新的 backdrop 层。
///
/// 用于**已经处在一条模糊条内部**的按钮（例如全文页底部操作栏里的
/// 收藏 / 分享按钮）。嵌套 `BackdropFilter` 会让同一条 bar 上出现多个
/// backdrop 层：既成倍增加开销，又容易在滑动时产生色带与闪烁。
/// 这里改用静态半透明填充，视觉上仍是毛玻璃质感，但完全确定、零闪烁。
class GlassTint extends StatelessWidget {
  const GlassTint({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.opacity = 0.16,
    this.tint,
    this.border,
    this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double opacity;
  final Color? tint;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: (tint ?? scheme.surface).withValues(alpha: opacity),
        borderRadius: borderRadius,
        border: border ??
            Border.all(color: Colors.white24, width: 0.6),
      ),
      child: child,
    );
  }
}

/// 模糊控件分组。
///
/// 性能优化说明：Flutter 3.35+ 提供了 `BackdropGroup` + `BackdropFilter.grouped()`，
/// 可让一组模糊控件共享同一次背景采样。本项目锁定 Flutter 3.27.4（CodeMagic 上
/// 已验证的稳定版本），该 API 尚不可用，因此这里是一个**零开销的语义化分组容器**。
///
/// 升级到 Flutter 3.35+ 时，只需把 `build` 改成 `BackdropGroup(child: child)`
/// 即可获得共享采样的性能收益，业务代码无需改动。
class BlurGroup extends StatelessWidget {
  const BlurGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// 毛玻璃按钮：可点击的高斯模糊控件。
class BlurButton extends StatelessWidget {
  const BlurButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.blur = 10,
    this.opacity = 0.16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.foregroundColor,
    this.expand = false,
    this.tooltip,
    this.flat = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? foregroundColor;
  final bool expand;
  final String? tooltip;

  /// 置为 true 时改用静态半透明填充（[GlassTint]）而不是再叠一层 backdrop。
  /// 用于**已经位于模糊条内部**的按钮，避免同一条 bar 上嵌套 backdrop 层
  /// 导致的滑动色带 / 闪烁。
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg = foregroundColor ?? theme.colorScheme.onSurface;

    final Widget inner = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget button = flat
        ? GlassTint(
            borderRadius: borderRadius,
            opacity: opacity + 0.04,
            tint: theme.colorScheme.surface,
            child: inner,
          )
        : BlurContainer(
            borderRadius: borderRadius,
            blur: blur,
            opacity: opacity,
            child: inner,
          );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// 顶部 / 底部毛玻璃状态栏容器：整条横幅一次模糊，避免一条 bar 里出现
/// 多个 backdrop 层叠加导致的色带与闪烁。
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
    final BorderRadius radius = BorderRadius.vertical(
      // top=true 表示这是顶部条：上侧直角、下侧圆角
      top: top ? Radius.zero : const Radius.circular(20),
      bottom: bottom ? Radius.zero : const Radius.circular(20),
    );

    return BlurContainer(
      borderRadius: radius,
      blur: blur,
      opacity: opacity,
      tint: color,
      border: Border.all(
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.28),
        width: 0.6,
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
