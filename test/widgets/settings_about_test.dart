import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show pumpApp;

void main() {
  testWidgets('About shows developer and embedded build metadata', (
    tester,
  ) async {
    await pumpApp(tester, location: '/settings');
    expect(find.text('RobMac Software'), findsOneWidget);
    final version = appBuildName == null
        ? 'Version unavailable'
        : 'Version $appBuildName${appBuildNumber == null ? '' : ' ($appBuildNumber)'}';
    expect(find.text(version), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('licenses open and return accessibly at scale $scale', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: '/settings',
        size: const Size(320, 800),
        textScale: scale,
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.scrollUntilVisible(
          find.text('Open-source licenses'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final button = find.widgetWithText(TextButton, 'Open-source licenses');
        expect(
          tester.getSemantics(button),
          matchesSemantics(
            label: 'Open-source licenses',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.byType(LicensePage), findsOneWidget);
        expect(find.text('Engineering Toolkit'), findsWidgets);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(LicensePage), findsNothing);
        await tester.ensureVisible(find.text('Privacy Policy'));
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
