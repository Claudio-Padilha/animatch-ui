import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/profile/domain/breeder_profile.dart';
import 'package:animatch/features/profile/domain/breeder_statistics.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';
import 'package:animatch/shared/domain/breeder_association.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  phone: '119999999',
  farmName: 'Fazenda Boa Vista',
  city: 'Uberaba',
  state: 'MG',
  associationId: 'assoc1',
  associations: [BreederAssociation(code: 'ABCZ', name: 'ABCZ')],
  status: BreederStatus.pending,
  avatarUrl: 'http://avatar',
);

ProviderContainer _buildContainer({
  Breeder? breeder,
  FakeProfileRepository? profileRepository,
}) {
  final container = ProviderContainer(overrides: [
    authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder)),
    profileRepositoryProvider
        .overrideWithValue(profileRepository ?? FakeProfileRepository()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ProfileNotifier.build', () {
    test('returns stubProfile when logged out', () {
      final container = _buildContainer(breeder: null);
      expect(container.read(profileProvider), stubProfile);
    });

    test('derives BreederProfile field-by-field from the current Breeder',
        () {
      final container = _buildContainer(breeder: _breeder);
      final profile = container.read(profileProvider);

      expect(profile.name, 'Fazenda X');
      expect(profile.email, 'x@example.com');
      expect(profile.phone, '119999999');
      expect(profile.farmName, 'Fazenda Boa Vista');
      expect(profile.city, 'Uberaba');
      expect(profile.state, 'MG');
      expect(profile.status, BreederStatus.pending);
      expect(profile.associationId, 'assoc1');
      expect(profile.associations, hasLength(1));
      expect(profile.avatarUrl, 'http://avatar');
      // plan/planRenewal come from stubProfile, unrelated to Breeder.
      expect(profile.plan, stubProfile.plan);
    });

    test('null phone/farmName/city/state/associationId fall back to empty '
        'string, not null', () {
      const bare = Breeder(id: 'b1', name: 'X', email: 'x@x.com');
      final container = _buildContainer(breeder: bare);
      final profile = container.read(profileProvider);

      expect(profile.phone, '');
      expect(profile.farmName, '');
      expect(profile.city, '');
      expect(profile.state, '');
      expect(profile.associationId, '');
    });
  });

  group('ProfileNotifier.activate', () {
    test('updates authNotifierProvider with the result, forces status: '
        'active, and preserves the pre-activation city/state rather than '
        'trusting the response', () async {
      final activateResult = _breeder.copyWith(
        status: BreederStatus.pending,
        city: null,
        state: null,
      );
      final repo = FakeProfileRepository(activateResult: activateResult);
      final container = _buildContainer(breeder: _breeder, profileRepository: repo);

      await container.read(profileProvider.notifier).activate(
            name: 'Fazenda X',
            phone: '119999999',
          );

      final updated = container.read(authNotifierProvider)!;
      expect(updated.status, BreederStatus.active);
      // Preserved from the pre-activation breeder, not the (null) response.
      expect(updated.city, 'Uberaba');
      expect(updated.state, 'MG');
    });
  });

  group('ProfileNotifier.updateProfile', () {
    test('updates authNotifierProvider with the raw repository result, no '
        'override (unlike activate)', () async {
      final updateResult = _breeder.copyWith(
        name: 'Novo Nome',
        city: 'Ribeirão Preto',
        state: 'SP',
      );
      final repo = FakeProfileRepository(updateProfileResult: updateResult);
      final container = _buildContainer(breeder: _breeder, profileRepository: repo);

      await container
          .read(profileProvider.notifier)
          .updateProfile(name: 'Novo Nome');

      final updated = container.read(authNotifierProvider)!;
      expect(updated.name, 'Novo Nome');
      expect(updated.city, 'Ribeirão Preto');
      expect(updated.state, 'SP');
    });
  });

  group('ProfileNotifier.update', () {
    test('direct state set', () {
      final container = _buildContainer(breeder: _breeder);
      final replacement = stubProfile.copyWith(name: 'Direct Set');

      container.read(profileProvider.notifier).update(replacement);

      expect(container.read(profileProvider).name, 'Direct Set');
    });
  });

  group('BreederStatisticsNotifier', () {
    test('loading -> success via the repository', () async {
      final repo = FakeProfileRepository(
        statisticsResult: const BreederStatistics(
          activeAnimals: 3,
          likes: 2,
          breederMatches: 1,
        ),
      );
      final container = _buildContainer(profileRepository: repo);

      final stats = await container.read(breederStatisticsProvider.future);

      expect(stats.activeAnimals, 3);
    });

    test('error surfaces as AsyncError', () async {
      final repo = _ThrowingStatisticsRepository();
      // Riverpod 3.x retries failed AsyncNotifier builds with backoff by
      // default (AsyncLoading(...retrying: true)) — disable that here so
      // the failure settles to AsyncError on the first attempt.
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          authNotifierProvider.overrideWith(() => SeededAuthNotifier(null)),
          profileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(breederStatisticsProvider, (_, _) {});
      await container.pump();

      expect(container.read(breederStatisticsProvider), isA<AsyncError>());
    });
  });
}

class _ThrowingStatisticsRepository extends FakeProfileRepository {
  @override
  Future<BreederStatistics> getStatistics() async {
    throw Exception('boom');
  }
}
