import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../domain/engines/ideal_gas_law.dart';
import '../calculator_view_model.dart';
import 'visual_animation_lifecycle.dart';
import 'visual_controls.dart';
import 'visual_models.dart';
import 'visual_scene.dart';

class IdealGasVisual extends StatefulWidget {
  const IdealGasVisual({
    super.key,
    required this.model,
    required this.viewModel,
    this.showInputControls = true,
  });
  final IdealGasVisualizationModel model;
  final CalculatorViewModel viewModel;
  final bool showInputControls;

  @override
  State<IdealGasVisual> createState() => _IdealGasVisualState();
}

class _IdealGasVisualState extends State<IdealGasVisual>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        VisualAnimationLifecycle<IdealGasVisual> {
  @override
  Duration get visualPeriod => Duration(
    milliseconds: (10000 - 8000 * widget.model.motionIntensity).round(),
  );

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
            key: const ValueKey('ideal-gas-canvas'),
            painter: IdealGasPainter(
              phase: visualClock,
              chamberFraction: model.chamberFraction,
              particleCount: model.particleCount,
              ink: colors.onSurfaceVariant,
              accent: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Quantitative labels stay outside the animated canvas, fully scalable.
        for (final variable in GasVariable.values)
          Text(
            '${_symbol(variable)} · ${variable.name}: ${model.label(variable)}'
            '${variable == model.inputs.solved ? ' (calculated)' : ''}',
            style: variable == model.inputs.solved
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.bodyLarge,
          ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'More volume raises the piston; more gas adds dots; higher temperature '
          'increases motion. Piston size, dot count, speed and arrangement use '
          'bounded educational scales, not molecular simulation.',
        ),
        Text(
          'Temperature motion cue: ${(model.motionIntensity * 100).round()}% '
          'of the illustrative scale.',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (motionReduced)
          const Text(
            'Reduce Motion is on. The static chamber, particles and '
            'temperature cue preserve the same information.',
          )
        else
          OutlinedButton.icon(
            onPressed: () => setState(() {
              motionPaused = !motionPaused;
              syncVisualMotion();
            }),
            icon: Icon(
              motionPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(motionPaused ? 'Play particles' : 'Pause particles'),
          ),
        if (widget.showInputControls)
          for (final input in model.inputs.inputs)
            VisualInputControl(
              input: input,
              viewModel: widget.viewModel,
              minimum: _range(input.input.id).$1,
              maximum: _range(input.input.id).$2,
            ),
      ],
    );
  }
}

String _symbol(GasVariable variable) => switch (variable) {
  GasVariable.pressure => 'P',
  GasVariable.volume => 'V',
  GasVariable.amount => 'n',
  GasVariable.temperature => 'T',
};

// SI convenience ranges: 10–500 kPa, 1–100 L, 0.1–5 mol, 100–1000 K.
// Positive endpoints respect the existing domain; manual values remain unlimited
// by these presentation choices. VisualInputControl preserves selected units.
(double, double) _range(String id) => switch (id) {
  'pressure' => (10000, 500000),
  'volume' => (.001, .1),
  'amount' => (.1, 5),
  'temperature' => (100, 1000),
  _ => throw ArgumentError.value(id),
};

/// Gas-specific immutable seed table, allocated once. Integer travel cycles make
/// the triangle-wave reflection seamless at the repeating clock boundary.
/// Reflection is drawing geometry; wall contacts never calculate pressure.
abstract final class IdealGasParticles {
  static final seeds =
      List<({double x, double y, int dx, int dy})>.unmodifiable(
        List.generate(
          36,
          (i) => (
            x: ((i * 37 + 11) % 101) / 101,
            y: ((i * 61 + 29) % 103) / 103,
            dx: i.isEven ? 1 : -1,
            dy: i % 3 == 0 ? 2 : -1,
          ),
        ),
      );

  static double _reflect(double value) => 1 - ((value % 2) - 1).abs();

  static Offset position(int index, double phase, Rect region) {
    final seed = seeds[index];
    return Offset(
      region.left + _reflect(seed.x + phase * 2 * seed.dx) * region.width,
      region.top + _reflect(seed.y + phase * 2 * seed.dy) * region.height,
    );
  }
}

/// One repaint listenable and three cached paints. No lists, paths or paints are
/// allocated per frame; only the small Offset values required by Canvas.
class IdealGasPainter extends CustomPainter {
  IdealGasPainter({
    required this.phase,
    required this.chamberFraction,
    required this.particleCount,
    required this.ink,
    required this.accent,
  }) : _wall = (Paint()
         ..color = ink
         ..style = PaintingStyle.stroke
         ..strokeWidth = 2),
       _piston = (Paint()..color = ink),
       _dot = (Paint()..color = accent),
       super(repaint: phase);

  final Animation<double> phase;
  final double chamberFraction;
  final int particleCount;
  final Color ink, accent;
  final Paint _wall, _piston, _dot;
  Size? _cachedSize;
  late Rect _container, _chamber, _particles, _pistonRect, _rod;
  double _radius = 0;

  Rect chamberFor(Size size) => Rect.fromLTRB(
    size.width * .15,
    size.height * (.9 - .8 * chamberFraction),
    size.width * .85,
    size.height * .9,
  );

  Rect particleRegionFor(Size size) {
    final chamber = chamberFor(size);
    final inset = math.min(8.0, math.min(chamber.width, chamber.height) / 4);
    return chamber.deflate(inset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    if (_cachedSize != size) {
      _cachedSize = size;
      _container = Rect.fromLTRB(
        size.width * .15,
        size.height * .1,
        size.width * .85,
        size.height * .9,
      );
      _chamber = chamberFor(size);
      _particles = particleRegionFor(size);
      _radius = math.min(3.0, math.min(_chamber.width, _chamber.height) / 8);
      final thickness = math.min(3.0, size.height * .02);
      _pistonRect = Rect.fromLTRB(
        _chamber.left,
        _chamber.top - thickness,
        _chamber.right,
        _chamber.top,
      );
      _rod = Rect.fromLTRB(
        size.width * .49,
        size.height * .035,
        size.width * .51,
        _chamber.top - thickness,
      );
    }
    canvas.drawRect(_container, _wall);
    canvas.drawRect(_rod, _piston);
    canvas.drawRect(_pistonRect, _piston);
    for (var i = 0; i < particleCount; i++) {
      canvas.drawCircle(
        IdealGasParticles.position(i, phase.value, _particles),
        _radius,
        _dot,
      );
    }
  }

  @override
  bool shouldRepaint(IdealGasPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      chamberFraction != oldDelegate.chamberFraction ||
      particleCount != oldDelegate.particleCount ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent;
}
