import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_tile.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_preferences_repository.dart';
import 'app_test.dart' show pumpApp;

void main() {
  testWidgets(
    'capability text and semantics follow all existing catalog flags',
    (tester) async {
      final registry = createInitialCatalog();
      final preferences = await PreferencesController.restore(
        MemoryPreferencesRepository(),
        registry,
      );
      addTearDown(preferences.dispose);
      final semantics = tester.ensureSemantics();
      for (final d in registry.all) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CalculatorTile(
                definition: d,
                preferences: preferences,
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final capability in {
          'Learn visually': d.supportsVisualLearning,
          'Explore interactively': d.supportsPlayground,
        }.entries) {
          expect(
            find.textContaining(capability.key),
            capability.value ? findsOneWidget : findsNothing,
            reason: d.id,
          );
          expect(
            find.bySemanticsLabel(RegExp(capability.key)),
            capability.value ? findsOneWidget : findsNothing,
            reason: d.id,
          );
        }
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'concept result opens, returns with query and restores quick access',
    (tester) async {
      final registry = createInitialCatalog();
      final repository = MemoryPreferencesRepository();
      final preferences = await PreferencesController.restore(
        repository,
        registry,
      );
      await pumpApp(tester, registry: registry, preferences: preferences);
      await tester.enterText(find.byType(TextField), '  F=ma  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.byType(CalculatorTile), findsOneWidget);
      await tester.tap(find.byTooltip('Add Newton’s Second Law to favorites'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Newton’s Second Law'));
      await tester.pumpAndSettle();
      expect(find.text('Calculate'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '  F=ma  ',
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Recent tools'), findsOneWidget);
      expect(preferences.recents.single.id, 'newtons-second-law');
      await preferences.pendingWrites;
      final restored = await PreferencesController.restore(
        repository,
        registry,
      );
      addTearDown(restored.dispose);
      expect(restored.favorites.single.id, 'newtons-second-law');
      expect(restored.recents.single.id, 'newtons-second-law');
      await tester.tap(find.byTooltip('Favorites'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('Remove Newton’s Second Law from favorites'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Make room for your go-to tools'), findsOneWidget);
    },
  );

  testWidgets('Tab reaches clear and calculator; Enter opens the result', (
    tester,
  ) async {
    await pumpApp(tester, registry: createInitialCatalog());
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Search tools or fields')),
      findsOneWidget,
    );
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.enterText(find.byType(TextField), 'F=ma');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.context!.widget, isA<Focus>());
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Engineering fields'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'F=ma');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Calculate'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    semantics.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('discovery at 320px and 200% text in ${mode.name}', (
      tester,
    ) async {
      final registry = createInitialCatalog();
      final preferences = await PreferencesController.restore(
        MemoryPreferencesRepository(Preferences(themeMode: mode)),
        registry,
      );
      final semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        registry: registry,
        preferences: preferences,
        size: const Size(320, 900),
        textScale: 2,
      );
      await tester.enterText(find.byType(TextField), 'F=ma');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(CalculatorTile),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Learn visually')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Explore interactively')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CalculatorTile)).width,
        lessThanOrEqualTo(320),
      );
      expect(
        tester
            .getSize(find.byTooltip('Add Newton’s Second Law to favorites'))
            .shortestSide,
        greaterThanOrEqualTo(48),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.scrollUntilVisible(
        find.byType(TextField),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'unmatched concept');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('No tools found'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No tools found'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
