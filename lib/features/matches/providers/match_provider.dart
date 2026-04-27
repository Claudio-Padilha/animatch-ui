import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/match_repository.dart';
import '../domain/match_item.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(dioProvider)),
);

final matchesProvider = FutureProvider.autoDispose
    .family<List<MatchItem>, String>((ref, animalId) =>
        ref.read(matchRepositoryProvider).getMatches(animalId));

// ─── Cancel match ─────────────────────────────────────────────────────────────

class CancelMatchNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> cancel(String matchId, {required String animalId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(matchRepositoryProvider).rejectMatch(matchId),
    );
    if (state is! AsyncError) {
      ref.invalidate(matchesProvider(animalId));
    }
  }
}

final cancelMatchProvider =
    AsyncNotifierProvider<CancelMatchNotifier, void>(CancelMatchNotifier.new);

// ─── Delete match ─────────────────────────────────────────────────────────────

class DeleteMatchNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteMatch(String matchId, {required String animalId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(matchRepositoryProvider).deleteMatch(matchId),
    );
    if (state is! AsyncError) {
      ref.invalidate(matchesProvider(animalId));
    }
  }
}

final deleteMatchProvider =
    AsyncNotifierProvider<DeleteMatchNotifier, void>(DeleteMatchNotifier.new);
