import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/breeder.dart';

class AuthNotifier extends Notifier<Breeder?> {
  @override
  Breeder? build() => null;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> login() async {
    final breeder = await _repository.login();
    state = breeder;
  }

  Future<void> signUp() async {
    final breeder = await _repository.signUp();
    state = breeder;
  }

  Future<void> syncBreeder({
    required String name,
    required String city,
    required String state,
    required String zipCode,
    String? directions,
  }) async {
    final breeder = await _repository.syncBreeder(
      name: name,
      city: city,
      state: state,
      zipCode: zipCode,
      directions: directions,
    );
    this.state = breeder;
  }

  void updateBreeder(Breeder breeder) {
    state = breeder;
  }

  Future<void> restoreSession() async {
    final breeder = await _repository.restoreSession();
    if (breeder != null) state = breeder;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, Breeder?>(AuthNotifier.new);

class _AuthInitializedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setInitialized() => state = true;
}

// Becomes true once restoreSession() has completed (or is skipped on web).
// The router waits on this before deciding where to navigate.
final authInitializedProvider =
    NotifierProvider<_AuthInitializedNotifier, bool>(_AuthInitializedNotifier.new);
