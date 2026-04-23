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
