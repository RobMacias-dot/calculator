import 'package:engineering_toolkit/features/calculators/domain/calculator_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:engineering_toolkit/features/calculators/domain/definitions/ideal_gas_definition.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/ideal_gas_law.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/ideal_gas_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/reynolds_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/visual_learning_samples.dart';
import '../visual_learning/ideal_gas_visual_test.dart' show gasValues;
import 'visual_learning_test.dart' show openVisual;

IdealGasPainter gasPainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.byKey(const ValueKey('ideal-gas-canvas')))
            .painter!
        as IdealGasPainter;
CalculatorViewModel gasVm(WidgetTester tester) => tester
    .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
    .viewModel;

Future<void> host(WidgetTester tester, CalculatorViewModel vm) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: VisualLearningSheet(viewModel: vm)),
    ),
  );
  await tester.pump();
}

const gasPressureInputs = {
  'volume': '.025',
  'amount': '1',
  'temperature': '300',
};

void main() {
  for (final gas in [true, false]) {
    testWidgets(
      'platform disableAnimations overrides local MediaQuery false gas=$gas',
      (tester) async {
        final vm = gas
            ? visualVm('ideal-gas-law', gasValues)
            : visualVm(visualSamples[2].id, visualSamples[2].values);
        addTearDown(vm.dispose);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: false),
              child: Scaffold(body: VisualLearningSheet(viewModel: vm)),
            ),
          ),
        );
        final Animation<double> phase = gas
            ? gasPainter(tester).phase
            : (tester
                          .widget<CustomPaint>(
                            find.byKey(const ValueKey('reynolds-canvas')),
                          )
                          .painter!
                      as ReynoldsPainter)
                  .phase;
        await tester.pump(const Duration(milliseconds: 400));
        expect(phase.value, 0);
        expect(find.textContaining('Reduce Motion is on'), findsOneWidget);
      },
    );
  }
  for (final variable in GasVariable.values) {
    testWidgets(
      '${variable.name}: only three inputs drive existing engine and labels',
      (tester) async {
        final vm = visualVm('ideal-gas-law', gasValues, mode: variable.name);
        addTearDown(vm.dispose);
        await host(tester, vm);
        expect(find.byType(Slider), findsNWidgets(3));
        expect(
          find.byKey(ValueKey('visual-control-${variable.name}')),
          findsNothing,
        );
        for (final input in vm.inputs.take(2)) {
          final slider = tester.widget<Slider>(
            find.byKey(ValueKey('visual-control-${input.id}')),
          );
          final old = vm.result;
          slider.onChanged!((slider.min + slider.max) / 2);
          await tester.pump();
          expect(vm.result, isNot(same(old)));
          expect(vm.result!.formula, vm.mode.formula);
          final model = tester
              .widget<IdealGasVisual>(find.byType(IdealGasVisual))
              .model;
          expect(model.report, same(vm.result));
          expect(model.values[variable], vm.result!.value);
          expect(
            find.textContaining('${model.label(variable)} (calculated)'),
            findsOneWidget,
          );
          expect(gasPainter(tester).chamberFraction, model.chamberFraction);
          expect(gasPainter(tester).particleCount, model.particleCount);
        }
        vm.selectMode(
          vm.definition.modes.firstWhere((m) => m.id != variable.name),
        );
        await tester.pump();
        expect(find.byType(IdealGasVisual), findsNothing);
        expect(
          find.textContaining('Calculate with valid inputs'),
          findsOneWidget,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  }

  testWidgets(
    'gas controls preserve Celsius and litres, keyboard and form substitution',
    (tester) async {
      await openVisual(
        tester,
        'ideal-gas-law',
        gasPressureInputs,
        reduced: true,
      );
      final vm = gasVm(tester);
      vm.setUnit('temperature', EngineeringUnit.celsius);
      vm.setValue('temperature', '26.85');
      vm.setUnit('volume', EngineeringUnit.litre);
      vm.updateAndCalculate('volume', '25');
      await tester.pump();
      tester
          .widget<Slider>(
            find.byKey(const ValueKey('visual-control-temperature')),
          )
          .onChanged!(400);
      await tester.pump();
      expect(double.parse(vm.valueFor('temperature')), closeTo(126.85, 1e-10));
      expect(vm.result!.substitution, contains('400 K'));
      tester
          .widget<Slider>(find.byKey(const ValueKey('visual-control-volume')))
          .onChanged!(.05);
      await tester.pump();
      expect(vm.valueFor('volume'), '50.0');
      expect(vm.result!.substitution, contains('0.05 m³'));
      final input = find.byKey(const ValueKey('visual-control-amount'));
      await tester.ensureVisible(input);
      await tester.pump();
      final before = vm.valueFor('amount');
      for (var i = 0; i < 10 && vm.valueFor('amount') == before; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      expect(vm.valueFor('amount'), isNot(before));
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
      final field = find.byWidgetPredicate(
        (w) => w is TextFormField && w.key.toString().contains('input-volume-'),
      );
      expect(
        tester.widget<TextFormField>(field).initialValue,
        vm.valueFor('volume'),
      );
    },
  );

  testWidgets(
    'gas manual extremes retained; invalid and empty remove animated scene',
    (tester) async {
      final vm = visualVm('ideal-gas-law', {...gasValues, 'volume': '1e100'});
      addTearDown(vm.dispose);
      await host(tester, vm);
      final report = vm.result;
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('visual-control-volume')),
      );
      expect(slider.value, slider.max);
      expect(vm.valueFor('volume'), '1e100');
      expect(vm.result, same(report));
      vm.updateAndCalculate('volume', '0');
      await tester.pump();
      expect(find.byType(VisualScene), findsNothing);
      expect(find.text('Return to inputs'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      vm.reset();
      await tester.pump();
      expect(
        find.textContaining('Calculate with valid inputs'),
        findsOneWidget,
      );
    },
  );

  testWidgets('gas ticks repaint only, keep seeds, never calculate or notify', (
    tester,
  ) async {
    final definition = createIdealGasDefinition();
    final mode = definition.modes.first;
    var calculations = 0;
    final vm = CalculatorViewModel(
      CalculatorDefinition(
        id: definition.id,
        name: definition.name,
        description: definition.description,
        category: definition.category,
        formula: definition.formula,
        explanation: definition.explanation,
        inputs: definition.inputs,
        modes: [
          CalculatorMode(
            id: mode.id,
            label: mode.label,
            formula: mode.formula,
            inputs: mode.inputs,
            calculate: (values, units) {
              calculations++;
              return mode.calculate(values, units);
            },
          ),
        ],
      ),
    );
    addTearDown(vm.dispose);
    for (final entry in gasValues.entries) {
      vm.setValue(entry.key, entry.value);
    }
    vm.calculate();
    var notifications = 0;
    vm.addListener(() => notifications++);
    await host(tester, vm);
    final painter = gasPainter(tester);
    final seeds = IdealGasParticles.seeds;
    final report = vm.result;
    final labels = tester.widget(find.textContaining('P · pressure:'));
    final phase = painter.phase.value;
    await tester.pump(const Duration(milliseconds: 700));
    expect(painter.phase.value, isNot(phase));
    expect(gasPainter(tester), same(painter));
    expect(tester.widget(find.textContaining('P · pressure:')), same(labels));
    expect(IdealGasParticles.seeds, same(seeds));
    expect(vm.result, same(report));
    expect(calculations, 1);
    expect(notifications, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gas pause persists across app lifecycle and resumes explicitly',
    (tester) async {
      await openVisual(
        tester,
        'ideal-gas-law',
        gasPressureInputs,
        size: const Size(600, 1200),
      );
      final clock = gasPainter(tester).phase;
      await tester.ensureVisible(find.text('Pause particles'));
      await tester.pump();
      await tester.tap(find.text('Pause particles'));
      await tester.pump();
      final stopped = clock.value;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(clock.value, stopped);
      await tester.tap(find.text('Play particles'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(clock.value, isNot(stopped));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      final background = clock.value;
      await tester.pump(const Duration(seconds: 1));
      expect(clock.value, background);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(clock.value, isNot(background));
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'gas stops off viewport and across repeated close reopen rotate',
    (tester) async {
      await openVisual(
        tester,
        'ideal-gas-law',
        gasPressureInputs,
        size: const Size(320, 640),
      );
      final clock = gasPainter(tester).phase;
      await tester.ensureVisible(find.byType(Slider).last);
      await tester.pump();
      final stopped = clock.value;
      await tester.pump(const Duration(seconds: 1));
      expect(clock.value, stopped);
      await tester.ensureVisible(
        find.byKey(const ValueKey('ideal-gas-canvas')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));
      expect(clock.value, isNot(stopped));
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byTooltip('Close visualization'));
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
        await tester.ensureVisible(find.text('Learn visually'));
        await tester.tap(find.text('Learn visually'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(IdealGasVisual), findsOneWidget);
        tester.view.physicalSize = i == 0
            ? const Size(640, 320)
            : const Size(320, 640);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('gas honors route TickerMode', (tester) async {
    final vm = visualVm('ideal-gas-law', gasValues);
    final visible = ValueNotifier(true);
    addTearDown(vm.dispose);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, enabled, _) => TickerMode(
              enabled: enabled,
              child: VisualLearningSheet(viewModel: vm),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final clock = gasPainter(tester).phase;
    visible.value = false;
    await tester.pump();
    final stopped = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, stopped);
    visible.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(clock.value, isNot(stopped));
  });

  testWidgets(
    'gas both motion flags stop ticks but preserve and update educational state',
    (tester) async {
      await openVisual(tester, 'ideal-gas-law', gasPressureInputs);
      final vm = gasVm(tester);
      final clock = gasPainter(tester).phase;
      for (final flags in [
        const FakeAccessibilityFeatures(disableAnimations: true),
        const FakeAccessibilityFeatures(reduceMotion: true),
      ]) {
        tester.platformDispatcher.accessibilityFeaturesTestValue = flags;
        await tester.pump();
        final stopped = clock.value;
        final report = vm.result;
        await tester.pump(const Duration(seconds: 1));
        expect(clock.value, stopped);
        expect(vm.result, same(report));
        expect(find.textContaining('Reduce Motion is on'), findsOneWidget);
        expect(find.byType(Slider), findsNWidgets(3));
        expect(find.textContaining('Temperature motion cue:'), findsOneWidget);
        tester
            .widget<Slider>(
              find.byKey(const ValueKey('visual-control-temperature')),
            )
            .onChanged!(600);
        await tester.pump();
        expect(clock.value, stopped);
        expect(find.textContaining('T · temperature: 600 K'), findsOneWidget);
      }
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      final before = clock.value;
      await tester.pump(const Duration(milliseconds: 200));
      expect(clock.value, isNot(before));
    },
  );

  testWidgets(
    'gas inherited reduce motion survives platform accessibility changes',
    (tester) async {
      final vm = visualVm('ideal-gas-law', gasValues);
      addTearDown(vm.dispose);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(body: VisualLearningSheet(viewModel: vm)),
          ),
        ),
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(boldText: true);
      await tester.pump();
      final clock = gasPainter(tester).phase;
      await tester.pump(const Duration(seconds: 1));
      expect(clock.value, 0);
      expect(find.textContaining('Reduce Motion is on'), findsOneWidget);
    },
  );

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('gas ${theme.name} 200% text semantics controls and contrast', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await openVisual(
          tester,
          'ideal-gas-law',
          gasPressureInputs,
          theme: theme,
          textScale: 2,
          size: const Size(320, 640),
          reduced: true,
        );
        expect(
          find.bySemanticsLabel(RegExp('Ideal gas visualization.')),
          findsOneWidget,
        );
        final summary = tester
            .widget<VisualScene>(find.byType(VisualScene))
            .summary;
        expect(summary, contains('Calculated pressure'));
        for (final variable in GasVariable.values) {
          await tester.ensureVisible(
            find.textContaining(RegExp('^[PVnT] · ${variable.name}:')),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        for (final slider in find.byType(Slider).evaluate().toList()) {
          await tester.ensureVisible(find.byWidget(slider.widget));
          await tester.pump();
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          expect(tester.takeException(), isNull);
        }
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pump();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
