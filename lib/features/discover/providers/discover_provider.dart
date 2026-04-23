import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/discover_repository.dart';
import '../domain/discover_animal.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref.watch(dioProvider)),
);

final suggestionsProvider = FutureProvider.autoDispose
    .family<List<DiscoverAnimal>, String>(
  (ref, animalId) =>
      ref.read(discoverRepositoryProvider).getSuggestions(animalId),
);
