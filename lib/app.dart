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

class AnimatchApp extends ConsumerStatefulWidget {
  const AnimatchApp({super.key});

  @override
  ConsumerState<AnimatchApp> createState() => _AnimatchAppState();
}

class _AnimatchAppState extends ConsumerState<AnimatchApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) ref.read(notificationServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    // Register / unregister FCM token whenever auth state changes.
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
      final breeder = ref.read(authNotifierProvider)!;
      final notificationService = ref.read(notificationServiceProvider);
      final deviceTokenService = ref.read(deviceTokenServiceProvider);

      final settings = await notificationService.requestPermission();
      // ignore: avoid_print
      print('[FCM] permission status: ${settings.authorizationStatus}');

      final token = await notificationService.getToken();
      // ignore: avoid_print
      print('[FCM] device token: $token');

      if (token != null) {
        await deviceTokenService.register(token, breederId: breeder.id);
        // ignore: avoid_print
        print('[FCM] token registered with backend.');
      }

      notificationService.onTokenRefresh.listen((newToken) {
        // ignore: avoid_print
        print('[FCM] token refreshed, re-registering...');
        deviceTokenService.register(newToken, breederId: breeder.id);
      });
    } catch (e) {
      // ignore: avoid_print
      print('[FCM] _onLogin error: $e');
    }
  }

  Future<void> _onLogout() async {
    if (kIsWeb) return;
    try {
      final breeder = ref.read(authNotifierProvider);
      final token = await ref.read(notificationServiceProvider).getToken();
      if (token != null && breeder != null) {
        await ref.read(deviceTokenServiceProvider).unregister(token, breederId: breeder.id);
        // ignore: avoid_print
        print('[FCM] token unregistered on logout.');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FCM] _onLogout error: $e');
    }
  }
}
