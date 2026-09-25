import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/calculators/domain/initial_catalog.dart';
import 'features/preferences/local_preferences_repository.dart';
import 'features/preferences/preferences_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final registry = createInitialCatalog();
  final preferences = await PreferencesController.restore(
    LocalPreferencesRepository(),
    registry,
  );
  runApp(EngineeringToolkitApp(registry: registry, preferences: preferences));
}
