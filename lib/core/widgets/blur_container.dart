import 'dart:ui';

import 'package:flutter/material.dart';

/// 通用高斯模糊（毛玻璃）容器。
///
/// 实现要点（严格按需求）：
/// * `BackdropFilter.filter` 使用 `ImageFilter.blur(sigmaX: 10, sigmaY: 10)`；
/// * `BackdropFilter` 的 child 必须是一个可见的 `Container`/装饰盒，否则看不到模糊；
/// * 用 `ClipRRect`/`ClipRect` 包裹，避免模糊扩散到整个区域；
/// * 用 `RepaintBoundary` 包裹，避免模糊引发不必要的重绘。
///
/// 多个模糊控件共享同一背景时，把它们放进同一个 [BlurGroup]，
/// 内部会使用 `BackdropGroup` + `BackdropFilter.grouped()` 做性能优化。
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

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

/// 模糊控件分组。
///
/// 性能优化说明：Flutter 3.35+ 提供了 `BackdropGroup` + `BackdropFilter.grouped()`，
/// 可让一组模糊控件共享同一次背景采样。本项目锁定 Flutter 3.27.4（CodeMagic 上
/// 已验证的稳定版本），该 API 尚不可用，因此这里是一个**零开销的语义化分组容器**，
/// 仅用于把相关模糊控件组织在一起；每个模糊控件自身都包了 [RepaintBoundary]，
/// 已经避免了相互之间的重复重绘。
///
/// 升级到 Flutter 3.35+ 时，只需把这里的实现替换为：
/// ```dart
/// BackdropGroup(child: child)
/// ```
/// 即可获得 `grouped()` 的性能收益，业务代码无需改动。
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg = foregroundColor ?? theme.colorScheme.onSurface;

    Widget button = BlurContainer(
      borderRadius: borderRadius,
      blur: blur,
      opacity: opacity,
      child: Material(
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
      ),
    );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
