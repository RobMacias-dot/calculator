import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../calculator_view_model.dart';
import 'diagram_labels.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_scene.dart';

class VectorVisual extends StatelessWidget {
  const VectorVisual({super.key, required this.model, required this.viewModel});
  final VectorVisualModel model;
  final CalculatorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisualScene(
          summary: model.summary,
          child: CustomPaint(
            painter: VectorPainter(
              model,
              colors.onSurfaceVariant,
              colors.primary,
              MediaQuery.textScalerOf(context),
              labelStyle: Theme.of(context).textTheme.labelSmall!,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Magnitude ${model.report.formattedValue}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          model.is3d
              ? 'Oblique 3D projection. Dashed segments add x, y and z; the arrow joins the origin to the endpoint. '
                    'Depth is projected onto the screen, so screen length and angles are not physical measurements.'
              : 'Dashed segments add x then y. The arrow points from the origin to (x, y). '
                    'A dot at the origin represents the zero vector.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'The diagram automatically fits the largest component. '
          'Very small components may be too short to see; their values remain below.',
        ),
        for (final component in model.inputs.components)
          VisualInputControl(
            input: component,
            viewModel: viewModel,
            minimum: -10,
            maximum: 10,
          ),
      ],
    );
  }
}

class VectorPainter extends CustomPainter {
  VectorPainter(
    this.model,
    this.ink,
    this.accent,
    this.textScaler, {
    this.labelStyle = const TextStyle(),
  });
  final VectorVisualModel model;
  final Color ink;
  final Color accent;
  final TextScaler textScaler;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // Isotropic viewport mapping keeps 2D angles correct in any aspect ratio.
    final radius = math.min(size.width, size.height) * .37;
    final origin = Offset(size.width / 2, size.height / 2);
    Offset p(PlotPoint point) =>
        origin + Offset(point.x * radius, -point.y * radius);
    final axis = Paint()
      ..color = ink
      ..strokeWidth = 1.5;
    final arrow = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final axes = model.is3d
        ? <({PlotPoint point, String label})>[
            (point: (x: .8, y: -.41), label: 'x'),
            (point: (x: -.8, y: -.41), label: 'y'),
            (point: (x: 0, y: 1), label: 'z'),
          ]
        : <({PlotPoint point, String label})>[
            (point: (x: 1, y: 0), label: 'x'),
            (point: (x: 0, y: 1), label: 'y'),
          ];
    for (final axisEnd in axes) {
      canvas.drawLine(
        p((x: -axisEnd.point.x, y: -axisEnd.point.y)),
        p(axisEnd.point),
        axis,
      );
      paintDiagramLabel(
        canvas,
        axisEnd.label,
        p((x: axisEnd.point.x * 1.18, y: axisEnd.point.y * 1.18)),
        ink,
        textScaler,
        labelStyle,
      );
    }
    for (var i = 1; i < model.points.length; i++) {
      final start = p(model.points[i - 1]), end = p(model.points[i]);
      for (var dash = 0; dash < 8; dash++) {
        canvas.drawLine(
          Offset.lerp(start, end, dash / 8)!,
          Offset.lerp(start, end, (dash + .55) / 8)!,
          axis,
        );
      }
    }
    final tip = p(model.points.last);
    canvas.drawLine(origin, tip, arrow);
    if ((tip - origin).distance < 1) {
      canvas.drawCircle(origin, 4, arrow);
    } else {
      final direction = math.atan2(tip.dy - origin.dy, tip.dx - origin.dx);
      for (final turn in [-.5, .5]) {
        canvas.drawLine(
          tip,
          tip -
              Offset(math.cos(direction + turn), math.sin(direction + turn)) *
                  10,
          arrow,
        );
      }
    }
  }

  @override
  bool shouldRepaint(VectorPainter oldDelegate) =>
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent ||
      labelStyle != oldDelegate.labelStyle ||
      textScaler != oldDelegate.textScaler ||
      model.is3d != oldDelegate.model.is3d ||
      !_samePoints(model.points, oldDelegate.model.points);

  bool _samePoints(List<PlotPoint> a, List<PlotPoint> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((same) => same);
}
