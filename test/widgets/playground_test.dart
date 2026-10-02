import 'package:engineering_toolkit/features/calculators/domain/calculator_mode.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_input_field.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_view_model.dart';
import 'package:engineering_toolkit/features/calculators/presentation/playground_screen.dart';
import 'package:engineering_toolkit/features/calculators/presentation/result_card.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/ideal_gas_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_model_view.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_preferences_repository.dart';
import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput;

const playgroundSamples = [
  (
    id: 'voltage-divider',
    values: {'voltage': '12', 'r1': '1000', 'r2': '2000'},
  ),
  (id: 'ipv4-subnet', values: {'address': '192.168.1.10', 'prefix': '24'}),
  (
    id: 'ideal-gas-law',
    values: {'amount': '1', 'temperature': '300', 'volume': '.025'},
  ),
  (id: 'newtons-second-law', values: {'mass': '2', 'acceleration': '-3'}),
  (id: 'torque', values: {'force': '10', 'radius': '.5'}),
  (id: 'vector-magnitude', values: {'x': '-3', 'y': '4'}),
];

CalculatorViewModel playgroundVm(WidgetTester tester) =>
    tester.widget<PlaygroundContent>(find.byType(PlaygroundContent)).viewModel;
Finder liveField(String id) => find.byKey(ValueKey('input-$id-live'));

Future<void> edit(WidgetTester tester, String id, String value) async {
  await tester.ensureVisible(liveField(id));
  await tester.pump();
  await tester.enterText(liveField(id), value);
  await tester.pump();
}

