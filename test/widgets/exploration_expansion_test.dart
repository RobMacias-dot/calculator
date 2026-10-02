import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';
import 'package:engineering_toolkit/features/calculators/presentation/result_card.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_model_view.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'playground_test.dart'
    show
        openPlayground,
        fill,
        edit,
        liveField,
        playgroundVm,
        playgroundSamples,
        expandReasoning,
        expectSynchronized;

// Compare to the normal form coordinator with the same mode, values and units.
// Formula correctness is already established by the domain suite.
void expectOrdinaryResult(WidgetTester tester) {
  final live = playgroundVm(tester);
  final ordinary = CalculatorViewModel(live.definition);
  try {
    ordinary.selectMode(live.mode);
    for (final input in live.inputs) {
      ordinary.setValue(input.id, live.valueFor(input.id));
      final unit = live.unitFor(input.id);
      if (unit != null) ordinary.setUnit(input.id, unit);
    }
    ordinary.calculate();
    expect(live.result!.value, ordinary.result!.value);
    expect(live.result!.formattedValue, ordinary.result!.formattedValue);
    expect(live.result!.substitution, ordinary.result!.substitution);
    expect(live.result!.explanation, ordinary.result!.explanation);
    expectSynchronized(tester);
  } finally {
    ordinary.dispose();
  }
}

void expectWaiting(WidgetTester tester, String staleSubstitution) {
  expect(playgroundVm(tester).result, isNull);
  expect(find.byType(CalculationResultSummary), findsNothing);
  expect(find.byType(CalculationResultDetails), findsNothing);
  expect(find.byType(VisualModelView), findsNothing);
  expect(find.byType(VisualScene), findsNothing);
  expect(find.byTooltip('Copy result'), findsNothing);
  expect(find.text(staleSubstitution), findsNothing);
  expect(find.text('Waiting for valid inputs'), findsOneWidget);
}

