import 'dart:ui' show FragmentProgram;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wentianxia/core/widgets/blur_container.dart';
import 'package:wentianxia/core/widgets/liquid_glass.dart';
import 'package:wentianxia/features/news/views/article_detail_page.dart';
import 'package:wentianxia/shared/hive/app_settings.dart';

/// 玻璃控件层结构回归测试（1.0.1 修复 + 2.x/3.x 重构后的约定）。
///
/// 背景：`BackdropFilter` 依赖「自己下方已绘制的像素」。如果在它外层乱包
/// `RepaintBoundary`，Flutter 会把子树提升为独立层，backdrop 采样范围被截断，
/// 表现为控件下方出现**图像缺失的空白带**并随滚动**闪烁**。
///
/// 3.0.0 约定的层结构（唯一允许的形态）：
///
/// ```text
/// ClipRRect → RepaintBoundary → [BackdropFilter(blur) → BackdropFilter(shader)] → 装饰盒 → child
/// ```
///
/// 即：两层 `BackdropFilter`（下层背景模糊、上层 shader 真折射）**共用同一个**
/// `RepaintBoundary`；绝不允许每层各包一个，否则 backdrop 采样会被切成两段。
void main() {
  Future<void> pumpGlass(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF223344)),
                ),
              ),
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }

  /// 断言：从 `BackdropFilter` 往上到页面 `Stack` 之间，`RepaintBoundary` 至多 1 个。
  void expectBoundedRepaintBoundaries(WidgetTester tester) {
    final Iterable<Element> backdropFilters =
        find.byType(BackdropFilter).evaluate();
    expect(backdropFilters, isNotEmpty, reason: '玻璃控件必须包含 BackdropFilter');

    for (final Element element in backdropFilters) {
      int boundaries = 0;
      element.visitAncestorElements((Element ancestor) {
        if (ancestor.widget.runtimeType.toString() == 'RepaintBoundary') {
          boundaries++;
        }
        if (ancestor.widget is Stack) return false;
        return true;
      });
      expect(
        boundaries,
        lessThanOrEqualTo(1),
        reason: 'BackdropFilter 上方最多只能有 1 个 RepaintBoundary'
            '（多出来的会截断 backdrop 采样 → 图像缺失色带 + 滑动闪烁）',
      );
    }
  }

  testWidgets('BlurContainer：ClipRRect → RepaintBoundary → BackdropFilter 固定结构',
      (WidgetTester tester) async {
    await pumpGlass(
      tester,
      const BlurContainer.rounded(
        child: SizedBox(width: 120, height: 44, child: Text('观看全文')),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRRect), findsWidgets);
    expectBoundedRepaintBoundaries(tester);
  });

  testWidgets('BlurButton：普通形态有 backdrop 层，flat 形态没有',
      (WidgetTester tester) async {
    await pumpGlass(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BlurButton(label: '观看全文', onPressed: () {}),
          const SizedBox(height: 12),
          BlurButton(label: '切换频道', flat: true, onPressed: () {}),
        ],
      ),
    );

    expect(find.text('观看全文'), findsOneWidget);
    expect(find.text('切换频道'), findsOneWidget);
    // 非 flat 的按钮产生 backdrop 层；flat 的按钮用静态填充，不产生
    expect(find.byType(BackdropFilter), findsOneWidget);
    expectBoundedRepaintBoundaries(tester);
  });

  testWidgets('GlassBackdrop 铺满全屏并绘制渐变（玻璃区域的兜底采样源）',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              GlassBackdrop(),
              Center(child: Text('内容')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(GlassBackdrop), findsOneWidget);
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(GlassBackdrop),
        matching: find.byType(DecoratedBox),
      ),
    );
    final BoxDecoration decoration = box.decoration as BoxDecoration;
    expect(decoration.gradient, isNotNull, reason: '兜底底必须是已绘制的渐变');
  });

  testWidgets('GlassTint 不引入新的 backdrop 层（用于玻璃条内部的按钮）',
      (WidgetTester tester) async {
    await pumpGlass(
      tester,
      const GlassTint(child: SizedBox(width: 40, height: 40)),
    );

    expect(find.byType(GlassTint), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing,
        reason: 'GlassTint 必须是静态半透明填充，不能再叠一层 BackdropFilter');
  });

  group('液态玻璃折射数学（与《液态玻璃实现技术文档》一致）', () {
    test('圆角矩形 SDF：内部为负、边界为 0、外部为正', () {
      final double center = LiquidGlassSdf.sdRoundedRect(
        Offset.zero,
        const Size(100, 50),
        20,
      );
      expect(center, lessThan(0));

      final double edge = LiquidGlassSdf.sdRoundedRect(
        const Offset(100, 0),
        const Size(100, 50),
        20,
      );
      expect(edge, closeTo(0, 0.001));

      final double outside = LiquidGlassSdf.sdRoundedRect(
        const Offset(140, 0),
        const Size(100, 50),
        20,
      );
      expect(outside, greaterThan(0));
    });

    test('折射剖面 circleMap：内边界为 0、边缘为 1、单调递增', () {
      expect(LiquidGlassRefraction.profile(0), closeTo(0, 1e-9));
      expect(LiquidGlassRefraction.profile(1), closeTo(1, 1e-9));
      double previous = -1;
      for (int i = 0; i <= 20; i++) {
        final double v = LiquidGlassRefraction.profile(i / 20);
        expect(v, greaterThanOrEqualTo(previous - 1e-9));
        previous = v;
      }
    });

    test('归一化深度：折射带内边界为 0（不动）、越靠边越接近 1', () {
      const Size size = Size(200, 120);
      final double atBandInner = LiquidGlassSdf.normalizedDepth(
        const Offset(96, 0),
        size,
        refractHeight: 4,
        radius: 20,
      );
      expect(atBandInner, closeTo(0.0, 0.02));

      final double nearEdge = LiquidGlassSdf.normalizedDepth(
        const Offset(99, 0),
        size,
        refractHeight: 4,
        radius: 20,
      );
      expect(nearEdge, greaterThan(atBandInner));

      final double center = LiquidGlassSdf.normalizedDepth(
        Offset.zero,
        size,
        refractHeight: 4,
        radius: 20,
      );
      expect(center, 0.0);
    });

    test('bezel 取值遵循文档公式 clamp(min(w,h) × 0.12, 6, 28)', () {
      const GlassStyle style = GlassStyle();
      expect(style.bezelFor(const Size(400, 300)), closeTo(28, 0.001));
      expect(style.bezelFor(const Size(100, 80)), closeTo(9.6, 0.001));
      expect(style.bezelFor(const Size(20, 20)), closeTo(6, 0.001));
    });

    test('材质映射：液态玻璃开启折射与色散，高斯模糊全部关闭', () {
      final GlassMaterial liquid = GlassMaterial.liquid();
      expect(liquid.isLiquid, isTrue);
      expect(liquid.enableRefraction, isTrue);
      expect(liquid.enableDispersion, isTrue);
      expect(liquid.blurSigma, lessThanOrEqualTo(4),
          reason: '文档：模糊必须小，否则会抹平折射细节');

      final GlassMaterial blur = GlassMaterial.blur();
      expect(blur.mode, GlassMode.blur);
      expect(blur.enableRefraction, isFalse);
      expect(blur.enableSpecular, isFalse);
      expect(blur.blurSigma, 10);
    });
  });

  group('着色器真折射的能力探测与降级', () {
    test('着色器资产路径固定，且加载失败时返回 null 而不抛异常', () async {
      expect(LiquidGlassShader.assetPath, 'shaders/liquid_glass.frag');
      // 测试环境（flutter_tester / Skia）通常不支持 shader 型 ImageFilter；
      // 无论支持与否，load() 都**不得抛异常**：要么返回程序，要么返回 null。
      LiquidGlassShader.resetForTest();
      final FragmentProgram? program = await LiquidGlassShader.load();
      if (!LiquidGlassShader.isSupported) {
        expect(program, isNull, reason: '不支持时必须安静地返回 null 以便降级');
      }
      LiquidGlassShader.resetForTest();
    });

    test('GlassScope 在没有着色器时判定为不可折射', () {
      final GlassMaterial material = GlassMaterial.liquid();
      final GlassScope scope = GlassScope(
        material: material,
        child: const SizedBox.shrink(),
      );
      expect(scope.refractive, isFalse, reason: 'shaderProgram 为 null → 必须降级');
    });
  });

  group('全文页自动滚动（2.0.0 修复）', () {
    test('默认不启动自动滚动', () {
      expect(ArticleDetailPage.autoScrollByDefault, isFalse,
          reason: '2.0.0 起默认不启动自动滚动，只有用户点按钮才滚动');
    });
  });
}
