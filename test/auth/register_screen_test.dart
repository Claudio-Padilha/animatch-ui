import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/ui/register_screen.dart';

import '../helpers/fakes.dart';

/// A [FakeAuthRepository] whose `signUp()` doesn't resolve until
/// [completeSignUp]/[failSignUp] is called — the base fake resolves within
/// a single microtask, too fast for `pump()` to catch the intermediate
/// loading state.
class _SlowSignUpAuthRepository extends FakeAuthRepository {
  _SlowSignUpAuthRepository({super.signUpResult});

  final _completer = Completer<void>();

  @override
  Future<Breeder> signUp() async {
    await _completer.future;
    return super.signUp();
  }

  void completeSignUp() => _completer.complete();
  void failSignUp(Object error) => _completer.completeError(error);
}

Future<GoRouter> _pumpRegisterScreen(
  WidgetTester tester, {
  required FakeAuthRepository repo,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const RegisterScreen()),
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
  return router;
}

void main() {
  group('RegisterScreen', () {
    testWidgets(
        'tapping Criar conta calls signUp(), shows a loading spinner '
        'mid-flight, disables the button', (tester) async {
      final repo = _SlowSignUpAuthRepository(
        signUpResult: const Breeder(id: '1', name: 'A', email: 'a@x.com'),
      );
      await _pumpRegisterScreen(tester, repo: repo);

      await tester.tap(find.text('Criar conta').first);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      repo.completeSignUp();
      await tester.pumpAndSettle();

      expect(repo.signUpCalls, 1);
    });

    testWidgets('non-cancellation error shows the Portuguese SnackBar',
        (tester) async {
      final repo = _SlowSignUpAuthRepository();
      await _pumpRegisterScreen(tester, repo: repo);

      await tester.tap(find.text('Criar conta').first);
      await tester.pump();
      repo.failSignUp(Exception('network down'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Não foi possível criar a conta. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('UserCancelled error shows nothing', (tester) async {
      final repo = _SlowSignUpAuthRepository();
      await _pumpRegisterScreen(tester, repo: repo);

      await tester.tap(find.text('Criar conta').first);
      await tester.pump();
      repo.failSignUp(Exception('user_cancelled'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Não foi possível criar a conta. Tente novamente.'),
        findsNothing,
      );
    });

    testWidgets('"Entrar" navigates to the login screen', (tester) async {
      await _pumpRegisterScreen(tester, repo: FakeAuthRepository());

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('login-screen'), findsOneWidget);
    });
  });
}
