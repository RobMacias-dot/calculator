import 'dart:ui' as ui;

import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/divider_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/vector_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/reynolds_visual.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/visual_learning_samples.dart';

void main() {
  test(
    'static painters repaint for meaningful geometry/theme/text changes only',
    () {
      final vm = visualVm('vector-magnitude', {'x': '3', 'y': '-4'});
      addTearDown(vm.dispose);
      final model = mapVisualModel(vm.result!)! as VectorVisualModel;
      final original = VectorPainter(
        model,
        Colors.black,
        Colors.orange,
        TextScaler.noScaling,
      );
      expect(
        VectorPainter(
          model,
          Colors.black,
          Colors.orange,
          TextScaler.noScaling,
        ).shouldRepaint(original),
        isFalse,
      );
      expect(
        VectorPainter(
          model,
          Colors.white,
          Colors.orange,
          TextScaler.noScaling,
        ).shouldRepaint(original),
        isTrue,
      );
      vm.updateAndCalculate('x', '-3');
      expect(
        VectorPainter(
          mapVisualModel(vm.result!)! as VectorVisualModel,
          Colors.black,
          Colors.orange,
          TextScaler.noScaling,
        ).shouldRepaint(original),
        isTrue,
      );
      final divider = DividerPainter(
        Colors.black,
        Colors.orange,
        TextScaler.noScaling,
      );
      expect(
        DividerPainter(
          Colors.black,
          Colors.orange,
          TextScaler.noScaling,
        ).shouldRepaint(divider),
        isFalse,
      );
      expect(
        DividerPainter(
          Colors.black,
          Colors.orange,
          const TextScaler.linear(2),
        ).shouldRepaint(divider),
        isTrue,
      );
    },
  );

  test(
    'flow geometry is deterministic, bounded and paints at varied viewports',
    () {
      const phase = AlwaysStoppedAnimation(.5);
      for (final intensity in [0.0, .5, 1.0]) {
        final painter = ReynoldsPainter(
          phase: phase,
          irregularity: intensity,
          ink: Colors.black,
          accent: Colors.orange,
        );
        for (var lane = 0; lane < ReynoldsPainter.laneCount; lane++) {
          for (var i = 0; i <= 100; i++) {
            final y = painter.laneY(lane, i / 100);
            expect(y, inInclusiveRange(0, 1));
            expect(y, painter.laneY(lane, i / 100));
          }
        }
        for (final size in [const Size(200, 160), const Size(600, 300)]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          painter.paint(canvas, size);
          painter.paint(canvas, size); // reuse cached geometry
          recorder.endRecording().dispose();
        }
        expect(
          ReynoldsPainter(
            phase: phase,
            irregularity: intensity,
            ink: Colors.black,
            accent: Colors.orange,
          ).shouldRepaint(painter),
          isFalse,
        );
        expect(
          ReynoldsPainter(
            phase: phase,
            irregularity: intensity,
            ink: Colors.white,
            accent: Colors.orange,
          ).shouldRepaint(painter),
          isTrue,
        );
      }
      expect(ReynoldsPainter.particleCount, 24);
    },
  );
}
