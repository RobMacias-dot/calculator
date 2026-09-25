import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show pumpApp;

Future<void> enterInput(WidgetTester tester, String id, String value) async {
  final field = find.byWidgetPredicate(
    (widget) =>
        widget is TextFormField && widget.key.toString().contains('input-$id-'),
  );
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> pressCalculate(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Calculate'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Calculate'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('IPv4 inputs -> Calculate -> subnet, mask and exact counts', (
    tester,
  ) async {
    await pumpApp(tester, location: '/calculator/ipv4-subnet');
    await enterInput(tester, 'address', '192.168.1.10');
    await enterInput(tester, 'prefix', '24');
    await pressCalculate(tester);
    expect(find.text('192.168.1.0/24'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-value')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('255.255.255.0'), findsOneWidget);
    expect(find.text('256'), findsOneWidget);
    expect(find.text('254'), findsOneWidget);
  });
  testWidgets('Ideal gas inputs -> Calculate -> visible pressure', (
    tester,
  ) async {
    await pumpApp(tester, location: '/calculator/ideal-gas-law');
    await enterInput(tester, 'amount', '1');
    await enterInput(tester, 'temperature', '300');
    await enterInput(tester, 'volume', '0.025');
    await pressCalculate(tester);
    expect(find.text('99773.551418 Pa'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-value')).hitTestable(),
      findsOneWidget,
    );
  });
  testWidgets('Reynolds inputs -> Calculate -> visible dimensionless result', (
    tester,
  ) async {
    await pumpApp(tester, location: '/calculator/reynolds-number');
    for (final entry in {
      'density': '1000',
      'speed': '2',
      'length': '0.05',
      'viscosity': '0.001',
    }.entries) {
      await enterInput(tester, entry.key, entry.value);
    }
    await pressCalculate(tester);
    expect(find.text('100000'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-value')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.textContaining('thresholds depend on geometry'),
      findsOneWidget,
    );
  });
  testWidgets('Newton inputs -> Calculate -> visible force', (tester) async {
    await pumpApp(tester, location: '/calculator/newtons-second-law');
    await enterInput(tester, 'mass', '1');
    await enterInput(tester, 'acceleration', '9.80665');
    await pressCalculate(tester);
    expect(find.text('9.80665 N'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-value')).hitTestable(),
      findsOneWidget,
    );
  });
  testWidgets('Ohm inputs -> Calculate -> visible 22 A with substitution', (
    tester,
  ) async {
    await pumpApp(tester, location: '/calculator/ohms-law');
    await enterInput(tester, 'voltage', '220');
    await enterInput(tester, 'resistance', '10');
    await pressCalculate(tester);
    expect(find.text('22 A'), findsOneWidget);
    expect(find.text('I = 220 V / 10 Ω'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-value')).hitTestable(),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('22 A'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is TextFormField &&
                  widget.key.toString().contains('input-voltage-'),
            ),
          )
          .initialValue,
      '',
    );
  });
  testWidgets('Ohm target selection exposes exactly two known values', (
    tester,
  ) async {
    await pumpApp(tester, location: '/calculator/ohms-law');
    await tester.tap(find.byType(DropdownButtonFormField<CalculatorMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltage (V)').last);
    await tester.pumpAndSettle();
    await enterInput(tester, 'current', '2');
    await enterInput(tester, 'resistance', '10');
    await pressCalculate(tester);
    expect(find.text('20 V'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
  testWidgets('Ohm zero resistance is an inline error, never a result', (
    tester,
  ) async {
    await pumpApp(tester, location: '/calculator/ohms-law');
    await enterInput(tester, 'voltage', '12');
    await enterInput(tester, 'resistance', '0');
    await pressCalculate(tester);
    expect(
      find.text('Resistance must be greater than zero to calculate current.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('result-value')), findsNothing);
  });
}
