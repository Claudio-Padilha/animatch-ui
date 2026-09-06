import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/app.dart';
import 'package:animatch/core/services/device_token_service.dart';
import 'package:animatch/core/services/notification_service.dart';
import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/herd/providers/herd_provider.dart';
import 'package:animatch/features/onboarding/providers/onboarding_provider.dart';

import 'helpers/fakes.dart';

// city set so the post-login redirect lands on HerdScreen, not
// ProfileCompletionScreen — the latter's AddressFormFields watches
// municipalitiesProvider, a real network call that never resolves under
// flutter test, leaving a perpetually-animating loading spinner that
// pumpAndSettle can never settle past. HerdScreen's own network dependency
// (herdRepositoryProvider) is overridden below with a fake instead.
const _breeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  city: 'Uberaba',
);

/// The onboarding/login screens the app lands on before a breeder is
/// seeded overflow under `flutter test`'s GoogleFonts fallback metrics
/// (same root cause as K-5 in docs/known-issues.md) — this test's actual
/// subject is app.dart's login/logout/lifecycle wiring, not those screens'
/// layout, so silence just that error class rather than widen the
/// viewport to chase every screen this test might transiently pass
/// through. Matches the precedent already established in
/// test/widget_test.dart for the same reason.
void _muteFontFallbackOverflow() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isOverflow =
        details.exception.toString().contains('A RenderFlex overflowed');
    if (!isOverflow) originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required FakeNotificationService notificationService,
  required FakeDeviceTokenService deviceTokenService,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _muteFontFallbackOverflow();

  final container = ProviderContainer(overrides: [
    notificationServiceProvider.overrideWithValue(notificationService),
    deviceTokenServiceProvider.overrideWithValue(deviceTokenService),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    hasSeenOnboardingProvider.overrideWith(FakeOnboardingNotifier.new),
    herdRepositoryProvider.overrideWithValue(FakeHerdRepository(getAnimalsResult: const [])),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const AnimatchApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('AnimatchApp._onLogin', () {
    testWidgets(
        'on auth transitioning null -> non-null: requests notification '
        'permission, registers the FCM token, subscribes to '
        'onTokenRefresh', (tester) async {
      final notificationService =
          FakeNotificationService(tokenResult: 'fcm-token-1');
      final deviceTokenService = FakeDeviceTokenService();
      final container = await _pumpApp(
        tester,
        notificationService: notificationService,
        deviceTokenService: deviceTokenService,
      );

      container.read(authNotifierProvider.notifier).updateBreeder(_breeder);
      await tester.pumpAndSettle();

      expect(notificationService.requestPermissionCalls, 1);
      expect(notificationService.getTokenCalls, 1);
      expect(deviceTokenService.registerCalls, ['fcm-token-1']);
      expect(notificationService.onTokenRefreshController.hasListener, isTrue);
    });

    testWidgets(
        'does not stack onTokenRefresh listeners across login -> logout -> '
        'login (H-2 regression)', (tester) async {
      final notificationService =
          FakeNotificationService(tokenResult: 'fcm-token-1');
      final deviceTokenService = FakeDeviceTokenService();
      final container = await _pumpApp(
        tester,
        notificationService: notificationService,
        deviceTokenService: deviceTokenService,
      );

      container.read(authNotifierProvider.notifier).updateBreeder(_breeder);
      await tester.pumpAndSettle();
      expect(notificationService.onTokenRefreshController.hasListener, isTrue);

      await container.read(authNotifierProvider.notifier).logout();
      await tester.pumpAndSettle();
      // _onLogout cancels the subscription immediately (synchronously,
      // before its own async token fetch), so it's gone even mid-logout.
      expect(
        notificationService.onTokenRefreshController.hasListener,
        isFalse,
      );

      container.read(authNotifierProvider.notifier).updateBreeder(_breeder);
      await tester.pumpAndSettle();

      // A StreamController exposes only hasListener (not a count), so the
      // real proof this isn't stacked is that only one #onTokenRefresh
      // subscription is active — broadcast streams tolerate multiple
      // listeners silently, so directly counting registrations driven by
      // one refresh event is the more precise assertion.
      notificationService.onTokenRefreshController.add('refreshed-token');
      await tester.pumpAndSettle();

      // 1 registerCall from each login (2 logins) + 1 from the single
      // refresh listener firing once = 3, not 4+ (which a stacked second
      // listener would produce for the same refresh event).
      expect(deviceTokenService.registerCalls, [
        'fcm-token-1',
        'fcm-token-1',
        'refreshed-token',
      ]);
    });
  });

  group('AnimatchApp._onLogout', () {
    testWidgets('unregisters the FCM token via deviceTokenServiceProvider',
        (tester) async {
      final notificationService =
          FakeNotificationService(tokenResult: 'fcm-token-1');
      final deviceTokenService = FakeDeviceTokenService();
      final container = await _pumpApp(
        tester,
        notificationService: notificationService,
        deviceTokenService: deviceTokenService,
      );

      container.read(authNotifierProvider.notifier).updateBreeder(_breeder);
      await tester.pumpAndSettle();
      await container.read(authNotifierProvider.notifier).logout();
      await tester.pumpAndSettle();

      expect(deviceTokenService.unregisterCalls, ['fcm-token-1']);
    });
  });

  group('didChangeAppLifecycleState', () {
    testWidgets('resumed calls authNotifierProvider.notifier.refreshBreeder()',
        (tester) async {
      final fakeAuthRepo = FakeAuthRepository(
        refreshBreederResult: _breeder.copyWith(name: 'Refreshed'),
      );
      final container = ProviderContainer(overrides: [
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        hasSeenOnboardingProvider.overrideWith(FakeOnboardingNotifier.new),
        herdRepositoryProvider.overrideWithValue(
            FakeHerdRepository(getAnimalsResult: const [])),
      ]);
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _muteFontFallbackOverflow();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AnimatchApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(authNotifierProvider.notifier).updateBreeder(_breeder);
      await tester.pumpAndSettle();
      expect(fakeAuthRepo.refreshBreederCalls, 0);

      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(fakeAuthRepo.refreshBreederCalls, 1);
      expect(container.read(authNotifierProvider)?.name, 'Refreshed');
    });
  });
}
