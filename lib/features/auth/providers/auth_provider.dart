import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/dev_token_service.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/breeder.dart';

// Holds the current Bearer token. Set by AuthNotifier; cleared on logout.
class _AccessTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? token) => state = token;
}

final accessTokenProvider =
    NotifierProvider<_AccessTokenNotifier, String?>(_AccessTokenNotifier.new);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<Breeder?> {
  @override
  Breeder? build() => null;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> login({required String email}) async {
    final breeder = await _repository.login(email: email, name: state?.name);
    ref.read(accessTokenProvider.notifier).set(DevTokenService.buildToken(breeder));
    state = breeder;
  }

  Future<void> signUp({required String name, required String email, String? phone}) async {
    await _repository.signUp(name: name, email: email, phone: phone);
  }

  void updateBreeder(Breeder breeder) {
    ref.read(accessTokenProvider.notifier).set(DevTokenService.buildToken(breeder));
    state = breeder;
  }

  void logout() {
    ref.read(accessTokenProvider.notifier).set(null);
    state = null;
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, Breeder?>(AuthNotifier.new);
