// Review artifacts only: flutter test tool/capture_phase4.dart --update-goldens
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/memory_preferences_repository.dart';
import '../test/widgets/app_test.dart' show pumpApp;
import '../test/widgets/calculator_test.dart' show enterInput, pressCalculate;
import 'capture_phase3.dart' show loadReviewFonts;

void main() {
  setUpAll(loadReviewFonts);
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final sample in [
      (id: 'quadratic-equation', values: {'a': '1', 'b': '2', 'c': '5'}),
      (id: 'series-resistance', values: {'r1': '10', 'r2': '20'}),
      (id: 'electrical-energy', values: {'power': '2000', 'time': '10800'}),
      (
        id: 'bernoulli-basic',
        values: {
          'pressure1': '100000',
          'density': '1000',
          'speed1': '2',
          'speed2': '4',
          'height1': '3',
          'height2': '1',
        },
      ),
    ]) {
      testWidgets('review ${sample.id} in ${mode.name}', (tester) async {
        final registry = createInitialCatalog();
        final preferences = await PreferencesController.restore(
          MemoryPreferencesRepository(Preferences(themeMode: mode)),
          registry,
        );
        await pumpApp(
          tester,
          registry: registry,
          preferences: preferences,
          location: '/calculator/${sample.id}',
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            '../build/phase4-${mode.name}-${sample.id}-inputs.png',
          ),
        );
        for (final entry in sample.values.entries) {
          await enterInput(tester, entry.key, entry.value);
        }
        await pressCalculate(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            '../build/phase4-${mode.name}-${sample.id}-result.png',
          ),
        );
      });
    }
  }
}
