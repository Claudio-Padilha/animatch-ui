import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/ui/login_screen.dart';

import '../helpers/fakes.dart';

/// A [FakeAuthRepository] whose `login()` doesn't resolve until
/// [completeLogin]/[failLogin] is called — the base fake resolves within a
/// single microtask, too fast for `pump()` to catch the intermediate
/// loading state.
class _SlowLoginAuthRepository extends FakeAuthRepository {
  _SlowLoginAuthRepository({super.loginResult});

  final _completer = Completer<void>();

  @override
  Future<Breeder> login() async {
    await _completer.future;
    return super.login();
  }

  void completeLogin() => _completer.complete();
  void failLogin(Object error) => _completer.completeError(error);
}

Future<GoRouter> _pumpLoginScreen(
  WidgetTester tester, {
  required FakeAuthRepository repo,
}) async {
  tester.view.physicalSize = const Size(500, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const Text('register-screen'),
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
  return router;
}

void main() {
  group('LoginScreen', () {
    testWidgets(
        'tapping Entrar calls login(), shows a loading spinner mid-flight, '
        'disables the button', (tester) async {
      final repo = _SlowLoginAuthRepository(
        loginResult: const Breeder(id: '1', name: 'A', email: 'a@x.com'),
      );
      await _pumpLoginScreen(tester, repo: repo);

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      repo.completeLogin();
      await tester.pumpAndSettle();

      expect(repo.loginCalls, 1);
    });

    testWidgets(
        'non-cancellation error shows the Portuguese SnackBar',
        (tester) async {
      final repo = _SlowLoginAuthRepository();
      await _pumpLoginScreen(tester, repo: repo);

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      repo.failLogin(Exception('network down'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Não foi possível entrar. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('UserCancelled error shows nothing', (tester) async {
      final repo = _SlowLoginAuthRepository();
      await _pumpLoginScreen(tester, repo: repo);

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      repo.failLogin(Exception('UserCancelled'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Não foi possível entrar. Tente novamente.'),
        findsNothing,
      );
    });

    testWidgets('"Criar conta" navigates to the register screen',
        (tester) async {
      await _pumpLoginScreen(tester, repo: FakeAuthRepository());

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('register-screen'), findsOneWidget);
    });
  });
}
