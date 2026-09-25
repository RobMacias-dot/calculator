// Four static review artifacts, not a frame-by-frame golden suite.
// flutter test tool/capture_phase5.dart --update-goldens
import 'package:engineering_toolkit/core/design_system/app_theme.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/visual_learning_samples.dart';
import 'capture_phase3.dart' show loadReviewFonts;

void main() {
  setUpAll(loadReviewFonts);
  for (final sample in [
    (
      id: 'voltage-divider',
      mode: 'output',
      theme: ThemeMode.light,
      values: visualSamples[0].values,
      width: 430.0,
      scale: 1.0,
    ),
    (
      id: 'vector-magnitude',
      mode: '3d',
      theme: ThemeMode.dark,
      values: {'x': '-2', 'y': '3', 'z': '6'},
      width: 320.0,
      scale: 2.0,
    ),
    (
      id: 'reynolds-number',
      mode: 'reynolds',
      theme: ThemeMode.light,
      values: visualSamples[2].values,
      width: 430.0,
      scale: 1.0,
    ),
    (
      id: 'ipv4-subnet',
      mode: 'subnet',
      theme: ThemeMode.dark,
      values: {'address': '192.168.1.10', 'prefix': '25'},
      width: 430.0,
      scale: 1.0,
    ),
  ]) {
    testWidgets('review ${sample.id}', (tester) async {
      final vm = visualVm(sample.id, sample.values, mode: sample.mode);
      addTearDown(vm.dispose);
      tester.view.physicalSize = Size(sample.width, 932);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = sample.scale;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: sample.theme,
          home: Scaffold(body: VisualLearningSheet(viewModel: vm)),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../build/phase5-${sample.id}.png'),
      );
    });
  }
}
