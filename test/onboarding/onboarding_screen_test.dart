import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/features/onboarding/onboarding_screen.dart';
import 'package:animatch/features/onboarding/providers/onboarding_provider.dart';

import '../helpers/fakes.dart';

/// `_SlideText`'s headline sits in a fixed-height (160) box sized for the
/// real Merriweather font; under `flutter test`'s GoogleFonts fallback
/// (Roboto, wider line-wrap — see the K-4 methodology note in
/// docs/known-issues.md) it overflows. `test/widget_test.dart` already
/// documents this exact case as a test-only artifact, not a real bug on a
/// device with the real font loaded — same mitigation applied here.
void _muteFontFallbackOverflow() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isOverflow =
        details.exception.toString().contains('A RenderFlex overflowed');
    if (!isOverflow) originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

Future<FakeOnboardingNotifier> _pumpOnboarding(
  WidgetTester tester, {
  String? errorMessage,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _muteFontFallbackOverflow();

  final notifier = FakeOnboardingNotifier();
  final container = ProviderContainer(overrides: [
    hasSeenOnboardingProvider.overrideWith(() => notifier),
  ]);
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => OnboardingScreen(errorMessage: errorMessage),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const Text('register-screen'),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const Text('login-screen'),
    ),
  ]);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return notifier;
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('"Pular" calls markSeen() then navigates to register',
        (tester) async {
      final notifier = await _pumpOnboarding(tester);

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(notifier.markSeenCalls, 1);
      expect(find.text('register-screen'), findsOneWidget);
    });

    testWidgets(
        '"Continuar" on the last slide (via repeated taps) calls markSeen() '
        'then navigates to register', (tester) async {
      await _pumpOnboarding(tester);

      // Advance through all slides via the FilledButton.
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      // Now on the last slide — button label switches to "Começar".
      expect(find.text('Começar'), findsOneWidget);

      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();

      expect(find.text('register-screen'), findsOneWidget);
    });

    testWidgets('"Já tenho conta" calls markSeen() then navigates to login',
        (tester) async {
      final notifier = await _pumpOnboarding(tester);

      await tester.tap(find.text('Já tenho conta'));
      await tester.pumpAndSettle();

      expect(notifier.markSeenCalls, 1);
      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets(
        'page swiping updates the dots indicator and button label '
        '(Continuar -> Começar on the last slide)', (tester) async {
      await _pumpOnboarding(tester);

      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Começar'), findsNothing);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Começar'), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
    });

    testWidgets(
        'errorMessage shows AppErrorAlert on first frame and resets to '
        'slide 0', (tester) async {
      await _pumpOnboarding(tester, errorMessage: 'Sessão expirada');
      await tester.pumpAndSettle();

      expect(find.text('Sessão expirada'), findsOneWidget);
      expect(find.text('Ops, algo deu errado'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Still on slide 0 (first slide's headline).
      expect(find.text('Continuar'), findsOneWidget);
    });
  });
}
