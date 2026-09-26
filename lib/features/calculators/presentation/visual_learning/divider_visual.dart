import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../../../core/formatting/number_formatting.dart';
import '../calculator_view_model.dart';
import 'diagram_labels.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_scene.dart';

class DividerVisual extends StatelessWidget {
  const DividerVisual({
    super.key,
    required this.model,
    required this.viewModel,
    this.showInputControls = true,
  });
  final DividerVisualModel model;
  final CalculatorViewModel viewModel;
  final bool showInputControls;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fraction = model.outputFraction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisualScene(
          summary: model.summary,
          child: CustomPaint(
            painter: DividerPainter(
              colors.onSurface,
              colors.primary,
              MediaQuery.textScalerOf(context),
              labelStyle: Theme.of(context).textTheme.labelSmall!,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Vin ${quantityLabel(model.inputs.voltage)} · '
          'R1 ${quantityLabel(model.inputs.r1)} · R2 ${quantityLabel(model.inputs.r2)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Vout ${model.report.formattedValue} V',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(value: fraction ?? 0, minHeight: 8),
        const SizedBox(height: AppSpacing.sm),
        Text(
          fraction == null
              ? 'Vin is zero, so there is no output voltage to compare.'
              : 'Output is ${NumberFormatting.format(fraction * 100)}% of the input voltage.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Vout is measured from the marked node to ground, across R2. '
          'Both resistor symbols have equal size; their size does not encode resistance. '
          'The circuit is unloaded.',
        ),
        if (showInputControls) ...[
          VisualInputControl(
            input: model.inputs.voltage,
            viewModel: viewModel,
            minimum: -24,
            maximum: 24,
            label: 'Input voltage Vin',
          ),
          VisualInputControl(
            input: model.inputs.r1,
            viewModel: viewModel,
            minimum: 1,
            maximum: 10000,
          ),
          VisualInputControl(
            input: model.inputs.r2,
            viewModel: viewModel,
            minimum: 1,
            maximum: 10000,
          ),
        ],
      ],
    );
  }
}

class DividerPainter extends CustomPainter {
  DividerPainter(
    this.ink,
    this.accent,
    this.textScaler, {
    this.labelStyle = const TextStyle(),
  });
  final Color ink;
  final Color accent;
  final TextScaler textScaler;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    final wire = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final output = Paint()
      ..color = accent
      ..strokeWidth = 3;
    final path = Path()
      ..moveTo(size.width * .18, size.height * .39)
      ..lineTo(size.width * .18, size.height * .08)
      ..lineTo(size.width * .60, size.height * .08)
      ..lineTo(size.width * .60, size.height * .19)
      ..moveTo(size.width * .60, size.height * .40)
      ..lineTo(size.width * .60, size.height * .60)
      ..moveTo(size.width * .60, size.height * .81)
      ..lineTo(size.width * .60, size.height * .92)
      ..lineTo(size.width * .18, size.height * .92)
      ..lineTo(size.width * .18, size.height * .61);
    canvas.drawPath(path, wire);
    canvas.drawOval(Rect.fromPoints(p(.10, .39), p(.26, .61)), wire);
    canvas.drawRect(Rect.fromPoints(p(.55, .19), p(.65, .40)), wire);
    canvas.drawRect(Rect.fromPoints(p(.55, .60), p(.65, .81)), wire);
    canvas.drawLine(p(.60, .50), p(.89, .50), output);
    canvas.drawCircle(p(.60, .50), 4, output);
    canvas.drawLine(p(.54, .94), p(.66, .94), wire);
    canvas.drawLine(p(.56, .97), p(.64, .97), wire);
    paintDiagramLabel(canvas, '+', p(.18, .46), ink, textScaler, labelStyle);
    paintDiagramLabel(canvas, '−', p(.18, .55), ink, textScaler, labelStyle);
    paintDiagramLabel(canvas, 'Vin', p(.38, .50), ink, textScaler, labelStyle);
    paintDiagramLabel(canvas, 'R1', p(.42, .29), ink, textScaler, labelStyle);
    paintDiagramLabel(canvas, 'R2', p(.42, .70), ink, textScaler, labelStyle);
    paintDiagramLabel(
      canvas,
      'Vout',
      p(.81, .39),
      accent,
      textScaler,
      labelStyle,
    );
  }

  @override
  bool shouldRepaint(DividerPainter oldDelegate) =>
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent ||
      labelStyle != oldDelegate.labelStyle ||
      textScaler != oldDelegate.textScaler;
}
