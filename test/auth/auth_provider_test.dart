import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';

import '../helpers/fakes.dart';

const _original = Breeder(id: '1', name: 'A', email: 'a@x.com');
const _updated = Breeder(id: '1', name: 'A', email: 'a@x.com', city: 'Uberaba');

void main() {
  group('restoreSession', () {
    test('sets state when a session is restored', () async {
      final fake = FakeAuthRepository(restoreSessionResult: _updated);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).restoreSession();

      expect(container.read(authNotifierProvider), _updated);
    });

    test('leaves state null when there is nothing to restore', () async {
      final fake = FakeAuthRepository(restoreSessionResult: null);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).restoreSession();

      expect(container.read(authNotifierProvider), isNull);
    });
  });

  // Covers the M-4 fix: refreshBreeder() is what keeps a stale in-memory
  // verification status from lingering after the app is foregrounded.
  group('refreshBreeder', () {
    test('is a no-op when logged out', () async {
      final fake = FakeAuthRepository(refreshBreederResult: _updated);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      expect(container.read(authNotifierProvider), isNull);
      await container.read(authNotifierProvider.notifier).refreshBreeder();

      expect(fake.refreshBreederCalls, 0);
      expect(container.read(authNotifierProvider), isNull);
    });

    test('updates state on success', () async {
      final fake = FakeAuthRepository(refreshBreederResult: _updated);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).updateBreeder(_original);
      await container.read(authNotifierProvider.notifier).refreshBreeder();

      expect(fake.refreshBreederCalls, 1);
      expect(container.read(authNotifierProvider), _updated);
    });

    test('leaves the cached breeder untouched on failure, does not log out', () async {
      final fake = FakeAuthRepository(refreshBreederResult: null); // simulated failure
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).updateBreeder(_original);
      await container.read(authNotifierProvider.notifier).refreshBreeder();

      expect(fake.refreshBreederCalls, 1);
      expect(container.read(authNotifierProvider), _original);
    });
  });

  group('login', () {
    test('sets state to the repository result', () async {
      final fake = FakeAuthRepository(loginResult: _updated);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).login();

      expect(fake.loginCalls, 1);
      expect(container.read(authNotifierProvider), _updated);
    });
  });

  group('signUp', () {
    test('sets state to the repository result', () async {
      final fake = FakeAuthRepository(signUpResult: _updated);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).signUp();

      expect(fake.signUpCalls, 1);
      expect(container.read(authNotifierProvider), _updated);
    });
  });

  group('syncBreeder', () {
    test('sets state to the repository result', () async {
      final fake = FakeAuthRepository(syncBreederResult: _updated);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).syncBreeder(
            name: 'A',
            city: 'Uberaba',
            state: 'MG',
            zipCode: '12345000',
          );

      final call = fake.syncBreederCalls.single;
      expect(call['name'], 'A');
      expect(call['city'], 'Uberaba');
      expect(container.read(authNotifierProvider), _updated);
    });
  });

  group('updateBreeder', () {
    test('direct state set', () {
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ]);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).updateBreeder(_updated);

      expect(container.read(authNotifierProvider), _updated);
    });
  });

  group('logout', () {
    test('calls repository logout then clears state', () async {
      final fake = FakeAuthRepository();
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).updateBreeder(_updated);
      await container.read(authNotifierProvider.notifier).logout();

      expect(fake.logoutCalls, 1);
      expect(container.read(authNotifierProvider), isNull);
    });
  });

  group('deleteAccount', () {
    test('is a no-op when logged out', () async {
      final fake = FakeAuthRepository();
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).deleteAccount();

      expect(fake.deleteAccountCalls, isEmpty);
      expect(container.read(authNotifierProvider), isNull);
    });

    test('calls repository with the current breeder id then clears state', () async {
      final fake = FakeAuthRepository();
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).updateBreeder(_updated);
      await container.read(authNotifierProvider.notifier).deleteAccount();

      expect(fake.deleteAccountCalls, ['1']);
      expect(container.read(authNotifierProvider), isNull);
    });

    test('propagates a failure and leaves the session intact', () async {
      final fake = FakeAuthRepository(deleteAccountError: Exception('boom'));
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).updateBreeder(_updated);

      await expectLater(
        container.read(authNotifierProvider.notifier).deleteAccount(),
        throwsException,
      );
      expect(container.read(authNotifierProvider), _updated);
    });
  });
}
