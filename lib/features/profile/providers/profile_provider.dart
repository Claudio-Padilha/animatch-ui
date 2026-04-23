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
    );
  }

  Future<void> activate({
    required String name,
    required String phone,
    String? cpf,
    String? farmName,
    List<BreederAssociation> associations = const [],
    String? pictureUrl,
    required String directions,
    required String zipCode,
    required String city,
    required String state,
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
          directions: directions,
          zipCode: zipCode,
          city: city,
          state: state,
        );
    // A successful PATCH means the backend accepted the activation.
    // Force status=active locally so the UI reflects it immediately,
    // regardless of whether the API echoes the status field back.
    // TODO: remove the copyWith once the backend reliably returns status:'active'
    ref.read(authNotifierProvider.notifier).updateBreeder(
          updated.copyWith(
            status: BreederStatus.active,
            city: city,
            state: state,
          ),
        );
  }

  Future<void> updateProfile({
    required String name,
    String? phone,
    String? farmName,
    String? city,
    String? state,
  }) async {
    final breederId = ref.read(authNotifierProvider)!.id;
    final updated = await ref.read(profileRepositoryProvider).updateProfile(
          breederId: breederId,
          name: name,
          phone: phone,
          farmName: farmName,
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
