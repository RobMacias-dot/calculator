import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/visual_learning_samples.dart';
import 'visual_learning_test.dart' show openVisual;

void main() {
  for (final sample in visualSamples.skip(4)) {
    testWidgets(
      '${sample.id}: controls use engine, keyboard, invalid and empty states',
      (tester) async {
        await openVisual(tester, sample.id, sample.values);
        final vm = tester
            .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
            .viewModel;
        expect(find.byType(Slider), findsNWidgets(sample.values.length));
        final field = sample.values.keys.first;
        final slider = find.byKey(ValueKey('visual-control-$field'));
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        final before = vm.result;
        tester.widget<Slider>(slider).onChanged!(10);
        await tester.pumpAndSettle();
        expect(vm.valueFor(field), '10.0');
        expect(vm.result, isNot(same(before)));
        final keyboardBefore = vm.valueFor(field);
        for (
          var step = 0;
          step < 10 && vm.valueFor(field) == keyboardBefore;
          step++
        ) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();
        }
        expect(vm.valueFor(field), isNot(keyboardBefore));
        vm.updateAndCalculate(field, 'not a number');
        await tester.pump();
        expect(find.byType(VisualScene), findsNothing);
        expect(find.text('Return to inputs'), findsOneWidget);
        expect(vm.issues, isNotEmpty);
        vm.reset();
        await tester.pump();
        expect(
          find.text(
            'Calculate with valid inputs in the main form to continue.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${sample.id}: static scenes preserve information for both motion settings',
      (tester) async {
        final vm = visualVm(sample.id, sample.values);
        addTearDown(vm.dispose);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: VisualLearningSheet(viewModel: vm)),
          ),
        );
        await tester.pumpAndSettle();
        final summary = tester
            .widget<VisualScene>(find.byType(VisualScene))
            .summary;
        final report = vm.result;
        for (final flags in [
          const FakeAccessibilityFeatures(disableAnimations: true),
          const FakeAccessibilityFeatures(reduceMotion: true),
          const FakeAccessibilityFeatures(),
        ]) {
          tester.platformDispatcher.accessibilityFeaturesTestValue = flags;
          await tester.pumpAndSettle();
          expect(
            tester.widget<VisualScene>(find.byType(VisualScene)).summary,
            summary,
          );
          expect(vm.result, same(report));
          expect(tester.binding.transientCallbackCount, 0);
        }
      },
    );

    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        '${sample.id}: accessible control targets and contrast ${theme.name}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await openVisual(
              tester,
              sample.id,
              sample.values,
              theme: theme,
              reduced: true,
            );
            await tester.ensureVisible(find.byType(Slider).first);
            await tester.pumpAndSettle();
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'new controls preserve selected units and out of range manual values',
    (tester) async {
      for (final item in [
        (
          index: 4,
          field: 'mass',
          unit: EngineeringUnit.gram,
          base: 2.0,
          raw: '2000.0',
        ),
        (
          index: 5,
          field: 'radius',
          unit: EngineeringUnit.centimetre,
          base: 2.0,
          raw: '200.0',
        ),
        (
          index: 6,
          field: 'pressure1',
          unit: EngineeringUnit.kilopascal,
          base: 200000.0,
          raw: '200.0',
        ),
      ]) {
        final sample = visualSamples[item.index];
        await openVisual(tester, sample.id, sample.values, reduced: true);
        final vm = tester
            .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
            .viewModel;
        vm.setUnit(item.field, item.unit);
        vm.updateAndCalculate(item.field, '1000000');
        await tester.pump();
        final slider = tester.widget<Slider>(
          find.byKey(ValueKey('visual-control-${item.field}')),
        );
        expect(slider.value, slider.max);
        expect(vm.valueFor(item.field), '1000000');
        slider.onChanged!(item.base);
        await tester.pump();
        expect(vm.valueFor(item.field), item.raw);
        expect(vm.unitFor(item.field), item.unit);
        await tester.tap(find.byTooltip('Close visualization'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'seven scenes survive repeated opening, rotation and navigation',
    (tester) async {
      for (final sample in visualSamples) {
        await openVisual(tester, sample.id, sample.values, reduced: true);
        for (var repeat = 0; repeat < 2; repeat++) {
          tester.view.physicalSize = const Size(932, 430);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          tester.view.physicalSize = const Size(430, 932);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Close visualization'));
          await tester.pumpAndSettle();
          expect(tester.binding.transientCallbackCount, 0);
          if (repeat == 0) {
            await tester.ensureVisible(find.text('Learn visually'));
            await tester.tap(find.text('Learn visually'));
            await tester.pumpAndSettle();
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
