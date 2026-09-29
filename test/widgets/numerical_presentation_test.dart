import 'dart:math' as math;

import 'package:engineering_toolkit/features/calculators/domain/calculation_outcome.dart';
import 'package:engineering_toolkit/features/calculators/domain/engines/fluids.dart';
import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_learning_sheet.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_models.dart';
import 'package:engineering_toolkit/features/calculators/presentation/visual_learning/visual_scene.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;
import 'content_expansion_test.dart' show tapVisible;
import 'visual_learning_test.dart' show openVisual;

void main() {
  testWidgets(
    'compensated quadratic branches retain coefficients reasoning and Copy',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
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
      await pumpApp(
        tester,
        registry: createInitialCatalog(),
        location: '/calculator/quadratic-equation',
      );
      for (final complex in [false, true]) {
        final d = math.pow(2.0, complex ? -26 : -27).toDouble();
        final a = (1 + d).toString();
        final c = (1 - d + (complex ? d * d : 0)).toString();
        await enterInput(tester, 'a', a);
        await enterInput(tester, 'b', '2');
        await enterInput(tester, 'c', c);
        expect(find.byTooltip('Copy result'), findsNothing);
        await pressCalculate(tester);
        expect(find.text('($a)x² + (2)x + ($c) = 0'), findsOneWidget);
        expect(
          find.textContaining(
            complex ? 'discriminant is negative' : 'discriminant is positive',
          ),
          findsOneWidget,
        );
        await tapVisible(tester, find.byTooltip('Copy result'));
        expect(clipboard, contains('($a)x² + (2)x + ($c) = 0'));
        expect(find.text('ax² + bx + c = 0'), findsWidgets);
        expect(clipboard, isNot(contains('double root')));
        if (complex) {
          expect(clipboard, contains('i'));
          expect(find.textContaining('conjugates'), findsOneWidget);
        } else {
          expect(clipboard, contains('x1 = -1'));
          expect(clipboard, contains('x2 = -0.9999999850988389'));
        }
      }
      await enterInput(tester, 'a', '0');
      expect(find.byTooltip('Copy result'), findsNothing);
      await pressCalculate(tester);
      expect(find.textContaining('discriminant is negative'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bernoulli compensated pressure uses one report in scene reasoning and Copy',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
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
      final height = (1e16 / (2 * standardGravity)).toString();
      await openVisual(tester, 'bernoulli-basic', {
        'pressure1': '1',
        'density': '2',
        'speed1': '100000000',
        'speed2': '0',
        'height1': '0',
        'height2': height,
      }, reduced: true);
      final vm = tester
          .widget<VisualLearningSheet>(find.byType(VisualLearningSheet))
          .viewModel;
      final report = vm.result!;
      expect(report.value, 1);
      final model = mapVisualModel(report)! as BernoulliVisualModel;
      expect(model.report, same(report));
      expect(model.summary, contains('1 Pa'));
      expect(find.text('Downstream pressure P2 = 1 Pa'), findsOneWidget);
      expect(report.formula, 'P2 = P1 + ½ρ(v1² − v2²) + ρg(z1 − z2)');
      expect(report.substitution, contains(height));
      expect(report.substitution, contains('100000000'));
      expect(report.explanation, contains('predicts 1 Pa'));
      await tester.tap(find.byTooltip('Close visualization'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('Copy result'));
      expect(clipboard, contains('P2 = 1 Pa'));
      expect(clipboard, contains(report.substitution));
      expect(find.text(report.explanation), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // Dismiss Copy snackbar.
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Learn visually'));
      // This nonzero head is unrepresentable: the corrected range failure must
      // replace the old report and scene instead of retaining their pressure.
      vm.setValue('density', '5e-324');
      vm.setValue('speed1', '1');
      vm.setValue('height2', '0');
      vm.calculate();
      await tester.pumpAndSettle();
      expect(vm.result, isNull);
      expect(
        vm.issues.any((i) => i.code == CalculationError.numericRange),
        isTrue,
      );
      expect(find.byType(VisualScene), findsNothing);
      expect(find.text('Return to inputs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
