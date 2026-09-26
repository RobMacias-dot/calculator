// Two static review artifacts, not animated-frame goldens.
// flutter test tool/capture_phase7.dart --update-goldens
import 'package:engineering_toolkit/core/design_system/app_theme.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/visual_learning_samples.dart';
import 'capture_phase3.dart' show loadReviewFonts;

void main() {
  setUpAll(loadReviewFonts);
  for (final large in [false, true]) {
    testWidgets('gas static review large=$large', (tester) async {
      final vm = visualVm('ideal-gas-law', {
        'amount': '1',
        'temperature': '300',
        'pressure': '100000',
      }, mode: 'volume');
      addTearDown(vm.dispose);
      tester.view.physicalSize = Size(large ? 320 : 430, large ? 1000 : 1100);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
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
          theme: large ? AppTheme.dark : AppTheme.light,
          home: Scaffold(body: VisualLearningSheet(viewModel: vm)),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../build/phase7-gas-${large ? 'large' : 'normal'}.png',
        ),
      );
    });
  }
}
