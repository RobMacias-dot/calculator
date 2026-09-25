import 'package:engineering_toolkit/app/app.dart';
import 'package:engineering_toolkit/features/calculators/domain/calculator_registry.dart';

import '../support/phase3_catalog.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_toolkit/features/preferences/preferences_controller.dart';

import '../support/memory_preferences_repository.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  String? location,
  Size size = const Size(430, 932),
  double textScale = 1,
  PreferencesController? preferences,
  CalculatorRegistry? registry,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    EngineeringToolkitApp(
      registry: registry ?? createPhase3Catalog(),
      preferences:
          preferences ??
          await PreferencesController.restore(
            MemoryPreferencesRepository(),
            registry ?? createPhase3Catalog(),
          ),
      initialLocation: location,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home to category to calculator and back', (tester) async {
    await pumpApp(tester);
    expect(find.text('Engineering Toolkit'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Electrical'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Electrical'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ohm’s Law'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsNothing);
    expect(find.text('I = V / R'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Electrical'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Engineering Toolkit'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Engineering Toolkit'), findsOneWidget);
  });

  testWidgets('search filters and recovers from an empty result', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pumpAndSettle();
    expect(find.text('No tools found'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Reynolds');
    await tester.pumpAndSettle();
    expect(find.text('Reynolds Number'), findsOneWidget);
    expect(find.text('Ohm’s Law'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Engineering fields'), findsOneWidget);
  });

  testWidgets('system Back returns through calculator and category', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(
      find.text('Electrical'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Electrical'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ohm’s Law'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Electrical'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Engineering Toolkit'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Engineering Toolkit'), findsOneWidget);
  });

  testWidgets('navigation supports favorites, tools and appearance', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Your favorites'), findsOneWidget);
    await tester.tap(find.byTooltip('Tools'));
    await tester.pumpAndSettle();
    expect(find.text('Explore tools'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownMenu<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Engineering Toolkit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final location in [
    '/category/unknown',
    '/calculator/unknown',
    '/missing',
  ]) {
    testWidgets('invalid route $location offers recovery', (tester) async {
      await pumpApp(tester, location: location);
      expect(find.text('Page not found'), findsOneWidget);
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
      expect(find.text('Engineering Toolkit'), findsOneWidget);
    });
  }

  testWidgets('direct calculator link and empty category work', (tester) async {
    await pumpApp(tester, location: '/calculator/ipv4-subnet');
    expect(find.text('IPv4 / CIDR Subnet'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Networking'), findsOneWidget);
  });

  testWidgets('Mathematics displays an honest empty catalog', (tester) async {
    await pumpApp(tester, location: '/category/mathematics');
    expect(find.text('0 tools'), findsOneWidget);
    expect(find.textContaining('New possibilities ahead'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(1024, 1366),
  ]) {
    testWidgets('responsive Home and calculator at $size with 200% text', (
      tester,
    ) async {
      await pumpApp(tester, size: size, textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Thermodynamics'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Thermodynamics'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ideal Gas Law'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ideal Gas Law'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Inputs'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keyboard leaves search scrollable on a small phone', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'ohm');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ohm’s Law'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home meets labeled target and touch target guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpApp(tester);
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Home'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });
}
