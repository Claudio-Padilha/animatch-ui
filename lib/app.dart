import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/device_token_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/breeder.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';

class AnimatchApp extends ConsumerStatefulWidget {
  const AnimatchApp({super.key});

  @override
  ConsumerState<AnimatchApp> createState() => _AnimatchAppState();
}

class _AnimatchAppState extends ConsumerState<AnimatchApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      ref.read(notificationServiceProvider).init();
    }
    _initAuthAndOnboarding();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Picks up server-side profile changes (e.g. an admin revoking
    // verification) that a stale in-memory Breeder wouldn't otherwise
    // reflect until the next full restart.
    if (state == AppLifecycleState.resumed) {
      ref.read(authNotifierProvider.notifier).refreshBreeder();
    }
  }

  Future<void> _initAuthAndOnboarding() async {
    final onboardingLoaded =
        ref.read(hasSeenOnboardingProvider.notifier).load();
    if (kIsWeb) {
      await onboardingLoaded;
    } else {
      await Future.wait([
        ref.read(authNotifierProvider.notifier).restoreSession(),
        onboardingLoaded,
      ]);
    }
    ref.read(authInitializedProvider.notifier).setInitialized();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Breeder?>(authNotifierProvider, (prev, next) {
      if (next != null && prev == null) _onLogin();
      if (next == null && prev != null) _onLogout();
    });

    return MaterialApp.router(
      title: 'Animatch',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  Future<void> _onLogin() async {
    if (kIsWeb) return;
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final deviceTokenService = ref.read(deviceTokenServiceProvider);

      final settings = await notificationService.requestPermission();
      if (kDebugMode) {
        debugPrint('[FCM] permission status: ${settings.authorizationStatus}');
      }

      final token = await notificationService.getToken();
      if (kDebugMode) {
        debugPrint('[FCM] device token: ${token ?? "NULL — FCM token unavailable"}');
      }

      if (token != null) {
        await deviceTokenService.register(token);
        if (kDebugMode) {
          debugPrint('[FCM] token registered with backend');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[FCM] skipping registration — getToken() returned null');
        }
      }

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = notificationService.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          debugPrint('[FCM] token refreshed, re-registering...');
        }
        deviceTokenService.register(newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] _onLogin error: $e');
      }
    }
  }

  Future<void> _onLogout() async {
    if (kIsWeb) return;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      final token = await ref.read(notificationServiceProvider).getToken();
      if (token != null) {
        await ref.read(deviceTokenServiceProvider).unregister(token);
        if (kDebugMode) {
          debugPrint('[FCM] token unregistered on logout.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] _onLogout error: $e');
      }
    }
  }
}
