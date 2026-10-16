import 'dart:async';

import 'package:engineering_toolkit/core/design_system/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show pumpApp;

const _supportUrl = 'https://robmacsoftware.github.io/support/';
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

  Future<void> openSupport(WidgetTester tester) async {
    await pumpApp(tester, location: '/settings');
    await tester.ensureVisible(find.text('Support Development'));
    await tester.tap(find.text('Support Development'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'About launches the official support page externally without preflight',
    (tester) async {
      await openSupport(tester);
      final about = find.ancestor(
        of: find.text('About'),
        matching: find.byType(GlassCard),
      );
      expect(
        find.descendant(of: about, matching: find.text('Support Development')),
        findsOneWidget,
      );
      expect(calls, hasLength(1));
      expect(calls.single.method, 'launch');
      final arguments = calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['url'], _supportUrl);
      // The plugin's default method-channel adapter maps externalApplication
      // to disabling both in-app browser mechanisms.
      expect(arguments['useSafariVC'], false);
      expect(arguments['useWebView'], false);
      expect(find.byType(SnackBar), findsNothing);
      await tester.scrollUntilVisible(
        find.byTooltip('Back'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
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
        await openSupport(tester);
        expect(find.text('Could not open the Support page.'), findsOneWidget);
        expect(find.text('Copy link'), findsOneWidget);
        // Dismiss feedback before retrying the button underneath it.
        await tester.drag(find.byType(SnackBar), const Offset(0, 200));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Support Development'));
        await tester.tap(find.text('Support Development'));
        await tester.pumpAndSettle();
        expect(attempts, 2);
        await tester.scrollUntilVisible(
          find.byTooltip('Back'),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
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
        await openSupport(tester);
        await tester.tap(find.text('Copy link'));
        await tester.pumpAndSettle();
        expect(copied, _supportUrl);
        expect(
          find.text(
            copyFails
                ? 'Could not copy the Support page link.'
                : 'Support page link copied',
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
    await openSupport(tester);
    await tester.pumpWidget(const SizedBox());
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('late launcher exception after disposal is safe', (tester) async {
    final pending = Completer<bool>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _launcher,
      (_) => pending.future,
    );
    await openSupport(tester);
    await tester.pumpWidget(const SizedBox());
    pending.completeError(PlatformException(code: 'NO_HANDLER'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final copyFails in [false, true]) {
    testWidgets('late clipboard completion is safe: copyFails=$copyFails', (
      tester,
    ) async {
      final pending = Completer<void>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _launcher,
        (_) async => false,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') await pending.future;
          return null;
        },
      );
      await openSupport(tester);
      await tester.tap(find.text('Copy link'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      if (copyFails) {
        pending.completeError(PlatformException(code: 'CLIPBOARD_UNAVAILABLE'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'support button supports semantics and keyboard at text scale $scale',
      (tester) async {
        await pumpApp(
          tester,
          location: '/settings',
          size: const Size(320, 568),
          textScale: scale,
        );
        final semantics = tester.ensureSemantics();
        try {
          await tester.scrollUntilVisible(
            find.text('Support Development'),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          final button = find.widgetWithText(TextButton, 'Support Development');
          expect(
            tester.getSemantics(button),
            matchesSemantics(
              label: 'Support Development',
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
