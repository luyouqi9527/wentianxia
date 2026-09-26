import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'liquid_glass.dart';

/// 液态玻璃容器：所有玻璃控件的统一实现入口。
///
/// 渲染分两条路径，由 [GlassScope] 里的着色器可用性与材质开关决定：
///
/// | 条件 | 路径 | 效果 |
/// | --- | --- | --- |
/// | Impeller + 着色器加载成功 + 材质=液态玻璃 | `ImageFilter.shader` | **真·背景重采样折射**（边缘弯折 + 色散 + 高光） |
/// | Skia / 着色器失败 / 旧版本 | 解析式折射（`_LiquidGlassPainter`） | 近似折射（亮度带 + 色边 + 高光） |
/// | 材质=高斯模糊 | `ImageFilter.blur(σ=10)` | 经典毛玻璃（1.x 行为） |
///
/// 层结构（顺序即文档 1.7 的六层堆叠）：
///
/// ```text
///   (6) child（内容）
///   (5) 镜面高光 + 色边 + 内阴影
///   (4) 折射（shader 真折射 或 解析式亮度层）
///   (3) tint（半透明色调层）
///   (2) backdrop blur（σ 很小，避免抹平折射细节）
///   (1) 真实背景（由 BackdropFilter 采样）
/// ```
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

  /// 圆角；为 null 时用直角裁剪。
  final BorderRadius? borderRadius;
  final Color? tint;

  /// 覆盖 tint alpha（默认取 [GlassStyle.tintOpacity]）。
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

  /// 兼容旧参数（2.0.1 起已废弃）。
  ///
  /// 2.0.0 用它做「materialize 入场」（Opacity + Transform），但那会在玻璃之上
  /// 再合成一层 OpacityLayer，与 BackdropFilterLayer 叠加时偶发采样闪烁，
  /// 因此 2.0.1 去掉了该动画；参数保留只为不破坏既有调用点。
  @Deprecated('2.0.1 起玻璃不再叠加 Opacity 合成层（会引发采样闪烁），该参数已无效果')
  final bool materialize;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with TickerProviderStateMixin {
  AnimationController? _press;

  /// 复用同一个 FragmentShader 实例（文档：比每帧新建更省）。
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (widget.pressScale > 0) {
      _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
      );
    }
  }

  @override
  void dispose() {
    _press?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  /// 取（或懒创建）着色器实例；Dart 侧只需设置自定义 uniform。
  ///
  /// 索引约定（见 `shaders/liquid_glass.frag`）：
  /// `0,1 = uSize`（引擎写，禁止 Dart 设置）、`2 = uRadius`、`3 = uRefractHeight`、
  /// `4 = uRefractAmount`、`5 = uSpecular`、`6 = uLightAngle`、`7 = uDispersion`、
  /// `8 = uInnerShadow`、`9 = uSaturation`、`10 = uTintAlpha`；
  /// 第 0 个 sampler2D 由引擎绑定为背景，同样不要设置。
  FragmentShader _shaderFor(FragmentProgram program) {
    final FragmentShader shader = _shader ??= program.fragmentShader();
    return shader;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final GlassMaterial material = GlassScope.of(context);
    final FragmentProgram? program = GlassScope.programOf(context);

    final GlassStyle effective = material.isLiquid
        ? widget.style
        : GlassScope.styleOf(context, widget.style);
    final Color baseTint = widget.tint ?? scheme.surface;
    final double tintAlpha = widget.opacity ?? effective.tintOpacity;
    final BorderRadius radius = widget.borderRadius ?? BorderRadius.zero;

    final bool useShader = program != null && material.isLiquid;

    Widget glass() {
      return ClipRRect(
        borderRadius: radius,
        clipBehavior: widget.clipBehavior,
        child: RepaintBoundary(
          child: useShader
              ? _buildShaderGlass(
                  program: program,
                  style: effective,
                  material: material,
                  radius: radius,
                  scheme: scheme,
                )
              : _buildFallbackGlass(
                  style: effective,
                  material: material,
                  radius: radius,
                  tint: baseTint,
                  tintAlpha: tintAlpha,
                ),
        ),
      );
    }

    // 按压形变：放大一点点（文档 2.10：scale 1 → 1 + 4dp/height）。
    //
    // ⚠️ 2.0.1：这里曾经还套过「materialize」入场动画（Opacity + Transform.scale），
    // 它会在玻璃上方再合成一层 OpacityLayer —— 与 BackdropFilterLayer 叠加时
    // 偶发出现采样闪烁。现在玻璃回归**单层 backdrop**。
    Widget result = glass();
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

  /// 真折射路径：两层 BackdropFilter 叠加。
  ///
  /// 第一层负责**背景模糊**（σ 很小），第二层用着色器**重采样背景做折射**。
  /// 刻意不把两者塞进同一个 `ImageFilter.compose`：那是 3.38 之前不稳的用法，
  /// 叠两层是官方文档推荐的可靠做法。
  Widget _buildShaderGlass({
    required FragmentProgram program,
    required GlassStyle style,
    required GlassMaterial material,
    required BorderRadius radius,
    required ColorScheme scheme,
  }) {
    final double uniformRadius = _uniformRadius(radius);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 240,
          constraints.hasBoundedHeight ? constraints.maxHeight : 120,
        );
        final double refractHeight = style.refractHeightFor(size);
        final FragmentShader shader = _shaderFor(program);
        final double amount = style.displacementFor(size);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: style.blur, sigmaY: style.blur),
          child: BackdropFilter(
            filter: ImageFilter.shader(shader),
            child: _ShaderUniforms(
              shader: shader,
              radius: uniformRadius,
              refractHeight: refractHeight,
              refractAmount: amount,
              specular: style.specular,
              lightAngle: style.lightAngle,
              dispersion: style.dispersion,
              innerShadow: style.innerShadow,
              saturation: style.saturation,
              tintAlpha: style.tintOpacity,
              child: Container(
                width: widget.width,
                height: widget.height,
                alignment: widget.alignment,
                padding: widget.padding,
                // 只叠一层很淡的色调 + 亮边；真正的折射/高光/色散都在着色器里
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: style.tintOpacity * 0.5),
                  borderRadius: radius,
                  border: widget.border ??
                      Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.7,
                      ),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 降级路径：解析式折射（Skia / 着色器不可用 / 旧版本 Flutter）。
  Widget _buildFallbackGlass({
    required GlassStyle style,
    required GlassMaterial material,
    required BorderRadius radius,
    required Color tint,
    required double tintAlpha,
  }) {
    final bool liquid = material.isLiquid;
    final bool uniform = _isUniform(radius);
    final ColorScheme scheme = ColorScheme.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: style.blur, sigmaY: style.blur),
      child: Container(
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: tintAlpha),
          borderRadius: radius,
          border: widget.border ??
              Border.all(
                color: (liquid ? Colors.white : scheme.outlineVariant)
                    .withValues(alpha: liquid ? 0.20 : 0.35),
                width: 0.7,
              ),
        ),
        child: CustomPaint(
          // 光学层：折射 → 高光 → 色散 → 内阴影（都在一个 painter 内，保证顺序）
          foregroundPainter: liquid
              ? _LiquidGlassPainter(
                  style: style,
                  borderRadius: uniform ? radius : null,
                  lightAngle: style.lightAngle,
                )
              : null,
          child: widget.child,
        ),
      ),
    );
  }

  static bool _isUniform(BorderRadius radius) =>
      radius.topLeft == radius.topRight &&
      radius.topLeft == radius.bottomLeft &&
      radius.topLeft == radius.bottomRight;

  static double _uniformRadius(BorderRadius radius) =>
      _isUniform(radius) ? radius.topLeft.x : 0;
}

