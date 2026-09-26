import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../calculator_view_model.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_animation_lifecycle.dart';
import 'visual_scene.dart';

class ReynoldsVisual extends StatefulWidget {
  const ReynoldsVisual({
    super.key,
    required this.model,
    required this.viewModel,
  });
  final ReynoldsVisualModel model;
  final CalculatorViewModel viewModel;

  @override
  State<ReynoldsVisual> createState() => _ReynoldsVisualState();
}

class _ReynoldsVisualState extends State<ReynoldsVisual>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        VisualAnimationLifecycle<ReynoldsVisual> {
  @override
  bool get motionUseful => widget.model.hasFlow;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisualScene(
          key: visualSceneKey,
          summary: model.summary,
          child: CustomPaint(
            key: const ValueKey('reynolds-canvas'),
            painter: ReynoldsPainter(
              phase: visualClock,
              irregularity: model.irregularity,
              ink: colors.onSurfaceVariant,
              accent: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Re = ${model.report.formattedValue}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Flow moves left to right. Ordered paths become progressively more irregular as Re increases. '
          'This is an educational illustration, not CFD or a prediction of the flow regime. '
          'Geometry and conditions determine real transition thresholds.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Path irregularity uses a capped logarithmic display scale (Re 1 to 1,000,000), '
          'with no classification boundaries.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (motionReduced)
          const Text(
            'Reduce Motion is on. Static paths preserve the same visual information.',
          )
        else if (!model.hasFlow)
          const Text('Zero speed: the flow illustration is stationary.')
        else
          OutlinedButton.icon(
            onPressed: () => setState(() {
              motionPaused = !motionPaused;
              syncVisualMotion();
            }),
            icon: Icon(
              motionPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(motionPaused ? 'Play flow' : 'Pause flow'),
          ),
        VisualInputControl(
          input: model.inputs.speed,
          viewModel: widget.viewModel,
          minimum: 0,
          maximum: 10,
        ),
      ],
    );
  }
}

/// One animation listenable repaints only this canvas, never the widget tree.
/// Six cached streamlines and 24 dots. Paints/paths are reused between frames;
/// the only per-dot temporary is an Offset passed to Canvas.drawCircle.
class ReynoldsPainter extends CustomPainter {
  ReynoldsPainter({
    required this.phase,
    required this.irregularity,
    required this.ink,
    required this.accent,
  }) : _line = (Paint()
         ..color = ink
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1),
       _dot = (Paint()..color = accent),
       super(repaint: phase);

  static const particleCount = 24;
  static const laneCount = 6;
  final Animation<double> phase;
  final double irregularity;
  final Color ink;
  final Color accent;
  final Paint _line;
  final Paint _dot;
  final List<Path> _paths = [];
  Size? _cachedSize;

  // Pure drawing geometry, deliberately unrelated to the Reynolds equation.
  double laneY(int lane, double x) =>
      (lane + 1) / (laneCount + 1) +
      irregularity *
          (.035 * math.sin(x * math.pi * 6 + lane * .8) +
              .018 * math.sin(x * math.pi * 14 + lane * 2));

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedSize != size) {
      _paths.clear();
      for (var lane = 0; lane < laneCount; lane++) {
        final path = Path();
        for (var step = 0; step <= 64; step++) {
          final x = step / 64;
          if (step == 0) {
            path.moveTo(0, laneY(lane, x) * size.height);
          } else {
            path.lineTo(x * size.width, laneY(lane, x) * size.height);
          }
        }
        _paths.add(path);
      }
      _cachedSize = size;
    }
    for (final path in _paths) {
      canvas.drawPath(path, _line);
    }
    for (var dot = 0; dot < particleCount; dot++) {
      final lane = dot ~/ 4;
      final x = ((dot % 4) / 4 + phase.value + lane * .03) % 1;
      canvas.drawCircle(
        Offset(x * size.width, laneY(lane, x) * size.height),
        3,
        _dot,
      );
    }
  }

  @override
  bool shouldRepaint(ReynoldsPainter oldDelegate) =>
      irregularity != oldDelegate.irregularity ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent ||
      phase != oldDelegate.phase;
}
