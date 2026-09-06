import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/matches/providers/match_provider.dart';

import '../helpers/fakes.dart';

void main() {
  group('matchesProvider', () {
    test('the animalId family key scopes results — two ids do not share '
        'cached data', () async {
      final repo = FakeMatchRepository();
      final container = ProviderContainer(overrides: [
        matchRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await container.read(matchesProvider('a1').future);
      await container.read(matchesProvider('a2').future);

      expect(repo.getMatchesCallArgs, ['a1', 'a2']);
    });
  });

  group('CancelMatchNotifier.cancel', () {
    test('on success: invalidates matchesProvider(animalId) so the list '
        're-fetches', () async {
      final repo = FakeMatchRepository();
      final container = ProviderContainer(overrides: [
        matchRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.listen(matchesProvider('a1'), (_, _) {});
      await container.read(matchesProvider('a1').future);
      expect(repo.getMatchesCallArgs, ['a1']);

      await container
          .read(cancelMatchProvider.notifier)
          .cancel('m1', animalId: 'a1');

      expect(repo.rejectMatchCalls, ['m1']);
      await container.pump();
      expect(repo.getMatchesCallArgs, ['a1', 'a1']);
    });

    test('on error: does not invalidate — stale list stays visible rather '
        'than vanishing an item that was not actually cancelled server-side',
        () async {
      final repo = FakeMatchRepository(rejectMatchError: Exception('boom'));
      final container = ProviderContainer(overrides: [
        matchRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.listen(matchesProvider('a1'), (_, _) {});
      await container.read(matchesProvider('a1').future);
      expect(repo.getMatchesCallArgs, ['a1']);

      await container
          .read(cancelMatchProvider.notifier)
          .cancel('m1', animalId: 'a1');

      expect(container.read(cancelMatchProvider), isA<AsyncError>());
      await container.pump();
      expect(repo.getMatchesCallArgs, ['a1']);
    });
  });

  group('DeleteMatchNotifier.deleteMatch', () {
    test('on success: invalidates matchesProvider(animalId) so the list '
        're-fetches', () async {
      final repo = FakeMatchRepository();
      final container = ProviderContainer(overrides: [
        matchRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.listen(matchesProvider('a1'), (_, _) {});
      await container.read(matchesProvider('a1').future);
      expect(repo.getMatchesCallArgs, ['a1']);

      await container
          .read(deleteMatchProvider.notifier)
          .deleteMatch('m1', animalId: 'a1');

      expect(repo.deleteMatchCalls, ['m1']);
      await container.pump();
      expect(repo.getMatchesCallArgs, ['a1', 'a1']);
    });

    test('on error: does not invalidate the list', () async {
      final repo = FakeMatchRepository(deleteMatchError: Exception('boom'));
      final container = ProviderContainer(overrides: [
        matchRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.listen(matchesProvider('a1'), (_, _) {});
      await container.read(matchesProvider('a1').future);

      await container
          .read(deleteMatchProvider.notifier)
          .deleteMatch('m1', animalId: 'a1');

      expect(container.read(deleteMatchProvider), isA<AsyncError>());
      await container.pump();
      expect(repo.getMatchesCallArgs, ['a1']);
    });
  });
}
