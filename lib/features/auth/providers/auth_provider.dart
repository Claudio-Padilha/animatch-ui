import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/dev_token_service.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/breeder.dart';

// Holds the current Bearer token. Set by AuthNotifier from the logged-in
// breeder via DevTokenService; cleared on logout.
final accessTokenProvider = StateProvider<String?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<Breeder?> {
  AuthNotifier(this._repository, this._ref) : super(null);

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> login({required String email}) async {
    final breeder = await _repository.login(email: email, name: state?.name);
    _ref.read(accessTokenProvider.notifier).state =
        DevTokenService.buildToken(breeder);
    state = breeder;
  }

  Future<void> signUp({required String name, required String email}) async {
    await _repository.signUp(name: name, email: email);
  }

  void updateBreeder(Breeder breeder) {
    _ref.read(accessTokenProvider.notifier).state =
        DevTokenService.buildToken(breeder);
    state = breeder;
  }

  void logout() {
    _ref.read(accessTokenProvider.notifier).state = null;
    state = null;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, Breeder?>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref),
);
