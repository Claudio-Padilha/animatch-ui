import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/domain/association.dart';
import '../../../shared/domain/breeder_association.dart';
import '../../auth/domain/breeder.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';
import '../domain/breeder_profile.dart';
import '../domain/breeder_statistics.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

class ProfileNotifier extends Notifier<BreederProfile> {
  @override
  BreederProfile build() {
    final breeder = ref.watch(authNotifierProvider);
    if (breeder == null) return stubProfile;
    return stubProfile.copyWith(
      name: breeder.name,
      email: breeder.email,
      phone: breeder.phone ?? '',
      farmName: breeder.farmName ?? '',
      city: breeder.city ?? '',
      state: breeder.state ?? '',
      status: breeder.status,
      associationId: breeder.associationId ?? '',
      associations: breeder.associations,
      avatarUrl: breeder.avatarUrl,
    );
  }

  Future<void> activate({
    required String name,
    required String phone,
    String? cpf,
    String? farmName,
    List<BreederAssociation> associations = const [],
    String? pictureUrl,
  }) async {
    final breederId = ref.read(authNotifierProvider)!.id;
    final updated = await ref.read(profileRepositoryProvider).activate(
          breederId: breederId,
          name: name,
          phone: phone,
          cpf: cpf,
          farmName: farmName,
          associations: associations,
          pictureUrl: pictureUrl,
        );
    final current = ref.read(authNotifierProvider);
    ref.read(authNotifierProvider.notifier).updateBreeder(
          updated.copyWith(
            status: BreederStatus.active,
            city: current?.city,
            state: current?.state,
          ),
        );
  }

  Future<void> updateProfile({
    required String name,
    String? phone,
    String? farmName,
    String? pictureUrl,
    List<BreederAssociation>? associations,
    String? directions,
    String? zipCode,
    String? city,
    String? state,
  }) async {
    final breederId = ref.read(authNotifierProvider)!.id;
    final updated = await ref.read(profileRepositoryProvider).updateProfile(
          breederId: breederId,
          name: name,
          phone: phone,
          farmName: farmName,
          pictureUrl: pictureUrl,
          associations: associations,
          directions: directions,
          zipCode: zipCode,
          city: city,
          state: state,
        );
    ref.read(authNotifierProvider.notifier).updateBreeder(updated);
  }

  void update(BreederProfile updated) => state = updated;
}

final profileProvider =
    NotifierProvider<ProfileNotifier, BreederProfile>(ProfileNotifier.new);

class BreederStatisticsNotifier
    extends AsyncNotifier<BreederStatistics> {
  @override
  Future<BreederStatistics> build() =>
      ref.read(profileRepositoryProvider).getStatistics();
}

final breederStatisticsProvider =
    AsyncNotifierProvider<BreederStatisticsNotifier, BreederStatistics>(
        BreederStatisticsNotifier.new);

final associationsProvider = FutureProvider<List<Association>>(
  (ref) => ref.read(profileRepositoryProvider).getAssociations(),
);
