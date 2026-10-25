import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mortgage_calc/features/flush/flush_screen.dart';
import 'package:mortgage_calc/providers/calculator_provider.dart';

/// 输入框显示的数必须就是参与计算的数：
/// 以前填 0 时只改了输入框，计算仍按上一个有效值 2000 元在算。
void main() {
  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: FlushScreen()),
    ));
    return container;
  }

  testWidgets('每月公积金填 0：按 0 计算', (tester) async {
    final container = await pumpScreen(tester);
    expect(container.read(pfAmountProvider), 2000);

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.pump();

    expect(container.read(pfAmountProvider), 0);
    expect(container.read(flushComparisonProvider).monthlyPfAmount, 0);
    expect(find.text('对比结果'), findsOneWidget);
  });

  testWidgets('负数或非数字：标错并暂停展示结果，不沿用旧值', (tester) async {
    final container = await pumpScreen(tester);

    for (final input in ['-100', 'abc']) {
      await tester.enterText(find.byType(TextFormField), input);
      await tester.pump();

      expect(find.text('请输入 ≥ 0 的金额'), findsOneWidget);
      expect(find.text('对比结果'), findsNothing);
      expect(container.read(pfAmountProvider), 2000);
    }

    await tester.enterText(find.byType(TextFormField), '1500');
    await tester.pump();
    expect(find.text('请输入 ≥ 0 的金额'), findsNothing);
    expect(container.read(pfAmountProvider), 1500);
  });
}