/// 每次尺寸/参数变化时把 uniform 写进着色器。
///
/// 放在布局阶段之后同步执行（`LayoutBuilder` 的 builder 内），
/// 保证 `setFloat` 发生在 `ImageFilter.shader` 使用它之前。
class _ShaderUniforms extends StatelessWidget {
  const _ShaderUniforms({
    required this.shader,
    required this.radius,
    required this.refractHeight,
    required this.refractAmount,
    required this.specular,
    required this.lightAngle,
    required this.dispersion,
    required this.innerShadow,
    required this.saturation,
    required this.tintAlpha,
    required this.child,
  });

  final FragmentShader shader;
  final double radius;
  final double refractHeight;
  final double refractAmount;
  final double specular;
  final double lightAngle;
  final double dispersion;
  final double innerShadow;
  final double saturation;
  final double tintAlpha;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 索引 0/1 是引擎写入的纹理尺寸（vec2），因此自定义 uniform 从 2 开始
    shader
      ..setFloat(2, radius)
      ..setFloat(3, refractHeight)
      ..setFloat(4, refractAmount)
      ..setFloat(5, specular)
      ..setFloat(6, lightAngle)
      ..setFloat(7, dispersion)
      ..setFloat(8, innerShadow)
      ..setFloat(9, saturation)
      ..setFloat(10, tintAlpha);
    return child;
  }
}

/// 一次性绘制全部光学层（解析式降级路径，严格按文档 1.7 的顺序）。
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
    // 边缘透镜，与 Kyant0 `RoundedRectRefractionShaderString` 同构。
    // 解析式路径把「位移 → 采样偏移」的结果画成亮度层：
    // 位移越大（越靠边）表现越亮；profile = 0 的内侧区域不画任何东西。
    if (style.refraction > 0 && refractHeight > 0.5) {
      canvas.save();
      canvas.clipRRect(rrect);

      const int steps = 6;
      for (int i = 0; i < steps; i++) {
        final double t = (i + 0.5) / steps;
        final double profile = LiquidGlassRefraction.profile(t);
        final double alpha = (profile * style.refraction * 0.30).clamp(0.0, 0.30);
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

/// 玻璃容器分组。
///
/// Flutter 3.29+ 提供 `BackdropGroup` + `BackdropFilter.grouped()`，可让一组
/// 玻璃控件共享同一次背景采样。
///
/// ⚠️ 注意：重叠的玻璃控件**不能**共享同一个 backdrop key，否则重叠区域看起来
/// 只应用了一次滤镜。本项目里各玻璃控件基本不重叠，因此这里默认开启分组优化；
/// 如有重叠（例如顶栏按钮压在顶栏上），请单独用 `BackdropFilter` 而不是 `.grouped()`。
class BlurGroup extends StatelessWidget {
  const BlurGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 3.29+ 才有 BackdropGroup；本项目基线为 3.47，直接使用。
    return BackdropGroup(child: child);
  }
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
            child: inner,
          );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
