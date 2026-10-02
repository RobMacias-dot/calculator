import 'package:engineering_toolkit/features/calculators/domain/calculator_category.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/calculator_screen.dart';
import 'package:engineering_toolkit/features/calculators/presentation/playground_screen.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';
import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/memory_preferences_repository.dart';
import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;
import 'playground_test.dart' show playgroundSamples;

void main() {
  testWidgets('every production definition resolves through its actual route', (
    tester,
  ) async {
    final registry = createInitialCatalog();
    await pumpApp(tester, registry: registry);
    final router = GoRouter.of(
      tester.element(find.text('Engineering Toolkit')),
    );
    final paths = <String>{};
    for (final definition in registry.all) {
      final path = router.namedLocation(
        'calculator',
        pathParameters: {'calculatorId': definition.id},
      );
      expect(paths.add(path), isTrue);
      expect(registry.search(definition.name), contains(definition));
      expect(registry.inCategory(definition.category), contains(definition));
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CalculatorScreen>(find.byType(CalculatorScreen))
            .definition,
        same(definition),
      );
      expect(tester.takeException(), isNull, reason: path);
    }
    for (final category in CalculatorCategory.values) {
      router.go('/category/${category.id}');
      await tester.pumpAndSettle();
      expect(find.text(category.label), findsOneWidget);
      expect(find.text('Page not found'), findsNothing);
    }
  });

  testWidgets('invalid routes offer a working escape to Home', (tester) async {
    await pumpApp(tester, registry: createInitialCatalog());
    final router = GoRouter.of(
      tester.element(find.text('Engineering Toolkit')),
    );
    for (final path in [
      '/calculator/obsolete',
      '/playground/obsolete',
      '/playground/ohms-law',
      '/category/obsolete',
      '/unknown',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text('Page not found'), findsOneWidget, reason: path);
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
      expect(find.text('Engineering Toolkit'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: path);
    }
  });

  testWidgets(
    'direct Playgrounds record recent tools and persist their order',
    (tester) async {
      final registry = createInitialCatalog();
      final repository = MemoryPreferencesRepository();
      final preferences = await PreferencesController.restore(
        repository,
        registry,
      );
      await pumpApp(tester, registry: registry, preferences: preferences);
      final router = GoRouter.of(
        tester.element(find.text('Engineering Toolkit')),
      );
      for (final sample in playgroundSamples) {
        router.go('/playground/${sample.id}');
        await tester.pumpAndSettle();
        expect(find.byType(PlaygroundScreen), findsOneWidget);
        expect(preferences.recents.firstOrNull?.id, sample.id);
        await preferences.pendingWrites;
        final writes = repository.writes;
        // Rebuild, then open the same calculator through the direct-link back
        // fallback. Neither should duplicate the most recent item or write.
        await tester.pump();
        await tester.ensureVisible(find.byTooltip('Back to calculator'));
        await tester.tap(find.byTooltip('Back to calculator'));
        await tester.pumpAndSettle();
        await preferences.pendingWrites;
        expect(repository.writes, writes);
        expect(preferences.recents.where((d) => d.id == sample.id).length, 1);
      }
      await preferences.pendingWrites;
      await tester.pumpWidget(const SizedBox());
      final restored = await PreferencesController.restore(
        repository,
        registry,
      );
      expect(
        restored.recents.map((tool) => tool.id),
        playgroundSamples.reversed.take(5).map((sample) => sample.id),
      );
      restored.dispose();
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(430, 932),
    const Size(1024, 768),
  ]) {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('full catalog shell $size ${theme.name} at 200% text', (
        tester,
      ) async {
        final registry = createInitialCatalog();
        final preferences = await PreferencesController.restore(
          MemoryPreferencesRepository(Preferences(themeMode: theme)),
          registry,
        );
        await pumpApp(
          tester,
          registry: registry,
          preferences: preferences,
          size: size,
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: 'Home');
        final router = GoRouter.of(
          tester.element(find.text('Engineering Toolkit')),
        );
        await tester.enterText(find.byType(TextField), 'volt');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Voltage Divider'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Voltage Divider'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byType(TextField),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'no such tool');
        await tester.pumpAndSettle();
        expect(find.text('No tools found'), findsOneWidget);
        await tester.tap(find.byTooltip('Clear search'));
        await tester.pumpAndSettle();
        for (final tab in ['Tools', 'Favorites', 'Settings', 'Home']) {
          await tester.tap(find.byTooltip(tab));
          await tester.pumpAndSettle();
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }
        router.go('/calculator/voltage-divider');
        await tester.pumpAndSettle();
        for (final entry in playgroundSamples.first.values.entries) {
          await enterInput(tester, entry.key, entry.value);
        }
        await pressCalculate(tester);
        expect(find.text('8 V'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Calculator');
      });
    }
  }
}
