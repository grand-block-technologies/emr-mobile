import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  group('AppButton', () {
    testWidgets('calls back when tapped', (tester) async {
      var taps = 0;
      await pumpApp(tester, AppButton(label: 'Go', onPressed: () => taps++));
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('while busy shows a spinner, keeps its size and ignores taps', (tester) async {
      var taps = 0;
      await pumpApp(tester, Center(child: AppButton(label: 'Sign in', onPressed: () => taps++, expand: false)));
      final idleSize = tester.getSize(find.byType(FilledButton));

      await pumpApp(tester, Center(child: AppButton(label: 'Sign in', onPressed: () => taps++, busy: true, expand: false)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)), idleSize);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('is at least 44 high', (tester) async {
      await pumpApp(tester, Center(child: AppButton(label: 'X', onPressed: () {}, variant: ButtonVariant.ghost, expand: false)));
      expect(tester.getSize(find.byType(TextButton)).height, greaterThanOrEqualTo(44));
    });
  });

  testWidgets('PriorityPill shows code and words, never colour alone', (tester) async {
    await pumpApp(tester, const PriorityPill(Priority.p1));
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('Life in danger'), findsOneWidget);
  });

  testWidgets('PriorityPill keeps the code LTR in Arabic', (tester) async {
    await pumpApp(tester, const PriorityPill(Priority.p2), lang: 'ar');
    expect(find.text('خطير'), findsOneWidget);
    final code = tester.widget<Text>(find.text('P2'));
    expect(code.textDirection, TextDirection.ltr);
  });

  testWidgets('LabeledField shows its label above and the error under it', (tester) async {
    await pumpApp(tester, const Padding(padding: EdgeInsets.all(16), child: LabeledField(label: 'Username', errorText: 'Required')));
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Username')).dy, lessThan(tester.getTopLeft(find.byType(TextField)).dy));
  });

  group('ErrorView', () {
    testWidgets('shows the reference only for unexpected errors', (tester) async {
      const unexpected = ApiError(status: 500, code: 'INTERNAL_ERROR', ar: 'خطأ', en: 'Server error', reference: 'REF-1');
      await pumpApp(tester, const ErrorView(error: unexpected));
      expect(find.text('Server error'), findsOneWidget);
      expect(find.textContaining('REF-1'), findsOneWidget);

      const expected = ApiError(status: 409, code: 'SHIFT_FULL', ar: 'ممتلئة', en: 'Shift is full', reference: 'REF-2');
      await pumpApp(tester, const ErrorView(error: expected));
      expect(find.textContaining('REF-2'), findsNothing);
    });

    testWidgets('picks the server message in the UI language', (tester) async {
      await pumpApp(tester, const ErrorView(error: ApiError.network), lang: 'ar');
      expect(find.text('تعذّر الاتصال بالخادم'), findsOneWidget);
    });

    testWidgets('Retry calls back', (tester) async {
      var retried = false;
      await pumpApp(tester, ErrorView(error: ApiError.network, onRetry: () => retried = true));
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  testWidgets('LoadingView announces loading and stops the shine with reduced motion', (tester) async {
    await pumpApp(tester, const MediaQuery(data: MediaQueryData(disableAnimations: true), child: LoadingView()));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('SyncStatusChip', () {
    String label(bool online, SyncState s) => SyncStatusChip.describe(online: online, state: s).$1;

    testWidgets('covers the standard data states', (tester) async {
      await pumpApp(tester, const SizedBox());
      expect(label(true, const SyncState()), 'Online · all sent');
      expect(label(false, const SyncState(pending: 3)), 'Offline · 3 waiting');
      expect(label(false, const SyncState()), 'Offline');
      expect(label(true, const SyncState(pending: 3, sendingIndex: 2, sendingTotal: 3)), 'Sending 2 of 3');
      expect(label(true, const SyncState(pending: 2, blocked: true)), 'Waiting for network · 2 waiting');
      expect(label(true, const SyncState(pending: 2)), 'Online · 2 waiting to send', reason: 'never says Offline when online');
    });
  });

  group('SwipeToConfirm', () {
    Future<int> swipe(WidgetTester tester, {required String lang, required double dx}) async {
      var confirmed = 0;
      await pumpApp(
        tester,
        Padding(padding: const EdgeInsets.all(16), child: SwipeToConfirm(label: 'Swipe to accept', onConfirmed: () => confirmed++)),
        lang: lang,
      );
      await tester.drag(find.byKey(const Key('swipe_thumb')), Offset(dx, 0));
      await tester.pumpAndSettle();
      return confirmed;
    }

    testWidgets('a full swipe confirms (LTR)', (tester) async {
      expect(await swipe(tester, lang: 'en', dx: 800), 1);
    });

    testWidgets('a short swipe does nothing', (tester) async {
      expect(await swipe(tester, lang: 'en', dx: 60), 0);
    });

    testWidgets('in Arabic the swipe goes right to left', (tester) async {
      expect(await swipe(tester, lang: 'ar', dx: 800), 0, reason: 'wrong direction');
      expect(await swipe(tester, lang: 'ar', dx: -800), 1);
    });

    testWidgets('screen readers can confirm with a tap action', (tester) async {
      var confirmed = 0;
      await pumpApp(tester, SwipeToConfirm(label: 'Swipe to accept', onConfirmed: () => confirmed++));
      final semantics = tester.getSemantics(find.bySemanticsLabel('Swipe to accept'));
      expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    });
  });

  testWidgets('theme uses the bundled Plex family for the language', (tester) async {
    expect(appTheme(const Locale('ar')).textTheme.bodyLarge!.fontFamily, AppFonts.arabic);
    expect(appTheme(const Locale('en')).textTheme.bodyLarge!.fontFamily, AppFonts.latin);
    expect(appTheme(const Locale('en')).brightness, Brightness.light);
  });
}
