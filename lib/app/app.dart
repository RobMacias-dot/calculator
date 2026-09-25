import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/app_theme.dart';
import '../features/calculators/domain/calculator_registry.dart';
import '../features/home/presentation/home_view_model.dart';
import '../features/preferences/preferences_controller.dart';
import 'router/app_router.dart';

/// Composition root: dependencies and their lifetime are explicit.
class EngineeringToolkitApp extends StatefulWidget {
  const EngineeringToolkitApp({
    super.key,
    required this.registry,
    required this.preferences,
    this.initialLocation,
  });
  final CalculatorRegistry registry;
  final PreferencesController preferences;
  final String? initialLocation;

  @override
  State<EngineeringToolkitApp> createState() => _EngineeringToolkitAppState();
}

class _EngineeringToolkitAppState extends State<EngineeringToolkitApp> {
  late final HomeViewModel _home;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _home = HomeViewModel(widget.registry);
    _router = createAppRouter(
      registry: widget.registry,
      home: _home,
      preferences: widget.preferences,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _home.dispose();
    widget.preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: widget.preferences.themeMode,
    builder: (context, mode, _) => MaterialApp.router(
      title: 'Engineering Toolkit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: _router,
    ),
  );
}
