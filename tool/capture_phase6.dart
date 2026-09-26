// On-demand review artifacts; not pixel-perfect baselines or animation goldens.
// flutter test tool/capture_phase6.dart --update-goldens
import 'package:engineering_toolkit/core/design_system/app_theme.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/visual_learning_samples.dart';
import 'capture_phase3.dart' show loadReviewFonts;

void main() {
  setUpAll(loadReviewFonts);
  for (final sample in visualSamples.skip(4)) {
    for (final large in [false, true]) {
      testWidgets('review ${sample.id} large=$large', (tester) async {
        final vm = visualVm(sample.id, {
          ...sample.values,
          if (large && sample.id == 'newtons-second-law') 'acceleration': '-3',
          if (large && sample.id == 'torque') 'radius': '0',
          if (large && sample.id == 'bernoulli-basic') ...{
            'height1': '-10',
            'height2': '-10',
            'speed1': '0',
            'speed2': '0',
            'pressure1': '-100',
          },
        });
        addTearDown(vm.dispose);
        tester.view.physicalSize = Size(large ? 320 : 430, large ? 900 : 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
            '../build/phase6-${sample.id}-${large ? 'large' : 'normal'}.png',
          ),
        );
      });
    }
  }
}
