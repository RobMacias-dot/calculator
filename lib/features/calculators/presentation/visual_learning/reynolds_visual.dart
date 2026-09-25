import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../calculator_view_model.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_motion.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  bool _paused = false;
  bool _reduced = false;
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = reduceVisualMotion(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  @override
  void didUpdateWidget(ReynoldsVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (!mounted) return;
    setState(() {
      final features = View.of(context)
          .platformDispatcher
          .accessibilityFeatures;
      _reduced = features.reduceMotion || features.disableAnimations;
      _syncMotion();
    });
  }

  void _syncMotion() {
    final running =
        !_paused &&
        !_reduced &&
        _visible &&
        _foreground &&
        widget.model.hasFlow;
    if (running && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!running && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisualScene(
          summary: model.summary,
          child: CustomPaint(
            key: const ValueKey('reynolds-canvas'),
            painter: ReynoldsPainter(
              phase: _clock,
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
        if (_reduced)
          const Text(
            'Reduce Motion is on. Static paths preserve the same visual information.',
          )
        else if (!model.hasFlow)
          const Text('Zero speed: the flow illustration is stationary.')
        else
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _paused = !_paused;
              _syncMotion();
            }),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(_paused ? 'Play flow' : 'Pause flow'),
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
