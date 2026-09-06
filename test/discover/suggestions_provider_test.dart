import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/discover/data/discover_repository.dart';
import 'package:animatch/features/discover/domain/discover_animal.dart';
import 'package:animatch/features/discover/providers/discover_provider.dart';

class _FakeDiscoverRepository extends DiscoverRepository {
  _FakeDiscoverRepository(this._byAnimalId) : super(Dio());

  final Map<String, List<DiscoverAnimal>> _byAnimalId;
  final Map<String, int> callCounts = {};

  @override
  Future<List<DiscoverAnimal>> getSuggestions(String animalId) async {
    callCounts[animalId] = (callCounts[animalId] ?? 0) + 1;
    return _byAnimalId[animalId] ?? const [];
  }
}

DiscoverAnimal _animal(String id) => DiscoverAnimal(
      id: id,
      name: 'Animal $id',
      species: 'cattle',
      breed: 'Nelore',
      sex: 'Macho',
      photoUrls: const [],
      locationCity: '',
      locationState: '',
    );

void main() {
  group('suggestionsProvider', () {
    test('the animalId family key scopes results — two ids do not share '
        'cached data', () async {
      final repo = _FakeDiscoverRepository({
        'a1': [_animal('cand1')],
        'a2': [_animal('cand2'), _animal('cand3')],
      });
      final container = ProviderContainer(overrides: [
        discoverRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final resultsA1 = await container.read(suggestionsProvider('a1').future);
      final resultsA2 = await container.read(suggestionsProvider('a2').future);

      expect(resultsA1.map((a) => a.id), ['cand1']);
      expect(resultsA2.map((a) => a.id), ['cand2', 'cand3']);
    });

    test('ref.invalidate on one family instance re-fetches only that '
        'instance', () async {
      final repo = _FakeDiscoverRepository({
        'a1': [_animal('cand1')],
      });
      final container = ProviderContainer(overrides: [
        discoverRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await container.read(suggestionsProvider('a1').future);
      expect(repo.callCounts['a1'], 1);

      container.invalidate(suggestionsProvider('a1'));
      await container.read(suggestionsProvider('a1').future);

      expect(repo.callCounts['a1'], 2);
    });
  });
}
