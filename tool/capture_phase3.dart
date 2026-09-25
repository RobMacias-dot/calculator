// Run with: flutter test tool/capture_phase3.dart --update-goldens
// These review artifacts are generated on demand, not versioned golden baselines.
import 'dart:io';
import 'dart:convert';

import '../test/support/phase3_catalog.dart';

import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/memory_preferences_repository.dart';
import '../test/widgets/app_test.dart' show pumpApp;
import '../test/widgets/calculator_test.dart' show enterInput, pressCalculate;

Future<void> loadReviewFonts() async {
  final config = File('.dart_tool/package_config.json');
  final packages =
      (jsonDecode(await config.readAsString())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;
  final flutter = packages.cast<Map<String, dynamic>>().singleWhere(
    (package) => package['name'] == 'flutter',
  );
  final root = flutter['rootUri'] as String;
  final fonts = config.absolute.uri
      .resolve(root.endsWith('/') ? root : '$root/')
      .resolve('../../bin/cache/artifacts/material_fonts/');
  for (final entry in {
    'Roboto': 'roboto-regular.ttf',
    'MaterialIcons': 'materialicons-regular.otf',
  }.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        File.fromUri(fonts.resolve(entry.value))
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    await loader.load();
  }
}

void main() {
  setUpAll(loadReviewFonts);
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('capture ${mode.name} product screens', (tester) async {
      final preferences = await PreferencesController.restore(
        MemoryPreferencesRepository(
          Preferences(
            themeMode: mode,
            favoriteCalculatorIds: ['ohms-law'],
            recentCalculatorIds: ['ohms-law'],
          ),
        ),
        createPhase3Catalog(),
      );
      await pumpApp(tester, preferences: preferences);
      Future<void> capture(String page) async {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../build/phase3-${mode.name}-$page.png'),
        );
      }

      await capture('home');
      for (final destination in ['Favorites', 'Tools', 'Settings']) {
        await tester.tap(find.byTooltip(destination));
        await tester.pumpAndSettle();
        await capture(destination.toLowerCase());
      }
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ohm’s Law'));
      await tester.pumpAndSettle();
      await enterInput(tester, 'voltage', '220');
      await enterInput(tester, 'resistance', '10');
      await pressCalculate(tester);
      await capture('result');
    });
  }
}
