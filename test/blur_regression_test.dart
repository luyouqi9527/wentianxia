import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wentianxia/core/widgets/blur_container.dart';

/// 1.0.1 回归测试：毛玻璃控件的层结构必须满足
/// 「ClipRRect → BackdropFilter → 可见 Container」，且**中间不能出现
/// `RepaintBoundary`**。
///
/// 背景：`BackdropFilter` 依赖「自己下方已绘制的像素」。如果在它外面套
/// `RepaintBoundary`，Flutter 会把该子树提升为独立层，backdrop 采样范围被
/// 截断，表现为控件下方出现**图像缺失的空白带**，滑动时还会闪烁。
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              // 模拟页面内容：毛玻璃需要它作为采样源
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

  /// 断言：从 blur 控件子树往下找 `BackdropFilter` 的整条祖先链上不得有
  /// `RepaintBoundary`（`ClipRect`/`ClipRRect` 允许存在）。
  void expectNoRepaintBoundaryAboveBackdropFilter(WidgetTester tester) {
    final Iterable<Element> backdropFilters = find
        .byType(BackdropFilter)
        .evaluate();
    expect(backdropFilters, isNotEmpty, reason: '毛玻璃控件必须包含 BackdropFilter');

    for (final Element element in backdropFilters) {
      element.visitAncestorElements((Element ancestor) {
        expect(
          ancestor.widget.runtimeType.toString(),
          isNot('RepaintBoundary'),
          reason: 'BackdropFilter 上方不允许出现 RepaintBoundary'
              '（会截断 backdrop 采样 → 图像缺失色带 + 滑动闪烁）',
        );
        // 只检查到页面级 Stack 为止
        if (ancestor.widget is Stack) return false;
        return true;
      });
    }
  }

  testWidgets('BlurContainer 使用 ClipRRect + BackdropFilter，且不包 RepaintBoundary',
      (WidgetTester tester) async {
    await pump(
      tester,
      const BlurContainer.rounded(
        blur: 10,
        child: SizedBox(width: 120, height: 44, child: Text('观看全文')),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRRect), findsWidgets);
    expectNoRepaintBoundaryAboveBackdropFilter(tester);

    // 直接确认：这棵子树里没有任何 RepaintBoundary
    expect(
      find.descendant(
        of: find.byType(BlurContainer),
        matching: find.byType(RepaintBoundary),
      ),
      findsNothing,
      reason: 'BlurContainer 内部不得包含 RepaintBoundary',
    );
  });

  testWidgets('BlurButton 不包 RepaintBoundary（flat 与模糊两种形态）',
      (WidgetTester tester) async {
    await pump(
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
    // 非 flat 的按钮必须产生 backdrop 层；flat 的按钮用静态填充，不产生
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BlurButton),
        matching: find.byType(RepaintBoundary),
      ),
      findsNothing,
    );
    expectNoRepaintBoundaryAboveBackdropFilter(tester);
  });

  testWidgets('GlassBackdrop 铺满全屏并绘制渐变（模糊区域的兜底采样源）',
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

    // 铺满：宽度等于屏幕宽度
    final Size size = tester.getSize(find.byType(GlassBackdrop));
    expect(size.width, tester.view.physicalSize.width / tester.view.devicePixelRatio);
  });

  testWidgets('GlassTint 不引入新的 backdrop 层（用于模糊条内部的按钮）',
      (WidgetTester tester) async {
    await pump(
      tester,
      const GlassTint(child: SizedBox(width: 40, height: 40)),
    );

    expect(find.byType(GlassTint), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing,
        reason: 'GlassTint 必须是静态半透明填充，不能再叠一层 BackdropFilter');
  });
}
