import 'dart:async';

import 'package:engineering_toolkit/core/design_system/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show pumpApp;

const _policyUrl =
    'https://robmacsoftware.github.io/engineering-toolkit/privacy/';
const _launcher = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> openPolicy(WidgetTester tester) async {
    await pumpApp(tester, location: '/settings');
    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'About launches the official policy externally without preflight',
    (tester) async {
      await openPolicy(tester);
      final about = find.ancestor(
        of: find.text('About'),
        matching: find.byType(GlassCard),
      );
      expect(
        find.descendant(of: about, matching: find.text('Privacy Policy')),
        findsOneWidget,
      );
      expect(calls, hasLength(1));
      expect(calls.single.method, 'launch');
      final arguments = calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['url'], _policyUrl);
      // The plugin's default method-channel adapter maps externalApplication
      // to disabling both in-app browser mechanisms.
      expect(arguments['useSafariVC'], false);
      expect(arguments['useWebView'], false);
      expect(find.byType(SnackBar), findsNothing);
      await tester.ensureVisible(find.byTooltip('Back'));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('About'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final throwsException in [false, true]) {
    testWidgets(
      'launch failure gives feedback and permits retry: exception=$throwsException',
      (tester) async {
        var attempts = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _launcher,
          (call) async {
            attempts++;
            if (attempts > 1) return true;
            if (throwsException) throw PlatformException(code: 'NO_HANDLER');
            return false;
          },
        );
        await openPolicy(tester);
        expect(find.text('Could not open the Privacy Policy.'), findsOneWidget);
        expect(find.text('Copy link'), findsOneWidget);
        // Dismiss feedback before retrying the button underneath it.
        await tester.drag(find.byType(SnackBar), const Offset(0, 200));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Privacy Policy'));
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();
        expect(attempts, 2);
        await tester.ensureVisible(find.byTooltip('Back'));
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.text('About'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final copyFails in [false, true]) {
    testWidgets(
      'fallback copies the official URL safely: copyFails=$copyFails',
      (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _launcher,
          (_) async => false,
        );
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied =
                  (call.arguments as Map<Object?, Object?>)['text'] as String;
              if (copyFails) {
                throw PlatformException(code: 'CLIPBOARD_UNAVAILABLE');
              }
            }
            return null;
          },
        );
        await openPolicy(tester);
        await tester.tap(find.text('Copy link'));
        await tester.pumpAndSettle();
        expect(copied, _policyUrl);
        expect(
          find.text(
            copyFails
                ? 'Could not copy the Privacy Policy link.'
                : 'Privacy Policy link copied',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a late platform failure after leaving Settings is safe', (
    tester,
  ) async {
    final pending = Completer<bool>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _launcher,
      (_) => pending.future,
    );
    await openPolicy(tester);
    await tester.pumpWidget(const SizedBox());
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'policy button supports semantics and keyboard at text scale $scale',
      (tester) async {
        await pumpApp(
          tester,
          location: '/settings',
          size: const Size(320, 800),
          textScale: scale,
        );
        final semantics = tester.ensureSemantics();
        try {
          await tester.scrollUntilVisible(
            find.text('Privacy Policy'),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          final button = find.widgetWithText(TextButton, 'Privacy Policy');
          expect(
            tester.getSemantics(button),
            matchesSemantics(
              label: 'Privacy Policy',
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          for (var i = 0; i < 12; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            final focused = FocusManager.instance.primaryFocus?.context;
            if (focused != null &&
                (focused.widget == tester.widget(button) ||
                    focused.findAncestorWidgetOfExactType<TextButton>() ==
                        tester.widget(button))) {
              break;
            }
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(calls, hasLength(1));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