Future<void> selectDimension(WidgetTester tester, String label) async {
  final selector = find.byType(DropdownButtonFormField<CalculatorMode>);
  await tester.ensureVisible(selector);
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Newton signed force, units and invalid mass use the form pipeline',
    (tester) async {
      await openPlayground(tester, 'newtons-second-law');
      await fill(tester, {'mass': '2', 'acceleration': '3'});
      await expandReasoning(tester);
      expectOrdinaryResult(tester);
      final vm = playgroundVm(tester);
      final positive =
          tester.widget<VisualModelView>(find.byType(VisualModelView)).model
              as NewtonVisualModel;
      await edit(tester, 'acceleration', '-3');
      expectOrdinaryResult(tester);
      final negative =
          tester.widget<VisualModelView>(find.byType(VisualModelView)).model
              as NewtonVisualModel;
      expect(negative.forceArrow, -positive.forceArrow);
      expect(negative.accelerationArrow, lessThan(0));
      final signedForce = vm.result!.value;
      tester
          .widget<DropdownButtonFormField<EngineeringUnit>>(
            find.byKey(const ValueKey('unit-mass-live')),
          )
          .onChanged!(EngineeringUnit.gram);
      await edit(tester, 'mass', '2000');
      expect(vm.result!.value, signedForce);
      expectOrdinaryResult(tester);
      await tester.ensureVisible(find.text('Engineering context'));
      await tester.tap(find.text('Engineering context'));
      await tester.pumpAndSettle();
      for (final bad in ['-1', '', 'NaN']) {
        final substitution = vm.result!.substitution;
        await edit(tester, 'mass', bad);
        expectWaiting(tester, substitution);
        for (final note in vm.definition.assumptions) {
          expect(find.text(note), findsOneWidget);
        }
        await edit(tester, 'mass', '2000');
      }
      // Existing algebraic zero-mass boundary stays valid, as do large manual inputs.
      for (final mass in ['0', '1e9']) {
        await edit(tester, 'mass', mass);
        expectOrdinaryResult(tester);
      }
    },
  );

  testWidgets(
    'Torque proportional edits, units and magnitude boundaries stay synchronized',
    (tester) async {
      await openPlayground(tester, 'torque');
      await fill(tester, {'force': '10', 'radius': '.5'});
      await expandReasoning(tester);
      expectOrdinaryResult(tester);
      final vm = playgroundVm(tester);
      final initial = vm.result!.value!;
      final geometry =
          tester.widget<VisualModelView>(find.byType(VisualModelView)).model
              as TorqueVisualModel;
      await edit(tester, 'force', '20');
      expect(vm.result!.value, initial * 2);
      expectOrdinaryResult(tester);
      final updated =
          tester.widget<VisualModelView>(find.byType(VisualModelView)).model
              as TorqueVisualModel;
      expect(updated.forceArrow, greaterThan(geometry.forceArrow));
      await edit(tester, 'radius', '1');
      expect(vm.result!.value, initial * 4);
      expectOrdinaryResult(tester);
      tester
          .widget<DropdownButtonFormField<EngineeringUnit>>(
            find.byKey(const ValueKey('unit-radius-live')),
          )
          .onChanged!(EngineeringUnit.centimetre);
      await edit(tester, 'radius', '100');
      expect(vm.result!.value, initial * 4);
      expectOrdinaryResult(tester);
      for (final id in ['force', 'radius']) {
        final substitution = vm.result!.substitution;
        await edit(tester, id, '-1');
        expectWaiting(tester, substitution);
        expect(vm.errorFor(id), isNotNull);
        await edit(tester, id, '0');
        expectOrdinaryResult(tester);
        await edit(tester, id, '20');
      }
      final substitution = vm.result!.substitution;
      await edit(tester, 'radius', '');
      expectWaiting(tester, substitution);
      await edit(tester, 'radius', '100000');
      expectOrdinaryResult(tester);
    },
  );

  testWidgets(
    'Vector 2D/3D resets, signed components and zero-z equivalence use real modes',
    (tester) async {
      await openPlayground(tester, 'vector-magnitude');
      await fill(tester, {'x': '-3', 'y': '4'});
      await expandReasoning(tester);
      expectOrdinaryResult(tester);
      final vm = playgroundVm(tester);
      final planar = vm.result!;
      await selectDimension(tester, '3D vector');
      expectWaiting(tester, planar.substitution);
      expect(liveField('z'), findsOneWidget);
      expect(vm.valueFor('x'), isEmpty);
      await fill(tester, {'x': '-3', 'y': '4', 'z': '0'});
      expect(vm.result!.value, planar.value);
      expectOrdinaryResult(tester);
      await edit(tester, 'z', '-12');
      expectOrdinaryResult(tester);
      final spatial = vm.result!;
      final model =
          tester.widget<VisualModelView>(find.byType(VisualModelView)).model
              as VectorVisualModel;
      expect(model.is3d, isTrue);
      expect(model.inputs.components.last.baseValue, -12);
      await edit(tester, 'z', '1e');
      expectWaiting(tester, spatial.substitution);
      await edit(tester, 'z', '-12');
      await selectDimension(tester, '2D vector');
      expectWaiting(tester, spatial.substitution);
      expect(liveField('z'), findsNothing);
      await fill(tester, {'x': '-3', 'y': '4'});
      expect(vm.result!.value, planar.value);
      expectOrdinaryResult(tester);
      expect(
        (tester.widget<VisualModelView>(find.byType(VisualModelView)).model
                as VectorVisualModel)
            .is3d,
        isFalse,
      );
      await edit(tester, 'x', '');
      expectWaiting(tester, planar.substitution);
      await edit(tester, 'x', '-30000');
      expectOrdinaryResult(tester);
    },
  );

  for (final sample in playgroundSamples.skip(3)) {
    testWidgets(
      '${sample.id} quantity semantics, keyboard and stable reduced-motion presentation',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await openPlayground(tester, sample.id, reduced: false);
          await fill(tester, sample.values);
          final vm = playgroundVm(tester);
          await tester.ensureVisible(find.byType(VisualScene));
          await tester.pumpAndSettle();
          final model = tester
              .widget<VisualModelView>(find.byType(VisualModelView))
              .model;
          expect(find.bySemanticsLabel(model.summary), findsOneWidget);
          expect(model.summary, contains(vm.result!.formattedValue));
          for (final value in sample.values.values) {
            expect(model.summary, contains(value));
          }
          expect(
            find.descendant(
              of: find.byType(VisualScene),
              matching: find.byType(RepaintBoundary),
            ),
            findsOneWidget,
          );
          var notifications = 0;
          vm.addListener(() => notifications++);
          final report = vm.result;
          for (final flags in [
            const FakeAccessibilityFeatures(disableAnimations: true),
            const FakeAccessibilityFeatures(reduceMotion: true),
          ]) {
            tester.platformDispatcher.accessibilityFeaturesTestValue = flags;
            await tester.pumpAndSettle();
            await tester.pump(const Duration(seconds: 1));
            expect(vm.result, same(report));
            expect(notifications, 0);
            expect(tester.binding.transientCallbackCount, 0);
          }
          await tester.ensureVisible(liveField(sample.values.keys.last));
          await tester.tap(liveField(sample.values.keys.last));
          tester.testTextInput.updateEditingValue(
            const TextEditingValue(
              text: '7',
              selection: TextSelection.collapsed(offset: 1),
            ),
          );
          await tester.pump();
          expect(vm.valueFor(sample.values.keys.last), '7');
          // Tab traversal reaches the two disclosures and Enter opens them.
          var reachedContext = false;
          for (var step = 0; step < 12; step++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
            final tile = FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<ExpansionTile>();
            if (tile != null) {
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pumpAndSettle();
              if ((tile.title as Text).data == 'Engineering context') {
                reachedContext = true;
                break;
              }
            }
          }
          expect(reachedContext, isTrue);
          for (final note in vm.definition.assumptions) {
            expect(find.text(note), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          expect(tester.binding.transientCallbackCount, 0);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Vector 3D geometry and context at 200% in ${theme.name}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await openPlayground(
          tester,
          'vector-magnitude',
          theme: theme,
          size: const Size(320, 640),
          textScale: 2,
        );
        await selectDimension(tester, '3D vector');
        await fill(tester, {'x': '-3', 'y': '4', 'z': '-12'});
        await expandReasoning(tester);
        expectOrdinaryResult(tester);
        await tester.ensureVisible(find.byType(VisualScene));
        await tester.pumpAndSettle();
        final model = tester
            .widget<VisualModelView>(find.byType(VisualModelView))
            .model;
        expect(find.bySemanticsLabel(model.summary), findsOneWidget);
        expect(model.summary, contains('z'));
        expect(model.summary, contains('-12'));
        await tester.ensureVisible(find.text('Engineering context'));
        await tester.tap(find.text('Engineering context'));
        await tester.pumpAndSettle();
        final note = playgroundVm(tester).definition.assumptions.single;
        await tester.ensureVisible(find.text(note));
        await tester.pump();
        expect(tester.getRect(find.text(note)).right, lessThanOrEqualTo(320));
        await selectDimension(tester, '2D vector');
        expect(find.text(note), findsNothing);
        expect(playgroundVm(tester).result, isNull);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('Vector mode dropdown supports keyboard selection', (
    tester,
  ) async {
    await openPlayground(tester, 'vector-magnitude');
    final selector = find.byType(DropdownButtonFormField<CalculatorMode>);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(playgroundVm(tester).mode.id, '3d');
    expect(liveField('z'), findsOneWidget);
  });
}
