import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:engineering_toolkit/features/calculators/presentation/playground_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'visual_learning_test.dart' show openVisual;
import '../support/visual_learning_samples.dart' show visualVm;

void main() {
  testWidgets('Newton slider speech is bounded without rounding calculations', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await openVisual(tester, 'newtons-second-law', {
        'mass': '2.123456789',
        'acceleration': '3',
      });
      final vm = tester
          .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
          .viewModel;
      final originalReport = vm.result;
      expect(find.text('Mass: 2.1235 kg'), findsOneWidget);
      expect(
        mapVisualModel(originalReport!)!.summary,
        contains('Mass 2.1235 kg.'),
      );
      final massFinder = find.byKey(const ValueKey('visual-control-mass'));
      await tester.ensureVisible(massFinder);
      await tester.pumpAndSettle();
      final mass = tester.widget<Slider>(massFinder);
      for (final sample in <double, String>{
        2: '2',
        2.5: '2.5',
        2.125: '2.125',
        2.123456789: '2.1235',
        0.000000123456789: '1.2346e-7',
      }.entries) {
        expect(
          mass.semanticFormatterCallback!(sample.key),
          '${sample.value} kg',
        );
      }
      final massData = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.getSemanticsData())
          .singleWhere((data) => data.value.endsWith(' kg'));
      expect(massData.value, '2.1235 kg');
      expect(massData.increasedValue, '7.1235 kg');
      expect(massData.decreasedValue, '0 kg');
      expect(vm.valueFor('mass'), '2.123456789');
      expect(vm.result, same(originalReport));
      expect(vm.result!.value, 2.123456789 * 3);

      // Exercise the edit path too: spoken rounding must never feed back to VM.
      final accelerationFinder = find.byKey(
        const ValueKey('visual-control-acceleration'),
      );
      tester.widget<Slider>(accelerationFinder).onChanged!(3.123456789);
      await tester.pump();
      await tester.ensureVisible(accelerationFinder);
      await tester.pumpAndSettle();
      final accelerationData = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.getSemanticsData())
          .singleWhere((data) => data.value.endsWith(' m/s²'));
      expect(accelerationData.value, '3.1235 m/s²');
      expect(accelerationData.increasedValue, '5.1235 m/s²');
      expect(accelerationData.decreasedValue, '1.1235 m/s²');
      expect(vm.valueFor('acceleration'), '3.123456789');
      expect(vm.result!.value, 2.123456789 * 3.123456789);
      expect(vm.result!.value, isNot(2.1235 * 3.1235));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final playground in [false, true]) {
    testWidgets(
      'Newton ${playground ? 'Playground' : 'Learn visually'} bounds screenshot labels and scene speech',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final vm = visualVm('newtons-second-law', {
          'mass': '53.929227941176435',
          'acceleration': '3',
        });
        try {
          final report = vm.result!;
          final summary = mapVisualModel(report)!.summary;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: playground
                    ? SingleChildScrollView(
                        child: PlaygroundContent(viewModel: vm),
                      )
                    : VisualLearningSheet(viewModel: vm),
              ),
            ),
          );
          expect(summary, contains('Mass 53.9292 kg.'));
          expect(summary, contains('Input acceleration 3 m/s².'));
          final scene = find.bySemanticsLabel(summary);
          await tester.ensureVisible(scene);
          await tester.pumpAndSettle();
          expect(scene, findsOneWidget);
          expect(
            find.text('Mass 53.9292 kg · Input acceleration 3 m/s²'),
            findsOneWidget,
          );
          if (!playground) {
            expect(find.text('Mass: 53.9292 kg'), findsOneWidget);
          } else {
            expect(find.byType(Slider), findsNothing);
          }
          expect(vm.valueFor('mass'), '53.929227941176435');
          expect(vm.result, same(report));
          expect(report.value, 53.929227941176435 * 3);
          expect(report.value, isNot(53.9292 * 3));
          expect(report.substitution, contains('53.929227941176435'));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
          vm.dispose();
        }
      },
    );
  }
}
