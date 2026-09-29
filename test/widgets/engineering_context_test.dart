import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_scene.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/memory_preferences_repository.dart';
import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;
import 'content_expansion_test.dart' show tapVisible;

Future<void> selectMode(WidgetTester tester, String label) async {
  await tapVisible(
    tester,
    find.byType(DropdownButtonFormField<CalculatorMode>),
  );
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  test('static notes are immutable and shared models need no mode copies', () {
    final registry = createInitialCatalog();
    final gas = registry.byId('ideal-gas-law')!;
    expect(gas.assumptions.join(' '), contains('absolute, not gauge'));
    expect(gas.modes.every((m) => m.assumptions.isEmpty), isTrue);
    expect(() => gas.assumptions.add('changed'), throwsUnsupportedError);
    final change = registry.byId('percentage')!.modes[1];
    expect(() => change.assumptions.clear(), throwsUnsupportedError);
    final source = ['original'];
    final mode = CalculatorMode(
      id: change.id,
      label: change.label,
      formula: change.formula,
      inputs: change.inputs,
      calculate: change.calculate,
      assumptions: source,
    );
    source.clear();
    expect(mode.assumptions, ['original']);
  });

  testWidgets(
    'omitted context has no empty shell, including both conversions',
    (tester) async {
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/ipv4-representation',
      );
      expect(find.text('Engineering context'), findsNothing);
      await selectMode(tester, 'Binary to decimal');
      expect(find.byType(ExpansionTile), findsNothing);
      GoRouter.of(tester.element(find.text('Inputs')))
          .go('/calculator/subnet-mask');
      await tester.pumpAndSettle();
      await selectMode(tester, 'CIDR to mask');
      expect(find.byType(ExpansionTile), findsNothing);
    },
  );

  testWidgets(
    'mode-specific context replaces old notes and disappears for of',
    (tester) async {
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/percentage',
      );
      expect(find.text('Engineering context'), findsNothing);
      await selectMode(tester, 'Percentage change');
      expect(find.textContaining('negative starting value'), findsNothing);
      await tapVisible(tester, find.text('Engineering context'));
      expect(find.textContaining('negative starting value'), findsOneWidget);
      await selectMode(tester, 'X is what % of Y');
      expect(find.textContaining('negative starting value'), findsNothing);
      await tapVisible(tester, find.text('Engineering context'));
      expect(find.textContaining('nonzero reference'), findsOneWidget);
      await selectMode(tester, 'X% of Y');
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.textContaining('nonzero reference'), findsNothing);
    },
  );

  testWidgets('shared gas context stays current across all four solve modes', (
    tester,
  ) async {
    final registry = createInitialCatalog();
    final gas = registry.byId('ideal-gas-law')!;
    await pumpApp(
      tester,
      registry: registry,
      location: '/calculator/ideal-gas-law',
    );
    for (final mode in gas.modes) {
      if (mode != gas.modes.first) await selectMode(tester, mode.label);
      await tapVisible(tester, find.text('Engineering context'));
      for (final note in gas.assumptions) {
        expect(find.text(note), findsOneWidget);
      }
      expect(find.text(mode.formula), findsOneWidget);
      expect(find.byTooltip('Copy result'), findsNothing);
    }
  });

  testWidgets(
    'invalid input clears report and scene while expanded context remains',
    (tester) async {
      final registry = createInitialCatalog();
      final divider = registry.byId('voltage-divider')!;
      await pumpApp(
        tester,
        registry: registry,
        location: '/calculator/voltage-divider',
      );
      await tapVisible(tester, find.text('Engineering context'));
      for (final entry in {
        'voltage': '12',
        'r1': '1000',
        'r2': '1000',
      }.entries) {
        await enterInput(tester, entry.key, entry.value);
      }
      await pressCalculate(tester);
      expect(find.text('6 V'), findsOneWidget);
      expect(find.text('Substitution'), findsOneWidget);
      await tapVisible(tester, find.text('Learn visually'));
      final vm = tester
          .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
          .viewModel;
      expect(find.byType(VisualScene), findsOneWidget);
      vm.setValue('r1', '');
      vm.calculate();
      await tester.pumpAndSettle();
      expect(find.byType(VisualScene), findsNothing);
      expect(find.text('Return to inputs'), findsOneWidget);
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('result-value')), findsNothing);
      expect(find.text('Substitution'), findsNothing);
      expect(find.byTooltip('Copy result'), findsNothing);
      expect(find.text('Enter a value.'), findsOneWidget);
      expect(
        find.text('Calculate with valid inputs to explore visually.'),
        findsOneWidget,
      );
      for (final note in divider.assumptions) {
        expect(find.text(note), findsOneWidget);
      }
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Learn visually'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Vout = Vin × R2 / (R1 + R2)'), findsOneWidget);
    },
  );

  testWidgets(
    'disclosure has semantic action/state, touch targets and keyboard access',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          registry: createInitialCatalog(),
          location: '/calculator/ohms-law',
        );
        final title = find.text('Engineering context');
        await tester.ensureVisible(title);
        await tester.pumpAndSettle();
        final collapsed = tester.getSemantics(title).toStringDeep();
        expect(collapsed, contains('tap'));
        expect(collapsed, contains('Collapsed'));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        // Start immediately before the disclosure in the form's traversal order.
        await tapVisible(tester, find.text('Reset'));
        FocusManager.instance.primaryFocus?.unfocus();
        var reached = false;
        for (var step = 0; step < 30; step++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          final focusContext = FocusManager.instance.primaryFocus?.context;
          if (focusContext?.findAncestorWidgetOfExactType<ExpansionTile>() !=
              null) {
            reached = true;
            break;
          }
        }
        expect(reached, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.textContaining('Models an ohmic element'), findsOneWidget);
        expect(tester.getSemantics(title).toStringDeep(), contains('Expanded'));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(find.textContaining('Models an ohmic element'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('long context at 320px and 200% in ${themeMode.name}', (
      tester,
    ) async {
      final registry = createInitialCatalog();
      final preferences = await PreferencesController.restore(
        MemoryPreferencesRepository(Preferences(themeMode: themeMode)),
        registry,
      );
      await pumpApp(
        tester,
        registry: registry,
        preferences: preferences,
        location: '/calculator/bernoulli-basic',
        size: const Size(320, 568),
        textScale: 2,
      );
      await tapVisible(tester, find.text('Engineering context'));
      for (final note in registry.byId('bernoulli-basic')!.assumptions) {
        await tester.ensureVisible(find.text(note));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.text(note));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
      expect(
        Theme.of(tester.element(find.text('Engineering context'))).brightness,
        themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      );
    });
  }

  testWidgets(
    'disclosure introduces no animation with either reduced motion flag',
    (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/linear-expansion',
      );
      for (final flags in [
        const FakeAccessibilityFeatures(disableAnimations: true),
        const FakeAccessibilityFeatures(reduceMotion: true),
      ]) {
        tester.platformDispatcher.accessibilityFeaturesTestValue = flags;
        await tester.pump();
        await tapVisible(tester, find.text('Engineering context'));
        expect(
          tester
              .widget<ExpansionTile>(find.byType(ExpansionTile))
              .expansionAnimationStyle,
          AnimationStyle.noAnimation,
        );
        expect(find.textContaining('restraint stresses'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        await tapVisible(tester, find.text('Engineering context'));
      }
    },
  );
}
