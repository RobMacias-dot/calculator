import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_tile.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_preferences_repository.dart';
import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  testWidgets(
    'expanded Tools is lazy, searches, filters, opens and favorites new tools',
    (tester) async {
      final registry = createInitialCatalog();
      await pumpApp(tester, registry: registry);
      await tester.tap(find.byTooltip('Tools'));
      await tester.pumpAndSettle();
      expect(find.text('30 tools · Offline catalog'), findsOneWidget);
      expect(
        find.byType(CalculatorTile).evaluate().length,
        lessThan(registry.all.length),
      );
      await tester.enterText(find.byType(TextField), 'quadratic');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Quadratic Equation'));
      await tapVisible(
        tester,
        find.byTooltip('Add Quadratic Equation to favorites'),
      );
      await tester.tap(find.byTooltip('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Quadratic Equation'), findsOneWidget);
      await tester.tap(find.byTooltip('Tools'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byType(DropdownButtonFormField<CalculatorCategory?>),
      );
      await tester.tap(find.text('Mathematics').last);
      await tester.pumpAndSettle();
      expect(find.text('4 tools · Offline catalog'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Quadratic Equation'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Remove Quadratic Equation from favorites'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'dynamic resistance form retains entries, validates inline, resets and copies',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard =
                (call.arguments as Map<dynamic, dynamic>)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/series-resistance',
      );
      await enterInput(tester, 'r1', '10');
      await enterInput(tester, 'r2', '20');
      await tapVisible(tester, find.text('Add resistor'));
      await pressCalculate(tester);
      expect(find.text('Enter a value.'), findsOneWidget);
      await enterInput(tester, 'r3', '30');
      await pressCalculate(tester);
      expect(find.text('60 Ω'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Copy result'));
      expect(clipboard, contains('R = 10 Ω + 20 Ω + 30 Ω'));
      await tapVisible(tester, find.text('Remove last resistor'));
      await pressCalculate(tester);
      expect(find.text('30 Ω'), findsOneWidget);
      await tapVisible(tester, find.text('Reset'));
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('30 Ω'), findsNothing);
    },
  );

  testWidgets(
    'new mode selector solves DC voltage with existing input components',
    (tester) async {
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/dc-power',
      );
      await tapVisible(
        tester,
        find.byType(DropdownButtonFormField<CalculatorMode>),
      );
      await tester.tap(find.text('Voltage (V)').last);
      await tester.pumpAndSettle();
      await enterInput(tester, 'power', '24');
      await enterInput(tester, 'current', '2');
      await pressCalculate(tester);
      expect(find.text('12 V'), findsOneWidget);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final sample in [
      (
        id: 'parallel-resistance',
        values: {'r1': '100', 'r2': '100'},
        expected: '50 Ω',
      ),
      (
        id: 'quadratic-equation',
        values: {'a': '1', 'b': '0', 'c': '1'},
        expected: 'x1 = 0 + 1i\nx2 = 0 − 1i',
      ),
      (
        id: 'bernoulli-basic',
        values: {
          'pressure1': '100000',
          'density': '1000',
          'speed1': '2',
          'speed2': '4',
          'height1': '3',
          'height2': '1',
        },
        expected: '113613.3 Pa',
      ),
      (
        id: 'sensible-heat',
        values: {
          'mass': '2',
          'specificHeat': '4186',
          'temperatureChange': '10',
        },
        expected: '83720 J',
      ),
      (
        id: 'ipv4-representation',
        values: {'address': '192.168.1.10'},
        expected: '11000000.10101000.00000001.00001010',
      ),
    ]) {
      testWidgets(
        '${sample.id} result and assumptions at 320px / 200% / ${mode.name}',
        (tester) async {
          final registry = createInitialCatalog();
          final preferences = await PreferencesController.restore(
            MemoryPreferencesRepository(Preferences(themeMode: mode)),
            registry,
          );
          await pumpApp(
            tester,
            registry: registry,
            preferences: preferences,
            location: '/calculator/${sample.id}',
            size: const Size(320, 568),
            textScale: 2,
          );
          if (registry.byId(sample.id)!.assumptions.isNotEmpty) {
            expect(find.text('Engineering context'), findsOneWidget);
          }
          expect(find.text('Unit: '), findsNothing);
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
            sample.expected,
          );
          await tapVisible(tester, find.byTooltip('Copy result'));
          expect(find.text('Result copied'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'dynamic controls have labeled touch targets and work with keyboard',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          registry: createInitialCatalog(),
          location: '/calculator/parallel-resistance',
        );
        await tapVisible(tester, find.text('Add resistor'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await enterInput(tester, 'r3', '100');
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Add resistor'));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        semantics.dispose();
      }
    },
  );
}
