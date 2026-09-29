import 'package:engineering_toolkit/features/calculators/domain/initial_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show pumpApp;
import 'calculator_test.dart' show enterInput, pressCalculate;
import 'content_expansion_test.dart' show tapVisible;

void main() {
  testWidgets(
    'quadratic copy and accessible reasoning follow current coefficients',
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
      final semantics = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          registry: createInitialCatalog(),
          location: '/calculator/quadratic-equation',
          size: const Size(320, 568),
          textScale: 2,
        );
        await enterInput(tester, 'a', '1');
        await enterInput(tester, 'b', '-2');
        await enterInput(tester, 'c', '1.0000001');
        await pressCalculate(tester);
        final substitution = find.text('(1)x² + (-2)x + (1.0000001) = 0');
        expect(substitution, findsOneWidget);
        await tester.ensureVisible(substitution);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(substitution).toStringDeep(),
          contains('1.0000001'),
        );
        await tapVisible(tester, find.byTooltip('Copy result'));
        expect(clipboard, contains('(1.0000001) = 0'));
        expect(clipboard, contains('0.000316i'));
        await enterInput(tester, 'c', '');
        expect(find.byTooltip('Copy result'), findsNothing);
        expect(substitution, findsNothing);
        await pressCalculate(tester);
        expect(find.text('Enter a value.'), findsOneWidget);
        await enterInput(tester, 'b', '-10');
        await enterInput(tester, 'c', '25');
        await pressCalculate(tester);
        await tapVisible(tester, find.byTooltip('Copy result'));
        expect(clipboard, contains('x = 5 (double root)'));
        expect(clipboard, isNot(contains('1.0000001')));
        await tapVisible(tester, find.text('Reset'));
        expect(find.byTooltip('Copy result'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
