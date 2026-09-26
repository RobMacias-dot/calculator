// Static layout review artifacts, not animation-frame goldens.
// flutter test tool/capture_phase8.dart --update-goldens
import 'package:engineering_toolkit/features/calculators/presentation/result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/widgets/playground_test.dart' as playground;
import 'capture_phase3.dart' show loadReviewFonts;

void main() {
  setUpAll(loadReviewFonts);
  for (final tablet in [false, true]) {
    testWidgets('Playground static review tablet=$tablet', (tester) async {
      await playground.openPlayground(
        tester,
        'ideal-gas-law',
        size: tablet ? const Size(1024, 768) : const Size(430, 932),
        theme: tablet ? ThemeMode.dark : ThemeMode.light,
      );
      await playground.fill(tester, playground.playgroundSamples[2].values);
      if (tablet) {
        await tester.ensureVisible(find.text('Interactive Playground'));
      } else {
        await tester.ensureVisible(find.byType(CalculationResultSummary));
      }
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../build/phase8-${tablet ? 'tablet' : 'phone'}.png'),
      );
    });
  }
}
