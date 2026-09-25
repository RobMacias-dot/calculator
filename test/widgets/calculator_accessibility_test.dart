import 'package:engineering_toolkit/features/calculators/domain/calculator_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;

Future<void> chooseUnit(WidgetTester tester, String id, String symbol) async {
  final selector = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<EngineeringUnit> &&
        widget.key.toString().contains('unit-$id-'),
  );
  await tester.ensureVisible(selector);
  await tester.pumpAndSettle();
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(symbol).last);
  await tester.pumpAndSettle();
}

void main() {
  final cases = [
    (
      id: 'ohms-law',
      values: {'voltage': '220', 'resistance': '10'},
      result: '22 A',
    ),
    (
      id: 'newtons-second-law',
      values: {'mass': '1', 'acceleration': '-9.80665'},
      result: '-9.80665 N',
    ),
    (
      id: 'reynolds-number',
      values: {
        'density': '1000',
        'speed': '0',
        'length': '0.05',
        'viscosity': '0.001',
      },
      result: '0',
    ),
    (
      id: 'ideal-gas-law',
      values: {'amount': '1', 'temperature': '300', 'volume': '0.025'},
      result: '99773.551418 Pa',
    ),
    (
      id: 'ipv4-subnet',
      values: {'address': '192.0.2.5', 'prefix': '31'},
      result: '192.0.2.4/31',
    ),
  ];
  for (final dark in [false, true]) {
    for (final sample in cases) {
      testWidgets('${sample.id} full flow on 320px, 200% text, dark=$dark', (
        tester,
      ) async {
        await pumpApp(
          tester,
          location: dark ? '/settings' : '/calculator/${sample.id}',
          size: const Size(320, 568),
          textScale: 2,
        );
        if (dark) {
          final themeSelector = find.byType(DropdownMenu<ThemeMode>);
          await tester.scrollUntilVisible(
            themeSelector,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(themeSelector);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Dark').last);
          await tester.pumpAndSettle();
          GoRouter.of(tester.element(find.text('Appearance')))
              .go('/calculator/${sample.id}');
          await tester.pumpAndSettle();
        }
        for (final entry in sample.values.entries) {
          await enterInput(tester, entry.key, entry.value);
        }
        await pressCalculate(tester);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey('result-value')),
              )
              .data,
          sample.result,
        );
        expect(tester.takeException(), isNull);
        if (dark) {
          expect(
            Theme.of(tester.element(find.byKey(const ValueKey('result-value'))))
                .brightness,
            Brightness.dark,
          );
        }
        await tester.ensureVisible(find.text('Explanation'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Ohm unit selectors change interpretation and resistance target works',
    (tester) async {
      await pumpApp(tester, location: '/calculator/ohms-law');
      await enterInput(tester, 'voltage', '12000');
      await enterInput(tester, 'resistance', '0.006');
      await chooseUnit(tester, 'voltage', 'mV');
      await chooseUnit(tester, 'resistance', 'kΩ');
      await pressCalculate(tester);
      expect(find.text('2 A'), findsOneWidget);
      final target = find.byType(DropdownButtonFormField<CalculatorMode>);
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resistance (R)').last);
      await tester.pumpAndSettle();
      await enterInput(tester, 'voltage', '24');
      await enterInput(tester, 'current', '2');
      await pressCalculate(tester);
      expect(find.text('12 Ω'), findsOneWidget);
    },
  );
  testWidgets('Gas Celsius and litres conversion through real selectors', (
    tester,
  ) async {
    await pumpApp(tester, location: '/calculator/ideal-gas-law');
    await enterInput(tester, 'amount', '1');
    await enterInput(tester, 'temperature', '26.85');
    await enterInput(tester, 'volume', '25');
    await chooseUnit(tester, 'temperature', '°C');
    await chooseUnit(tester, 'volume', 'L');
    await pressCalculate(tester);
    expect(find.text('99773.551418 Pa'), findsOneWidget);
    await enterInput(tester, 'temperature', '-273.15');
    await pressCalculate(tester);
    expect(
      find.textContaining('Absolute temperature must be greater'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('result-value')), findsNothing);
  });
  testWidgets('Gas target menu stays usable with large text', (tester) async {
    await pumpApp(
      tester,
      location: '/calculator/ideal-gas-law',
      size: const Size(320, 568),
      textScale: 2,
    );
    final selector = find.byType(DropdownButtonFormField<CalculatorMode>);
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temperature (T)').last);
    await tester.pumpAndSettle();
    await enterInput(tester, 'pressure', '100000');
    await enterInput(tester, 'volume', '0.02494338785445972');
    await enterInput(tester, 'amount', '1');
    await pressCalculate(tester);
    expect(find.text('300 K'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Calculator form scrolls while small-screen keyboard is visible',
    (tester) async {
      await pumpApp(
        tester,
        location: '/calculator/ohms-law',
        size: const Size(320, 568),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await enterInput(tester, 'voltage', '12');
      await enterInput(tester, 'resistance', '6');
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await pressCalculate(tester);
      expect(find.text('2 A'), findsOneWidget);
    },
  );
}
