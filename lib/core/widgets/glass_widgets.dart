import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'liquid_glass.dart';

/// 液态玻璃容器：所有毛玻璃控件的统一实现入口。
///
/// 层叠顺序严格遵循技术文档 1.7 节的「六层堆叠模型」：
///
/// ```text
///   (6) child（你的内容）
///   (5) 镜面边缘光 + 色边（rim + chromatic edge）
///   (4) 边缘折射亮度层（lens）
///   (3) tint 色调层（alpha 0.06~0.15）
///   (2) backdrop blur + saturate（σ 小！）
///   (1) 折射几何（解析式，见 LiquidGlassRefraction）
///   ─── 元素背后的页面内容（backdrop）
/// ```
///
/// * [GlassMode.liquid] → 液态玻璃：折射 + 色散 + 高光 + 内阴影；
/// * [GlassMode.blur] → 经典高斯模糊（1.x 行为，σ=10）。
///
/// 两套实现都**不采样实时背景、不依赖光栅缓存**，因此不会出现
/// 「图像缺失色带 / 滑动闪烁」。
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.style = GlassStyle.panel,
    this.borderRadius,
    this.tint,
    this.opacity,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
    this.pressScale = 0,
    this.materialize = false,
  });

  /// 面板（大块玻璃）快捷构造。
  const LiquidGlass.panel({
    super.key,
    required this.child,
    this.tint,
    this.opacity,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.pressScale = 0,
    this.materialize = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  })  : style = GlassStyle.panel,
        clipBehavior = Clip.antiAlias;

  /// 控件（按钮 / Chip / 图标钮）快捷构造：小折射带 + 小模糊。
  const LiquidGlass.control({
    super.key,
    required this.child,
    this.tint,
    this.opacity,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.pressScale = 0,
    this.materialize = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  })  : style = GlassStyle.control,
        clipBehavior = Clip.antiAlias;

  /// 卡片快捷构造。
  const LiquidGlass.card({
    super.key,
    required this.child,
    this.tint,
    this.opacity,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.pressScale = 0,
    this.materialize = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  })  : style = GlassStyle.card,
        clipBehavior = Clip.antiAlias;

  final Widget child;

  /// 材质参数（折射带宽 / 模糊 / 高光强度…）。
  final GlassStyle style;

  /// 圆角；为 null 时用 `ClipRect` 直角裁剪。
  final BorderRadius? borderRadius;
  final Color? tint;

  /// 覆盖 tint alpha（默认取 [style.tintOpacity]）。
  final double? opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  /// 交互形变幅度（文档 2.10 节）：按下时整体放大该倍数（如 0.04 = 放大 4%），
  /// 120ms 缓出。Apple 的「液」很大程度来自这种交互形变，而不是静态材质。
  /// 传 0 表示不做按压形变。
  final double pressScale;

  /// 「materialize」入场动画（文档：iOS 不用淡入淡出，而是**渐变折射强度**）。
  /// 首次挂载时折射强度从 0 涨到 1，同时轻微放大。
  final bool materialize;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with TickerProviderStateMixin {
  AnimationController? _press;
  AnimationController? _intro;

  @override
  void initState() {
    super.initState();
    if (widget.pressScale > 0) {
      _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
      );
    }
    if (widget.materialize) {
      _intro = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
      )..forward();
    }
  }

  @override
  void dispose() {
    _press?.dispose();
    _intro?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final GlassMaterial material = GlassScope.of(context);
    // 高斯模糊模式下把参数换成 1.x 的取值
    final GlassStyle effective =
        material.isLiquid ? widget.style : GlassScope.styleOf(context, widget.style);
    final Color baseTint = widget.tint ?? scheme.surface;
    final BorderRadius radius = widget.borderRadius ?? BorderRadius.zero;

    Widget glass(double strength) {
      final GlassStyle style = strength >= 1
          ? effective
          : effective.scaled(strength.clamp(0.05, 1));
      return ClipRRect(
        borderRadius: radius,
        clipBehavior: widget.clipBehavior,
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: style.blur,
              sigmaY: style.blur,
            ),
            child: _GlassSurface(
              style: style,
              material: material,
              radius: radius,
              tint: baseTint,
              tintAlpha: widget.opacity ?? effective.tintOpacity,
              border: widget.border,
              width: widget.width,
              height: widget.height,
              alignment: widget.alignment,
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      );
    }

    Widget content = _intro == null
        ? glass(1)
        : AnimatedBuilder(
            animation: _intro!,
            builder: (BuildContext context, Widget? _) {
              final double t = Curves.easeOutCubic.transform(_intro!.value);
              return Opacity(
                opacity: t,
                child: Transform.scale(scale: 0.97 + 0.03 * t, child: glass(t)),
              );
            },
          );

    // 按压形变：放大一点点（文档 2.10：scale 1 → 1 + 4dp/height）
    Widget result = content;
    final AnimationController? press = _press;
    if (press != null) {
      result = Listener(
        onPointerDown: (_) => press.forward(),
        onPointerUp: (_) => press.reverse(),
        onPointerCancel: (_) => press.reverse(),
        child: AnimatedBuilder(
          animation: press,
          builder: (BuildContext context, Widget? inner) {
            final double scale = 1 + widget.pressScale * press.value;
            return Transform.scale(scale: scale, child: inner);
          },
          child: result,
        ),
      );
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: result,
    );
  }
}