Future<void> openPlayground(
  WidgetTester tester,
  String id, {
  bool reduced = true,
  Size size = const Size(430, 932),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final registry = createInitialCatalog();
  final preferences = await PreferencesController.restore(
    MemoryPreferencesRepository(Preferences(themeMode: theme)),
    registry,
  );
  await pumpApp(
    tester,
    registry: registry,
    preferences: preferences,
    location: '/playground/$id',
    size: size,
    textScale: textScale,
  );
}

Future<void> fill(WidgetTester tester, Map<String, String> values) async {
  for (final entry in values.entries) {
    await edit(tester, entry.key, entry.value);
  }
  tester.testTextInput.hide();
  await tester.pump();
}

Future<void> expandReasoning(WidgetTester tester) async {
  final tile = find.text('How it is calculated');
  await tester.ensureVisible(tile);
  await tester.pump();
  await tester.tap(tile);
  await tester.pump();
}

void expectSynchronized(WidgetTester tester) {
  final vm = playgroundVm(tester);
  final report = vm.result!;
  expect(
    tester
        .widget<CalculationResultSummary>(find.byType(CalculationResultSummary))
        .result,
    same(report),
  );
  expect(
    tester.widget<VisualModelView>(find.byType(VisualModelView)).model.report,
    same(report),
  );
  expect(
    tester
        .widget<CalculationResultDetails>(find.byType(CalculationResultDetails))
        .result,
    same(report),
  );
  expect(report.formula, vm.mode.formula);
  expect(find.text(report.formula), findsWidgets);
  expect(find.text(report.substitution), findsOneWidget);
  expect(find.text(report.explanation), findsWidgets);
  expect(find.byType(Slider), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  test(
    'registry alone enables exactly six Playgrounds and preserves catalog',
    () {
      final registry = createInitialCatalog();
      expect(registry.all.length, 30);
      expect(registry.all.expand((d) => d.modes).length, 44);
      expect(registry.all.map((d) => d.category).toSet().length, 6);
      expect(registry.all.where((d) => d.supportsVisualLearning).length, 8);
      expect(
        registry.all.where((d) => d.supportsPlayground).map((d) => d.id),
        unorderedEquals(playgroundSamples.map((s) => s.id)),
      );
      expect(
        registry.all
            .where((d) => d.supportsPlayground)
            .every((d) => d.supportsVisualLearning && d.isAvailable),
        isTrue,
      );
    },
  );

  for (final id in ['ohms-law', 'reynolds-number', 'not-a-calculator']) {
    testWidgets('$id direct Playground is unavailable', (tester) async {
      await openPlayground(tester, id);
      expect(find.text('Page not found'), findsOneWidget);
      expect(find.byType(PlaygroundContent), findsNothing);
      if (id != 'not-a-calculator') {
        await pumpApp(
          tester,
          registry: createInitialCatalog(),
          location: '/calculator/$id',
        );
        expect(find.text('Explore interactively'), findsNothing);
      }
    });
  }

  for (final sample in playgroundSamples) {
    testWidgets(
      '${sample.id} shares one VM, preserves edits on back/reopen and Learn visually',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpApp(
          tester,
          registry: createInitialCatalog(),
          location: '/calculator/${sample.id}',
        );
        final vm = tester
            .widget<CalculatorInputField>(
              find.byType(CalculatorInputField).first,
            )
            .viewModel;
        for (final entry in sample.values.entries) {
          await enterInput(tester, entry.key, entry.value);
        }
        await tester.ensureVisible(find.text('Explore interactively'));
        await tester.pump();
        await tester.tap(find.text('Explore interactively'));
        await tester.pumpAndSettle();
        expect(playgroundVm(tester), same(vm));
        expect(
          tester
              .widget<PlaygroundScreen>(find.byType(PlaygroundScreen))
              .viewModel,
          same(vm),
        );
        expect(
          vm.result,
          isNotNull,
        ); // Entry also calculates previously unsubmitted text.
        final id = sample.values.keys.last;
        final newValue = sample.id == 'ipv4-subnet'
            ? '25'
            : sample.id == 'ideal-gas-law'
            ? '.05'
            : '3000';
        await edit(tester, id, newValue);
        final result = vm.result;
        await tester.ensureVisible(find.byTooltip('Back to calculator'));
        await tester.tap(find.byTooltip('Back to calculator'));
        await tester.pumpAndSettle();
        expect(vm.result, same(result));
        expect(
          tester
              .widget<CalculatorInputField>(
                find.byType(CalculatorInputField).first,
              )
              .viewModel,
          same(vm),
        );
        final field = find.byWidgetPredicate(
          (w) => w is TextFormField && w.key.toString().contains('input-$id-'),
        );
        expect(tester.widget<TextFormField>(field).initialValue, newValue);
        await tester.ensureVisible(find.text('Learn visually'));
        await tester.tap(find.text('Learn visually'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
              .viewModel,
          same(vm),
        );
        expect(
          find.byType(Slider),
          findsWidgets,
        ); // Original entry retains its controls.
        await tester.tap(find.byTooltip('Close visualization'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Explore interactively'));
        await tester.tap(find.text('Explore interactively'));
        await tester.pumpAndSettle();
        expect(playgroundVm(tester), same(vm));
        expect(vm.result, same(result));
        expect(find.bySemanticsLabel('Home').hitTestable(), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(PlaygroundScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${sample.id} direct route has local lifetime and proper fallback back',
      (tester) async {
        await openPlayground(tester, sample.id);
        expect(
          tester
              .widget<PlaygroundScreen>(find.byType(PlaygroundScreen))
              .viewModel,
          isNull,
        );
        await fill(tester, sample.values);
        await tester.ensureVisible(find.byTooltip('Back to calculator'));
        await tester.tap(find.byTooltip('Back to calculator'));
        await tester.pumpAndSettle();
        expect(find.byType(PlaygroundScreen), findsNothing);
        expect(find.text('Explore interactively'), findsOneWidget);
        final vm = tester
            .widget<CalculatorInputField>(
              find.byType(CalculatorInputField).first,
            )
            .viewModel;
        expect(vm.result, isNull); // Direct link had no owning normal form.
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  }

  testWidgets(
    'divider rapid edits, extremes, units, intermediate text and recovery stay synchronized',
    (tester) async {
      await openPlayground(tester, 'voltage-divider');
      await fill(tester, playgroundSamples[0].values);
      final vm = playgroundVm(tester);
      expect(vm.result!.value, 8);
      await expandReasoning(tester);
      expectSynchronized(tester);
      var notifications = 0;
      vm.addListener(() => notifications++);
      for (var i = 1; i <= 20; i++) {
        tester.widget<TextFormField>(liveField('voltage')).onChanged!('$i');
      }
      await tester.pump();
      expect(notifications, 20);
      expect(vm.valueFor('voltage'), '20');
      expectSynchronized(tester);
      await edit(tester, 'r1', '1e250');
      await edit(tester, 'r2', '1e-40');
      expect(vm.result, isNotNull);
      expectSynchronized(tester);
      for (final text in ['', '-', '.', '1e', 'NaN']) {
        await edit(tester, 'voltage', text);
        expect(vm.result, isNull);
        expect(find.byType(VisualModelView), findsNothing);
        expect(find.byType(CalculationResultSummary), findsNothing);
        expect(find.text('Waiting for valid inputs'), findsOneWidget);
        expect(vm.errorFor('voltage'), isNotNull);
      }
      await fill(tester, playgroundSamples[0].values);
      tester
          .widget<DropdownButtonFormField<EngineeringUnit>>(
            find.byKey(const ValueKey('unit-r1-live')),
          )
          .onChanged!(EngineeringUnit.kiloohm);
      await edit(tester, 'r1', '1');
      expect(vm.unitFor('r1'), EngineeringUnit.kiloohm);
      expect(vm.result!.value, 8);
      expectSynchronized(tester);
    },
  );

  testWidgets(
    'IPv4 edits and complete prefix boundaries use synchronized structured reports',
    (tester) async {
      await openPlayground(tester, 'ipv4-subnet');
      await fill(tester, playgroundSamples[1].values);
      await expandReasoning(tester);
      for (final prefix in [0, 24, 25, 31, 32]) {
        await edit(tester, 'prefix', '$prefix');
        expectSynchronized(tester);
        final model =
            tester.widget<VisualModelView>(find.byType(VisualModelView)).model
                as SubnetVisualModel;
        expect(model.inputs.subnet.prefix, prefix);
        expect(model.bits.length, 32);
        expect(model.report.formattedValue, endsWith('/$prefix'));
        if (prefix >= 31) expect(model.inputs.subnet.broadcastAddress, isNull);
      }
      await edit(tester, 'address', '10.20.30.40');
      expect(playgroundVm(tester).result!.formattedValue, '10.20.30.40/32');
      for (final bad in ['10.', '1.2.3.999', '']) {
        await edit(tester, 'address', bad);
        expect(playgroundVm(tester).result, isNull);
        expect(find.byType(VisualModelView), findsNothing);
      }
      await edit(tester, 'address', '10.20.30.40');
      await edit(tester, 'prefix', '33');
      expect(playgroundVm(tester).result, isNull);
      await edit(tester, 'prefix', '0');
      expect(playgroundVm(tester).result!.formattedValue, '0.0.0.0/0');
      expectSynchronized(tester);
    },
  );

  testWidgets(
    'gas repeats all four modes without stale roles and preserves unit handling',
    (tester) async {
      await openPlayground(tester, 'ideal-gas-law');
      final vm = playgroundVm(tester);
      const values = {
        'pressure': '100000',
        'volume': '.025',
        'amount': '1',
        'temperature': '300',
      };
      for (var cycle = 0; cycle < 2; cycle++) {
        for (final mode in vm.definition.modes) {
          tester
              .widget<DropdownButtonFormField<CalculatorMode>>(
                find.byType(DropdownButtonFormField<CalculatorMode>),
              )
              .onChanged!(mode);
          await tester.pump();
          expect(vm.result, isNull);
          expect(find.byType(VisualModelView), findsNothing);
          expect(find.byType(TextFormField), findsNWidgets(3));
          expect(liveField(mode.id), findsNothing);
          for (final input in vm.inputs) {
            await edit(tester, input.id, values[input.id]!);
          }
          if (find.byType(CalculationResultDetails).evaluate().isEmpty) {
            await expandReasoning(tester);
          }
          expectSynchronized(tester);
          final model = tester
              .widget<IdealGasVisual>(find.byType(IdealGasVisual))
              .model;
          expect(model.inputs.solved.name, mode.id);
          expect(model.values[model.inputs.solved], vm.result!.value);
          expect(find.text('Calculated · ${mode.label}'), findsOneWidget);
        }
      }
      vm.selectMode(vm.definition.modes.first);
      await tester.pump();
      await fill(tester, playgroundSamples[2].values);
      tester
          .widget<DropdownButtonFormField<EngineeringUnit>>(
            find.byKey(const ValueKey('unit-temperature-live')),
          )
          .onChanged!(EngineeringUnit.celsius);
      await edit(tester, 'temperature', '26.85');
      tester
          .widget<DropdownButtonFormField<EngineeringUnit>>(
            find.byKey(const ValueKey('unit-volume-live')),
          )
          .onChanged!(EngineeringUnit.litre);
      await edit(tester, 'volume', '25');
      expect(vm.result!.value, closeTo(99773.55141783887, 1e-8));
      await edit(tester, 'temperature', '-273.15');
      expect(vm.result, isNull);
      expect(find.byType(IdealGasVisual), findsNothing);
      await edit(tester, 'temperature', '-20');
      expect(vm.result, isNotNull);
      expectSynchronized(tester);
    },
  );

  testWidgets(
    'live typing preserves editor identity caret focus and current units',
    (tester) async {
      await openPlayground(tester, 'voltage-divider');
      await fill(tester, playgroundSamples[0].values);
      await tester.ensureVisible(liveField('voltage'));
      await tester.tap(liveField('voltage'));
      final editor = tester
          .widget<TextFormField>(liveField('voltage'))
          .controller!;
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '123',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<TextFormField>(liveField('voltage')).controller,
        same(editor),
      );
      expect(editor.selection.baseOffset, 1);
      expect(playgroundVm(tester).valueFor('voltage'), '123');
      expect(tester.testTextInput.isVisible, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keyboard edits discrete prefix and reaches reasoning controls', (
    tester,
  ) async {
    await openPlayground(tester, 'ipv4-subnet');
    await fill(tester, playgroundSamples[1].values);
    await tester.ensureVisible(liveField('address'));
    await tester.tap(liveField('address'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus;
    expect(focused, isNotNull);
    expect(
      focused!.context!.findAncestorWidgetOfExactType<TextFormField>()?.key,
      const ValueKey('input-prefix-live'),
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '32',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(playgroundVm(tester).result!.formattedValue, endsWith('/32'));
    await tester.ensureVisible(find.text('How it is calculated'));
    for (
      var step = 0;
      step < 12 && find.byType(CalculationResultDetails).evaluate().isEmpty;
      step++
    ) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
    }
    expect(find.byType(CalculationResultDetails), findsOneWidget);
  });

  testWidgets('gas mode and units support keyboard selection', (tester) async {
    await openPlayground(tester, 'ideal-gas-law');
    final mode = find.byType(DropdownButtonFormField<CalculatorMode>);
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(playgroundVm(tester).mode.id, 'volume');
    expect(liveField('volume'), findsNothing);
    final unit = find.byKey(const ValueKey('unit-temperature-live'));
    await tester.ensureVisible(unit);
    await tester.tap(unit);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      playgroundVm(tester).unitFor('temperature'),
      EngineeringUnit.celsius,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gas one clock never rebuilds inputs results or reasoning on ticks',
    (tester) async {
      await openPlayground(
        tester,
        'ideal-gas-law',
        reduced: false,
        size: const Size(1024, 768),
      );
      await fill(tester, playgroundSamples[2].values);
      final vm = playgroundVm(tester);
      await expandReasoning(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('ideal-gas-canvas')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('ideal-gas-canvas')),
                  )
                  .painter!
              as IdealGasPainter;
      final clock = painter.phase as AnimationController;
      final summary = tester.widget<CalculationResultSummary>(
        find.byType(CalculationResultSummary),
      );
      final details = tester.widget<CalculationResultDetails>(
        find.byType(CalculationResultDetails),
      );
      final field = tester.widget<CalculatorInputField>(
        find.byType(CalculatorInputField).first,
      );
      final report = vm.result;
      var notifications = 0;
      vm.addListener(() => notifications++);
      final phase = clock.value;
      await tester.pump(const Duration(milliseconds: 250));
      expect(clock.value, isNot(phase));
      expect(
        tester.widget<CalculationResultSummary>(
          find.byType(CalculationResultSummary),
        ),
        same(summary),
      );
      expect(
        tester.widget<CalculationResultDetails>(
          find.byType(CalculationResultDetails),
        ),
        same(details),
      );
      expect(
        tester.widget<CalculatorInputField>(
          find.byType(CalculatorInputField).first,
        ),
        same(field),
      );
      expect(vm.result, same(report));
      expect(notifications, 0);
      expect(find.byType(IdealGasVisual), findsOneWidget);
      await tester.ensureVisible(find.text('Pause particles'));
      await tester.tap(find.text('Pause particles'));
      await tester.pump();
      expect(clock.isAnimating, isFalse);
      await tester.tap(find.text('Play particles'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ideal-gas-canvas')),
      );
      await tester.pump();
      expect(clock.isAnimating, isTrue);
      for (final flags in [
        const FakeAccessibilityFeatures(disableAnimations: true),
        const FakeAccessibilityFeatures(reduceMotion: true),
      ]) {
        tester.platformDispatcher.accessibilityFeaturesTestValue = flags;
        await tester.pump();
        expect(clock.isAnimating, isFalse);
        expect(vm.result, same(report));
        expect(find.textContaining('Reduce Motion is on'), findsOneWidget);
      }
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(clock.isAnimating, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(clock.isAnimating, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final sample in playgroundSamples) {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        '${sample.id} ${theme.name} responsive 320 phone tablet and 200% semantics',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await openPlayground(
              tester,
              sample.id,
              theme: theme,
              size: const Size(320, 640),
              textScale: 2,
            );
            await fill(tester, sample.values);
            await expandReasoning(tester);
            expectSynchronized(tester);
            await tester.ensureVisible(find.text('Engineering context'));
            await tester.tap(find.text('Engineering context'));
            await tester.pumpAndSettle();
            for (final note in playgroundVm(tester).definition.assumptions) {
              await tester.ensureVisible(find.text(note));
              await tester.pump();
              final rect = tester.getRect(find.text(note));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(320));
              expect(tester.takeException(), isNull);
            }
            expect(
              find.byType(TextFormField),
              findsNWidgets(sample.values.length),
            );
            for (final size in [
              const Size(320, 640),
              const Size(430, 932),
              const Size(1024, 768),
            ]) {
              tester.view.physicalSize = size;
              await tester.pump();
              expect(
                find.byKey(const ValueKey('playground-one-column')),
                findsOneWidget,
              );
              await tester.ensureVisible(find.byType(CalculationResultSummary));
              await tester.pump();
              expect(
                find.bySemanticsLabel(RegExp('Calculated ·')),
                findsWidgets,
              );
              await tester.ensureVisible(find.byType(VisualModelView));
              await tester.pump();
              await tester.ensureVisible(find.text('How it is calculated'));
              await tester.pump();
              expect(tester.takeException(), isNull);
            }
            tester.platformDispatcher.textScaleFactorTestValue = 1;
            await tester.pump();
            expect(
              find.byKey(const ValueKey('playground-two-columns')),
              findsOneWidget,
            );
            await tester.ensureVisible(find.byType(TextFormField).first);
            await tester.pump();
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
