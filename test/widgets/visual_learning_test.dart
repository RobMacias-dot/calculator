import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/domain/engineering_unit.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/reynolds_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_preferences_repository.dart';
import '../support/visual_learning_samples.dart';
import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;

Future<void> openVisual(
  WidgetTester tester,
  String id,
  Map<String, String> values, {
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  Size size = const Size(430, 932),
  bool reduced = false,
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
    location: '/calculator/$id',
    size: size,
    textScale: textScale,
  );
  for (final entry in values.entries) {
    await enterInput(tester, entry.key, entry.value);
  }
  await pressCalculate(tester);
  await tester.ensureVisible(find.text('Learn visually'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Learn visually'));
  // Reynolds is intentionally continuous: never wait for it to settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

ReynoldsPainter flowPainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.byKey(const ValueKey('reynolds-canvas')))
            .painter!
        as ReynoldsPainter;

void main() {
  testWidgets(
    'manual values outside slider range are retained, only thumb is clamped',
    (tester) async {
      await openVisual(tester, 'voltage-divider', {
        'voltage': '12',
        'r1': '1e250',
        'r2': '1e-40',
      });
      final vm = tester
          .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
          .viewModel;
      final report = vm.result;
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('visual-control-r1')),
      );
      expect(slider.value, slider.max);
      expect(vm.valueFor('r1'), '1e250');
      expect(vm.result, same(report));
      expect(
        find.textContaining('Manual value is outside this slider range'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all four surfaces also fit a tablet viewport', (tester) async {
    for (final sample in visualSamples) {
      await openVisual(
        tester,
        sample.id,
        sample.values,
        size: const Size(1024, 768),
        reduced: true,
      );
      expect(
        tester.getSize(find.byType(VisualLearningSheet)).width,
        lessThanOrEqualTo(760),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'Reynolds stops when its route ticker mode is hidden and resumes',
    (tester) async {
      final vm = visualVm(visualSamples[2].id, visualSamples[2].values);
      final visible = ValueNotifier(true);
      addTearDown(vm.dispose);
      addTearDown(visible.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, enabled, _) => TickerMode(
                enabled: enabled,
                child: SingleChildScrollView(
                  child: ReynoldsVisual(
                    model: mapVisualModel(vm.result!)! as ReynoldsVisualModel,
                    viewModel: vm,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final phase = flowPainter(tester).phase;
      visible.value = false;
      await tester.pump();
      final stopped = phase.value;
      await tester.pump(const Duration(seconds: 1));
      expect(phase.value, stopped);
      visible.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(phase.value, isNot(stopped));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'capability entry is disabled until valid and absent for unsupported tools',
    (tester) async {
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/voltage-divider',
      );
      expect(find.byType(VisualLearningSheet), findsNothing);
      final button = find.widgetWithText(OutlinedButton, 'Learn visually');
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/ohms-law',
      );
      expect(find.text('Learn visually'), findsNothing);
    },
  );

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final sample in visualSamples) {
      testWidgets(
        '${sample.id} opens with semantics at 320px/200%/${theme.name}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await openVisual(
              tester,
              sample.id,
              sample.values,
              theme: theme,
              size: const Size(320, 640),
              textScale: 2,
              reduced: true,
            );
            expect(find.byType(VisualLearningSheet), findsOneWidget);
            expect(
              find.bySemanticsLabel(
                RegExp(
                  r'Voltage divider\.|2D vector\.|Reynolds number|IPv4 192',
                ),
              ),
              findsWidgets,
            );
            expect(tester.takeException(), isNull);
            // Scroll to controls: exercise both canvas and offscreen form content.
            final slider = find.byType(Slider).last;
            await tester.ensureVisible(slider);
            await tester.pump();
            expect(tester.takeException(), isNull);
            await tester.tap(find.byTooltip('Close visualization'));
            await tester.pumpAndSettle();
            expect(find.byType(VisualLearningSheet), findsNothing);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'divider sliders recalculate, preserve units and synchronize main text fields',
    (tester) async {
      await openVisual(tester, visualSamples[0].id, visualSamples[0].values);
      final sheet = tester.widget<VisualLearningSheet>(
        find.byType(VisualLearningSheet),
      );
      final vm = sheet.viewModel;
      vm.setUnit('r1', EngineeringUnit.kiloohm);
      vm.updateAndCalculate('r1', '1');
      await tester.pump();
      final r1 = tester.widget<Slider>(
        find.byKey(const ValueKey('visual-control-r1')),
      );
      r1.onChanged!(2000);
      await tester.pump();
      expect(vm.unitFor('r1'), EngineeringUnit.kiloohm);
      expect(vm.valueFor('r1'), '2.0');
      expect(vm.result!.value, 6);
      final voltage = find.byKey(const ValueKey('visual-control-voltage'));
      await tester.ensureVisible(voltage);
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(voltage));
      await tester.pumpAndSettle();
      expect(vm.result, isNotNull);
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
      final field = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.key.toString().contains('input-r1-'),
      );
      expect(tester.widget<TextFormField>(field).initialValue, '2.0');
      expect(vm.result!.context, isNotNull);
    },
  );

  testWidgets('IPv4 control drives engine through /0 /24 /25 /26 /31 /32', (
    tester,
  ) async {
    await openVisual(tester, visualSamples[3].id, visualSamples[3].values);
    final vm = tester
        .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
        .viewModel;
    for (final prefix in [0, 24, 25, 26, 31, 32]) {
      tester
          .widget<Slider>(find.byKey(const ValueKey('visual-control-prefix')))
          .onChanged!(prefix.toDouble());
      await tester.pump();
      expect(vm.valueFor('prefix'), '$prefix');
      expect(vm.valueFor('address'), '192.168.1.10');
      expect(find.text('CIDR prefix: /$prefix'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('1 addresses'), findsOneWidget);
  });

  testWidgets(
    'vector supports keyboard exploration and 3D without extra inputs',
    (tester) async {
      final vm = visualVm('vector-magnitude', {
        'x': '-2',
        'y': '3',
        'z': '-6',
      }, mode: '3d');
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VisualLearningSheet(viewModel: vm)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(3));
      final slider = find.byKey(const ValueKey('visual-control-z'));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      await tester.tap(slider);
      await tester.pump();
      final before = vm.valueFor('z');
      // Traverse with an actual keyboard: touch platforms need not focus a
      // slider after a tap, but Tab must make every control reachable.
      for (var step = 0; step < 6 && vm.valueFor('z') == before; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      expect(vm.valueFor('z'), isNot(before));
      expect(vm.result, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('invalid engine result removes scene and exposes errors', (
    tester,
  ) async {
    await openVisual(tester, visualSamples[0].id, visualSamples[0].values);
    final vm = tester
        .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
        .viewModel;
    vm.updateAndCalculate('r1', '-1');
    await tester.pump();
    expect(find.byType(Slider), findsNothing);
    expect(find.text('Return to inputs'), findsOneWidget);
    expect(vm.result, isNull);
    expect(find.text(vm.issues.first.message), findsWidgets);
  });

  testWidgets(
    'Reynolds ticks repaint without rebuilding or recalculating, pause and dispose',
    (tester) async {
      await openVisual(tester, visualSamples[2].id, visualSamples[2].values);
      final original = flowPainter(tester);
      final vm = tester
          .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
          .viewModel;
      var calculations = 0;
      vm.addListener(() => calculations++);
      final phase = original.phase.value;
      await tester.pump(const Duration(milliseconds: 500));
      expect(flowPainter(tester), same(original));
      expect(original.phase.value, isNot(phase));
      expect(calculations, 0);
      await tester.ensureVisible(find.text('Pause flow'));
      await tester.pump();
      await tester.tap(find.text('Pause flow'));
      await tester.pump();
      final stopped = original.phase.value;
      await tester.pump(const Duration(seconds: 1));
      expect(original.phase.value, stopped);
      await tester.tap(find.text('Play flow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(original.phase.value, isNot(stopped));
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reynolds-canvas')), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reynolds stops for both accessibility flags, zero speed and app background',
    (tester) async {
      await openVisual(tester, visualSamples[2].id, visualSamples[2].values);
      final animation = flowPainter(tester).phase;
      for (final features in [
        const FakeAccessibilityFeatures(disableAnimations: true),
        const FakeAccessibilityFeatures(reduceMotion: true),
      ]) {
        tester.platformDispatcher.accessibilityFeaturesTestValue = features;
        await tester.pump();
        final stopped = animation.value;
        await tester.pump(const Duration(seconds: 1));
        expect(animation.value, stopped);
        expect(find.textContaining('Reduce Motion is on'), findsOneWidget);
        expect(find.byKey(const ValueKey('reynolds-canvas')), findsOneWidget);
      }
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      final paused = animation.value;
      await tester.pump(const Duration(seconds: 1));
      expect(animation.value, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(animation.value, isNot(paused));
      tester
          .widget<Slider>(find.byKey(const ValueKey('visual-control-speed')))
          .onChanged!(0);
      await tester.pump();
      final zero = animation.value;
      await tester.pump(const Duration(seconds: 1));
      expect(animation.value, zero);
      expect(find.textContaining('Zero speed:'), findsOneWidget);
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('visual controls have labeled targets and theme contrast', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await openVisual(
        tester,
        visualSamples[0].id,
        visualSamples[0].values,
        theme: ThemeMode.dark,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('visual-control-voltage')),
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });
}