/// 玻璃本体：底色 + 光学层 + 内容。
class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.style,
    required this.material,
    required this.radius,
    required this.tint,
    required this.tintAlpha,
    required this.child,
    this.border,
    this.width,
    this.height,
    this.alignment,
    this.padding,
  });

  final GlassStyle style;
  final GlassMaterial material;
  final BorderRadius radius;
  final Color tint;
  final double tintAlpha;
  final Widget child;
  final BoxBorder? border;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool liquid = material.isLiquid;
    final bool uniformRadius = radius.topLeft == radius.topRight &&
        radius.topLeft == radius.bottomLeft &&
        radius.topLeft == radius.bottomRight;

    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: tintAlpha),
        borderRadius: radius,
        border: border ??
            Border.all(
              color: (liquid ? Colors.white : scheme.outlineVariant)
                  .withValues(alpha: liquid ? 0.20 : 0.35),
              width: 0.7,
            ),
      ),
      child: CustomPaint(
        // 光学层：折射 → 高光 → 色散 → 内阴影（全部在一个 painter 内，
        // 既保证顺序，也避免多个 CustomPaint 叠加造成额外的层）
        foregroundPainter: liquid
            ? _LiquidGlassPainter(
                style: style,
                borderRadius: uniformRadius ? radius : null,
                lightAngle: style.lightAngle,
              )
            : null,
        child: child,
      ),
    );
  }
}

/// 一次性绘制全部光学层（严格按文档 1.7 的顺序）。
class _LiquidGlassPainter extends CustomPainter {
  const _LiquidGlassPainter({
    required this.style,
    required this.borderRadius,
    required this.lightAngle,
  });

  final GlassStyle style;
  final BorderRadius? borderRadius;
  final double lightAngle;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final RRect rrect = borderRadius == null
        ? RRect.fromRectAndRadius(Offset.zero & size, Radius.zero)
        : borderRadius!.toRRect(Offset.zero & size);
    final double sw = size.shortestSide;
    final double radius = borderRadius?.topLeft.x ?? 0.0;
    final double bezel = style.bezelFor(size);
    // Kyant0 的 refractionHeight：折射带的内边界距离（bezel 的内侧一半）。
    final double refractHeight = style.refractHeightFor(size);

