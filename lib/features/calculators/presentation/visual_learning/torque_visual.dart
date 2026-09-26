import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../calculator_view_model.dart';
import 'diagram_arrow.dart';
import 'diagram_labels.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_scene.dart';

class TorqueVisual extends StatelessWidget {
  const TorqueVisual({super.key, required this.model, required this.viewModel});
  final TorqueVisualModel model;
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
            painter: TorquePainter(
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
          'Torque magnitude τ = ${model.report.formattedValue} N·m',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'The circle marks the pivot; r reaches the force application point. '
          'Force is perpendicular to the lever. Increasing force or lever arm increases the turning effect. '
          'This calculator has no angle input and reports magnitude only.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Illustrative lengths use separate capped display scales. '
          'The upward force is a drawing convention, not a calculated rotation direction. '
          'At zero lever arm the force acts at the pivot; a dot represents zero or a force arrow too small to resolve.',
        ),
        if (model.report.value == 0)
          const Text('Zero torque: no turning effect in this model.'),
        VisualInputControl(
          input: model.inputs.force,
          viewModel: viewModel,
          minimum: 0,
          maximum: 100,
        ),
        VisualInputControl(
          input: model.inputs.radius,
          viewModel: viewModel,
          minimum: 0,
          maximum: 5,
        ),
      ],
    );
  }
}

class TorquePainter extends CustomPainter {
  TorquePainter(
    this.model,
    this.ink,
    this.accent,
    this.textScaler,
    this.labelStyle,
  );
  final TorqueVisualModel model;
  final Color ink, accent;
  final TextScaler textScaler;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    final line = Paint()
      ..color = ink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final arrow = Paint()
      ..color = accent
      ..strokeWidth = 3;
    final end = .18 + .62 * model.leverLength;
    canvas.drawLine(p(.18, .66), p(end, .66), line);
    canvas.drawCircle(p(.18, .66), 7, line);
    paintDiagramArrow(
      canvas,
      p(end, .66),
      p(end, .66 - .40 * model.forceArrow),
      arrow,
    );
    paintDiagramLabel(canvas, 'F', p(end, .13), accent, textScaler, labelStyle);
    paintDiagramLabel(
      canvas,
      'r',
      p((.18 + end) / 2, .83),
      ink,
      textScaler,
      labelStyle,
    );
    if (model.leverLength > .08 && model.forceArrow > .08) {
      canvas.drawPath(
        Path()
          ..moveTo(end * size.width - 10, .66 * size.height)
          ..relativeLineTo(0, -10)
          ..relativeLineTo(10, 0),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(TorquePainter oldDelegate) =>
      model.leverLength != oldDelegate.model.leverLength ||
      model.forceArrow != oldDelegate.model.forceArrow ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent ||
      textScaler != oldDelegate.textScaler ||
      labelStyle != oldDelegate.labelStyle;
}
