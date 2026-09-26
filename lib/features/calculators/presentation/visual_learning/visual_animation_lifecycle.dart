import 'package:flutter/material.dart';

import 'visual_motion.dart';

/// Identical presentation-only gating for Reynolds and Ideal Gas. The scene
/// supplies usefulness/period; this mixin knows nothing about particles or gas.
/// Visibility is checked after layout/scroll/metrics, never on animation ticks.
mixin VisualAnimationLifecycle<T extends StatefulWidget>
    on State<T>, TickerProvider, WidgetsBindingObserver {
  bool get motionUseful => true;
  Duration get visualPeriod => const Duration(seconds: 4);
  Duration? _period;
  late final AnimationController visualClock;
  bool motionPaused = false;
  bool motionReduced = false;
  bool _visible = true;
  bool _foreground = true;
  final visualSceneKey = GlobalKey();
  ScrollableState? _scrollable;
  bool _inViewport = true;
  bool _visibilityScheduled = false;

  @override
  void initState() {
    super.initState();
    visualClock = AnimationController(vsync: this, duration: visualPeriod);
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    motionReduced = reduceVisualMotion(context);
    _visible = TickerMode.valuesOf(context).enabled;
    final scrollable = Scrollable.maybeOf(context);
    if (_scrollable?.position != scrollable?.position) {
      _scrollable?.position.removeListener(_scheduleVisibility);
      _scrollable = scrollable;
      _scrollable?.position.addListener(_scheduleVisibility);
    }
    _scheduleVisibility();
    syncVisualMotion();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncVisualMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    syncVisualMotion();
  }

  @override
  void didChangeMetrics() => _scheduleVisibility();

  // Scroll notifications run before layout. Inspect the scene/viewport once
  // after layout, never on animation ticks and without rebuilding the form.
  void _scheduleVisibility() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted) return;
      final scene = visualSceneKey.currentContext?.findRenderObject();
      final viewport = _scrollable?.context.findRenderObject();
      _inViewport =
          scene is! RenderBox ||
          viewport is! RenderBox ||
          (scene.localToGlobal(Offset.zero) & scene.size).overlaps(
            viewport.localToGlobal(Offset.zero) & viewport.size,
          );
      syncVisualMotion();
    });
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (!mounted) return;
    setState(() {
      motionReduced = reduceVisualMotion(context);
      syncVisualMotion();
    });
  }

  void syncVisualMotion() {
    final running =
        !motionPaused &&
        !motionReduced &&
        _visible &&
        _inViewport &&
        _foreground &&
        motionUseful;
    if (running && (!visualClock.isAnimating || _period != visualPeriod)) {
      _period = visualPeriod;
      visualClock.repeat(period: _period);
    } else if (!running && visualClock.isAnimating) {
      visualClock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollable?.position.removeListener(_scheduleVisibility);
    visualClock.dispose();
    super.dispose();
  }
}