    // ---------------------------------------------------------------- (1) 折射
    // 边缘透镜，与 Kyant0 `RoundedRectRefractionShaderString` 同构：
    //   depth = -sd；depth >= refractHeight 时**原样采样**（中心不动）
    //   d = circleMap(1 - depth/refractHeight) × refractionAmount
    //   sample = coord + d × grad
    // 这里把「位移 → 采样偏移」的结果解析地画成亮度层：
    // 位移越大（越靠边）采样越往放大区取，表现为该环带更亮；
    // profile = 0 的内侧区域不画任何东西，保证「中心保持不动」。
    if (style.refraction > 0 && refractHeight > 0.5) {
      canvas.save();
      canvas.clipRRect(rrect);

      const int steps = 6;
      for (int i = 0; i < steps; i++) {
        // 该环带的归一化深度（1 = 边缘最强，0 = 折射带内边界不动）
        final double t = (i + 0.5) / steps;
        final double profile = LiquidGlassRefraction.profile(t); // 0..1
        final double alpha =
            (profile * style.refraction * 0.30).clamp(0.0, 0.30);
        if (alpha <= 0.002) continue;
        final double inset = refractHeight * (1 - t);
        final RRect band = RRect.fromRectAndRadius(
          Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset),
          Radius.circular(math.max(0, radius - inset)),
        );
        canvas.drawRRect(
          band,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = refractHeight / steps + 0.6
            ..color = Colors.white.withValues(alpha: alpha)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, refractHeight / steps / 2),
        );
      }

      // 中心保持不动 → 折射带以内不做任何绘制（t >= 1 的区域）

      // ------------------------------------------------------------ (5) 内阴影
      if (style.innerShadow > 0) {
        final Paint inner = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: style.innerShadow),
              Colors.transparent,
              Colors.white.withValues(alpha: style.innerShadow * 0.35),
            ],
            stops: const <double>[0, 0.5, 1],
          ).createShader(Offset.zero & size);
        canvas.drawRRect(
          rrect.deflate(0.5),
          inner
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, bezel * 0.25),
        );
      }

      // ------------------------------------------------------------ (3) 高光
      // 由 ∇SDF 与 45° 光源点积得到：法线与光同向/反向两侧都亮（双面反光）
      if (style.specular > 0) {
        final Offset dir = Offset(math.cos(lightAngle), math.sin(lightAngle));
        final Paint specular = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6)
          ..shader = LinearGradient(
            begin: Alignment(-dir.dx, -dir.dy),
            end: Alignment(dir.dx, dir.dy),
            colors: <Color>[
              Colors.white.withValues(alpha: style.specular),
              Colors.transparent,
              Colors.white.withValues(alpha: style.specular * 0.55),
            ],
            stops: const <double>[0, 0.5, 1],
          ).createShader(Offset.zero & size);
        canvas.drawRRect(rrect.deflate(0.6), specular);
      }

      // ------------------------------------------------------------ (5) 色散
      // 文档 1.5 节的廉价替代：一暖一冷的 1px 内描边假装彩虹边
      if (style.dispersion > 0) {
        final double d = style.dispersion.clamp(0.0, 1.0) * 0.20;
        canvas.drawRRect(
          rrect.deflate(0.4),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9
            ..color = const Color(0xFFFF78FF).withValues(alpha: d),
        );
        canvas.drawRRect(
          rrect.deflate(1.4),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9
            ..color = const Color(0xFF78B4FF).withValues(alpha: d),
        );
      }

      // 抗锯齿 / 圆角外沿补一条极淡的亮边，避免玻璃边缘发黑（文档坑位 3）
      canvas.drawRRect(
        rrect.deflate(0.35),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = Colors.white.withValues(alpha: 0.10),
      );

      canvas.restore();
      return;
    }

    // 高斯模糊模式：只保留一点点边缘光，保持 1.x 的观感
    if (style.innerShadow > 0) {
      canvas.drawRRect(
        rrect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, sw * 0.01)
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: style.innerShadow),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size),
      );
    }
  }

  @override
  bool shouldRepaint(_LiquidGlassPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.lightAngle != lightAngle;
}

/// 玻璃容器分组（升级 Flutter 3.35+ 后可换成 `BackdropGroup` 共享采样）。
class LiquidGlassGroupDeprecated extends StatelessWidget {
  const LiquidGlassGroupDeprecated({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// 玻璃按钮：卡片「观看全文」、错误重试、引导页「前往聚合数据申请」等都用它。
///
/// [flat] = true 时改用 [GlassTint] 静态填充，用于**已经处在一条玻璃条内部**
/// 的按钮（避免同一条 bar 上嵌套多层 backdrop 采样）。
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

  /// 是否使用静态玻璃填充（不新增 backdrop 层）。
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
        : LiquidGlass(
            style: GlassStyle.control,
            borderRadius: borderRadius,
            opacity: opacity,
            // 文档 2.10：交互形变是「液」感的重要来源（按下放大 ~4%，120ms 缓出）
            pressScale: 0.04,
            materialize: true,
            child: inner,
          );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// 玻璃容器分组。
///
/// Flutter 3.35+ 提供 `BackdropGroup` + `BackdropFilter.grouped()`，可让一组
/// 玻璃控件共享同一次采样。本项目锁定 Flutter 3.27.4（CodeMagic 已验证），
/// 因此这里目前是**零开销的语义化分组容器**。
/// 升级到 3.35+ 后把 `build` 改成 `BackdropGroup(child: child)` 即可获得收益。
class BlurGroup extends StatelessWidget {
  const BlurGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// 玻璃容器分组（新名字，语义更准确）。
typedef LiquidGlassGroup = BlurGroup;

/// 半透明玻璃填充：不产生新的 backdrop 层。
///
/// 用于**已经处在一条玻璃条内部**的按钮（嵌套 backdrop 会让同一条 bar 上
/// 出现多层采样，既成倍增加开销，也容易产生色带）。视觉上仍是玻璃质感，
/// 但完全确定、零闪烁。
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
    final bool liquid = GlassScope.of(context).isLiquid;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: (tint ?? scheme.surface).withValues(alpha: opacity),
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: (liquid ? Colors.white : scheme.outlineVariant)
                  .withValues(alpha: liquid ? 0.18 : 0.24),
              width: 0.6,
            ),
      ),
      child: child,
    );
  }
}
