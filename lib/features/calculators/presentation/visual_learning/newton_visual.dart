import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../calculator_view_model.dart';
import 'diagram_arrow.dart';
import 'diagram_labels.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_scene.dart';

class NewtonVisual extends StatelessWidget {
  const NewtonVisual({super.key, required this.model, required this.viewModel});
  final NewtonVisualModel model;
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
            painter: NewtonPainter(
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
          'Net force F = ${model.report.formattedValue} N',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Mass ${quantityLabel(model.inputs.mass)} · '
          'Input acceleration ${quantityLabel(model.inputs.acceleration)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'This calculator solves net force from mass and acceleration. '
          'At fixed mass, greater acceleration needs greater force. '
          'At fixed acceleration, greater mass needs greater force. '
          'For the same nonzero force and positive mass, a larger mass corresponds to a smaller acceleration.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Static illustration: F and a arrows show direction along the chosen axis, '
          'not velocity or a motion trajectory. Block size and arrow lengths use separate capped display scales; '
          'they cannot be compared as physical lengths. A dot denotes zero or an arrow too small to resolve.',
        ),
        if (model.inputs.mass.baseValue == 0)
          const Text(
            'Zero mass is accepted by this calculator; it yields zero force for the supplied acceleration. '
            'This is an algebraic boundary, not a model of a physical massive object.',
          ),
        VisualInputControl(
          input: model.inputs.mass,
          viewModel: viewModel,
          minimum: 0,
          maximum: 100,
        ),
        VisualInputControl(
          input: model.inputs.acceleration,
          viewModel: viewModel,
          minimum: -20,
          maximum: 20,
        ),
      ],
    );
  }
}

class NewtonPainter extends CustomPainter {
  NewtonPainter(
    this.model,
    this.ink,
    this.accent,
    this.textScaler,
    this.labelStyle,
  );
  final NewtonVisualModel model;
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
    final half = .09 + .08 * model.massSize;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(p(.5 - half, .40), p(.5 + half, .65)),
        const Radius.circular(10),
      ),
      line,
    );
    paintDiagramLabel(canvas, 'm', p(.5, .52), ink, textScaler, labelStyle);
    paintDiagramArrow(
      canvas,
      p(.5, .26),
      p(.5 + .34 * model.forceArrow, .26),
      arrow,
    );
    paintDiagramLabel(canvas, 'F', p(.5, .12), accent, textScaler, labelStyle);
    paintDiagramArrow(
      canvas,
      p(.5, .79),
      p(.5 + .34 * model.accelerationArrow, .79),
      line,
    );
    paintDiagramLabel(canvas, 'a', p(.5, .92), ink, textScaler, labelStyle);
  }

  @override
  bool shouldRepaint(NewtonPainter oldDelegate) =>
      model.massSize != oldDelegate.model.massSize ||
      model.forceArrow != oldDelegate.model.forceArrow ||
      model.accelerationArrow != oldDelegate.model.accelerationArrow ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent ||
      textScaler != oldDelegate.textScaler ||
      labelStyle != oldDelegate.labelStyle;
}
