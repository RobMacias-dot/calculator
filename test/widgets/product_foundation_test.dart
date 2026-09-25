import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';
import 'package:engineering_toolkit/app/app.dart';

import '../support/phase3_catalog.dart';

import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_preferences_repository.dart';
import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;

void main() {
  testWidgets(
    'favorite from calculator survives remount and can be removed from Favorites',
    (tester) async {
      final repository = MemoryPreferencesRepository();
      final preferences = await PreferencesController.restore(
        repository,
        createPhase3Catalog(),
      );
      await pumpApp(
        tester,
        location: '/calculator/ohms-law',
        preferences: preferences,
      );
      await tester.tap(find.byTooltip('Add Ohm’s Law to favorites'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove Ohm’s Law from favorites'), findsOneWidget);
      await preferences.pendingWrites;
      await tester.pumpWidget(const SizedBox());
      final restored = await PreferencesController.restore(
        repository,
        createPhase3Catalog(),
      );
      await pumpApp(tester, preferences: restored);
      expect(find.text('Recent tools'), findsOneWidget);
      await tester.tap(find.byTooltip('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Ohm’s Law'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove Ohm’s Law from favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Make room for your go-to tools'), findsOneWidget);
      await tester.tap(find.text('Explore tools'));
      await tester.pumpAndSettle();
      expect(find.text('All fields'), findsOneWidget);
      await restored.pendingWrites;
      expect(repository.value.favoriteCalculatorIds, isEmpty);
    },
  );

  testWidgets('theme switches immediately and restores on the first frame', (
    tester,
  ) async {
    final repository = MemoryPreferencesRepository();
    final preferences = await PreferencesController.restore(
      repository,
      createPhase3Catalog(),
    );
    await pumpApp(tester, location: '/settings', preferences: preferences);
    for (final label in ['Dark', 'Light', 'System']) {
      await tester.tap(find.byType(DropdownMenu<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(preferences.themeMode.value.name, label.toLowerCase());
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        label == 'Dark' ? Brightness.dark : Brightness.light,
      );
    }
    preferences.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    await preferences.pendingWrites;
    await tester.pumpWidget(const SizedBox());
    final restored = await PreferencesController.restore(
      repository,
      createPhase3Catalog(),
    );
    await tester.pumpWidget(
      EngineeringToolkitApp(
        registry: createPhase3Catalog(),
        preferences: restored,
      ),
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Engineering Toolkit'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets(
    'search opens calculator, dismisses focus and adds Recent tools',
    (tester) async {
      await pumpApp(tester);
      expect(find.text('Recent tools'), findsNothing);
      await tester.enterText(find.byType(TextField), '  ÓHM  law ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ohm’s Law'));
      await tester.pumpAndSettle();
      expect(find.text('Calculate'), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Recent tools'), findsOneWidget);
      expect(find.text('Ohm’s Law'), findsOneWidget);
    },
  );

  testWidgets(
    'copy uses the standard clipboard and reports success; failures stay usable',
    (tester) async {
      String? copied;
      var fail = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            if (fail) throw PlatformException(code: 'unavailable');
            copied =
                (call.arguments as Map<dynamic, dynamic>)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(tester, location: '/calculator/ohms-law');
      await enterInput(tester, 'voltage', '220');
      await enterInput(tester, 'resistance', '10');
      await pressCalculate(tester);
      await tester.ensureVisible(find.byTooltip('Copy result'));
      await tester.tap(find.byTooltip('Copy result'));
      await tester.pumpAndSettle();
      expect(copied, 'Ohm’s Law\nI = 22 A\nI = 220 V / 10 Ω');
      expect(find.text('Result copied'), findsOneWidget);
      fail = true;
      await tester.tap(find.byTooltip('Copy result'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not copy. Select the result to copy it.'),
        findsOneWidget,
      );
      expect(find.text('22 A'), findsOneWidget);
    },
  );

  testWidgets(
    'Tools filters all fields, composes search and opens category calculators',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Tools'));
      await tester.pumpAndSettle();
      final filter = find.byType(DropdownButtonFormField<CalculatorCategory?>);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electrical').last);
      await tester.pumpAndSettle();
      expect(find.text('Ohm’s Law'), findsOneWidget);
      expect(find.text('Reynolds Number'), findsNothing);
      await tester.enterText(find.byType(TextField), 'gas');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('No tools found'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add Ohm’s Law to favorites'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ohm’s Law'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove Ohm’s Law from favorites'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Electrical'), findsOneWidget);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('All fields').last);
      await tester.pumpAndSettle();
      expect(find.text('5 tools · Offline catalog'), findsOneWidget);
      expect(find.text('Ohm’s Law'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Reynolds Number'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Reynolds Number'), findsOneWidget);
    },
  );

  testWidgets(
    'storage failure keeps session usable and Settings shows a nontechnical notice',
    (tester) async {
      final repository = MemoryPreferencesRepository()..failWrite = true;
      final preferences = await PreferencesController.restore(
        repository,
        createPhase3Catalog(),
      );
      await pumpApp(tester, location: '/settings', preferences: preferences);
      preferences.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Saving preferences is temporarily unavailable'),
        findsOneWidget,
      );
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.dark,
      );
      repository.failWrite = false;
      preferences.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Saving preferences is temporarily unavailable'),
        findsNothing,
      );
      expect(repository.value.themeMode, ThemeMode.light);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Phase 3 screens at 320px and 200% text in ${mode.name}', (
      tester,
    ) async {
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
      await pumpApp(
        tester,
        preferences: preferences,
        size: const Size(320, 568),
        textScale: 2,
      );
      for (final tab in ['Favorites', 'Tools', 'Settings', 'Home']) {
        await tester.tap(find.byTooltip(tab));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
    });
    testWidgets(
      'catalog and favorite controls meet accessibility guidelines in ${mode.name}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final preferences = await PreferencesController.restore(
            MemoryPreferencesRepository(Preferences(themeMode: mode)),
            createPhase3Catalog(),
          );
          await pumpApp(
            tester,
            location: '/category/electrical',
            preferences: preferences,
          );
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
