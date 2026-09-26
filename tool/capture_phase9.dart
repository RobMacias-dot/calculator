// Regenerable static review evidence; outputs stay ignored under build/.
// flutter test tool/capture_phase9.dart --update-goldens
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test/support/memory_preferences_repository.dart';
import '../test/widgets/app_test.dart' show pumpApp;
import '../test/widgets/calculator_test.dart' show enterInput, pressCalculate;
import 'capture_phase3.dart' show loadReviewFonts;

void main() {
  setUpAll(loadReviewFonts);
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('release surfaces ${theme.name}', (tester) async {
      final registry = createInitialCatalog();
      final preferences = await PreferencesController.restore(
        MemoryPreferencesRepository(Preferences(themeMode: theme)),
        registry,
      );
      await pumpApp(tester, registry: registry, preferences: preferences);
      final router = GoRouter.of(
        tester.element(find.text('Engineering Toolkit')),
      );
      Future<void> capture(String page) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../build/phase9-${theme.name}-$page.png'),
        );
      }

      await capture('home');
      await tester.enterText(find.byType(TextField), 'voltage');
      await capture('search');
      await tester.tap(find.byTooltip('Clear search'));
      await tester.tap(find.byTooltip('Tools'));
      await capture('tools');
      await tester.tap(find.byTooltip('Settings'));
      await capture('settings');
      router.go('/calculator/voltage-divider');
      await tester.pumpAndSettle();
      for (final entry in {
        'voltage': '12',
        'r1': '1000',
        'r2': '2000',
      }.entries) {
        await enterInput(tester, entry.key, entry.value);
      }
      await pressCalculate(tester);
      await capture('result');
      await tester.ensureVisible(find.text('Learn visually'));
      await tester.tap(find.text('Learn visually'));
      await capture('visual');
    });
  }
}
