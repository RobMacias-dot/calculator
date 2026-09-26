import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../calculator_view_model.dart';
import 'diagram_arrow.dart';
import 'diagram_labels.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_scene.dart';

class BernoulliVisual extends StatelessWidget {
  const BernoulliVisual({
    super.key,
    required this.model,
    required this.viewModel,
  });
  final BernoulliVisualModel model;
  final CalculatorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final inputs = model.inputs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisualScene(
          summary: model.summary,
          child: CustomPaint(
            painter: BernoulliPainter(
              model,
              colors.onSurface,
              colors.primary,
              MediaQuery.textScalerOf(context),
              Theme.of(context).textTheme.labelSmall!,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Downstream pressure P2 = ${model.report.formattedValue} Pa',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Station 1: P1 ${quantityLabel(inputs.pressure1)} · '
          'v1 ${quantityLabel(inputs.speed1)} · z1 ${quantityLabel(inputs.height1)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Station 2: v2 ${quantityLabel(inputs.speed2)} · z2 ${quantityLabel(inputs.height2)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Along the same ideal streamline, changes in speed and elevation affect downstream pressure. '
          'Both pressures use the same reference; signed gauge pressures are allowed. '
          'The signed bars below the pipe compare P1 and P2 against a shared zero line.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Schematic flow path from station 1 to 2. Elevations and speed arrows each share an automatically fitted scale. '
          'Pipe width is decorative: areas and flow rate are not supplied or inferred. '
          'Arrows are static directional cues; a dot means zero or a speed arrow too small to resolve. '
          'This is not CFD or a simulated pressure field. Assumes steady, incompressible, inviscid flow with no pumps or losses.',
        ),
        VisualInputControl(
          input: inputs.pressure1,
          viewModel: viewModel,
          minimum: -100000,
          maximum: 300000,
        ),
        VisualInputControl(
          input: inputs.density,
          viewModel: viewModel,
          minimum: 1,
          maximum: 2000,
        ),
        VisualInputControl(
          input: inputs.speed1,
          viewModel: viewModel,
          minimum: 0,
          maximum: 20,
        ),
        VisualInputControl(
          input: inputs.speed2,
          viewModel: viewModel,
          minimum: 0,
          maximum: 20,
        ),
        VisualInputControl(
          input: inputs.height1,
          viewModel: viewModel,
          minimum: -10,
          maximum: 10,
        ),
        VisualInputControl(
          input: inputs.height2,
          viewModel: viewModel,
          minimum: -10,
          maximum: 10,
        ),
      ],
    );
  }
}

class BernoulliPainter extends CustomPainter {
  BernoulliPainter(
    this.model,
    this.ink,
    this.accent,
    this.textScaler,
    this.labelStyle,
  );
  final BernoulliVisualModel model;
  final Color ink, accent;
  final TextScaler textScaler;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    final line = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final arrow = Paint()
      ..color = accent
      ..strokeWidth = 3;
    final y1 = .32 - .10 * model.elevation1;
    final y2 = .32 - .10 * model.elevation2;
    for (final edge in [-.06, .06]) {
      canvas.drawPath(
        Path()
          ..moveTo(.08 * size.width, (y1 + edge) * size.height)
          ..lineTo(.32 * size.width, (y1 + edge) * size.height)
          ..cubicTo(
            .48 * size.width,
            (y1 + edge) * size.height,
            .52 * size.width,
            (y2 + edge) * size.height,
            .68 * size.width,
            (y2 + edge) * size.height,
          )
          ..lineTo(.92 * size.width, (y2 + edge) * size.height),
        line,
      );
    }
    paintDiagramArrow(
      canvas,
      p(.12, y1),
      p(.12 + .17 * model.speed1, y1),
      arrow,
    );
    paintDiagramArrow(
      canvas,
      p(.70, y2),
      p(.70 + .17 * model.speed2, y2),
      arrow,
    );
    paintDiagramLabel(
      canvas,
      '1',
      p(.21, y1 - .13),
      ink,
      textScaler,
      labelStyle,
    );
    paintDiagramLabel(
      canvas,
      '2',
      p(.79, y2 - .13),
      ink,
      textScaler,
      labelStyle,
    );
    canvas.drawLine(p(.10, .80), p(.90, .80), line);
    canvas.drawLine(p(.30, .80), p(.30, .80 - .13 * model.pressure1), arrow);
    canvas.drawLine(p(.70, .80), p(.70, .80 - .13 * model.pressure2), arrow);
    paintDiagramLabel(canvas, 'P1', p(.30, .61), ink, textScaler, labelStyle);
    paintDiagramLabel(canvas, 'P2', p(.70, .61), ink, textScaler, labelStyle);
    paintDiagramLabel(canvas, '0', p(.06, .80), ink, textScaler, labelStyle);
  }

  @override
  bool shouldRepaint(BernoulliPainter oldDelegate) =>
      model.elevation1 != oldDelegate.model.elevation1 ||
      model.elevation2 != oldDelegate.model.elevation2 ||
      model.speed1 != oldDelegate.model.speed1 ||
      model.speed2 != oldDelegate.model.speed2 ||
      model.pressure1 != oldDelegate.model.pressure1 ||
      model.pressure2 != oldDelegate.model.pressure2 ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent ||
      textScaler != oldDelegate.textScaler ||
      labelStyle != oldDelegate.labelStyle;
}
