import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/herd_repository.dart';
import '../domain/animal_enums.dart';
import '../domain/herd_animal.dart';

final herdRepositoryProvider = Provider<HerdRepository>(
  (ref) => HerdRepository(ref.watch(dioProvider)),
);

final animalDetailProvider = FutureProvider.autoDispose
    .family<HerdAnimal, String>((ref, id) =>
        ref.read(herdRepositoryProvider).getAnimal(id));

// ── Herd list state ───────────────────────────────────────────────────────────

class HerdNotifier extends AsyncNotifier<List<HerdAnimal>> {
  @override
  Future<List<HerdAnimal>> build() async {
    final breederId = ref.watch(authNotifierProvider)?.id;
    if (breederId == null) return [];
    return ref.read(herdRepositoryProvider).getAnimals(breederId);
  }

  Future<void> refresh() async {
    final breederId = ref.read(authNotifierProvider)?.id;
    if (breederId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(herdRepositoryProvider).getAnimals(breederId),
    );
  }

  void remove(String id) {
    state.whenData(
      (animals) => state = AsyncData(animals.where((a) => a.id != id).toList()),
    );
  }

  void updateOne(HerdAnimal updated) {
    state.whenData(
      (animals) => state = AsyncData(
        [for (final a in animals) if (a.id == updated.id) updated else a],
      ),
    );
  }
}

final herdProvider =
    AsyncNotifierProvider<HerdNotifier, List<HerdAnimal>>(HerdNotifier.new);

// ── Add animal ────────────────────────────────────────────────────────────────

class AddAnimalNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addAnimal({
    required String name,
    required AnimalSpecies species,
    required AnimalBreed breed,
    required String sexLabel,
    required String propertyName,
    required String zipCode,
    required String city,
    required String state,
    String? description,
    int? qualityScore,
    int? age,
    String? registrationNumber,
    bool available = true,
    Map<String, double?> geneticIndices = const {},
    List<String> imageUrls = const [],
  }) async {
    final breederId = ref.read(authNotifierProvider)!.id;

    final payload = <String, dynamic>{
      'breederId': breederId,
      'name': name,
      'species': species.apiValue,
      'breed': breed.apiValue,
      'sex': sexApiValue[sexLabel]!.apiValue,
      'status': available ? 'active' : 'inactive',
      'address': {
        'directions': propertyName,
        'zipCode': zipCode,
        'city': city,
        'state': state.toUpperCase(),
      },
      if (description != null && description.isNotEmpty)
        'description': description,
      'qualityScore': ?qualityScore,
      'age': ?age,
      if (registrationNumber != null && registrationNumber.isNotEmpty)
        'registrationNumber': registrationNumber,
      if (imageUrls.isNotEmpty) 'photoUrls': imageUrls,
    };

    final filteredIndices = {
      for (final e in geneticIndices.entries)
        if (e.value != null) e.key: e.value,
    };
    if (filteredIndices.isNotEmpty) payload['geneticIndices'] = filteredIndices;

    this.state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(herdRepositoryProvider).addAnimal(payload),
    );

    if (result is AsyncData) {
      await ref.read(herdProvider.notifier).refresh();
      ref.invalidate(breederStatisticsProvider);
    }

    this.state = result.whenData((_) {});
  }
}

final addAnimalProvider =
    AsyncNotifierProvider<AddAnimalNotifier, void>(AddAnimalNotifier.new);

// ── Update animal ─────────────────────────────────────────────────────────────

class UpdateAnimalNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateAnimal({
    required String id,
    required String name,
    required AnimalSpecies species,
    required AnimalBreed breed,
    required String sexLabel,
    required String city,
    required String state,
    required String zipCode,
    required String propertyName,
    String? description,
    int? qualityScore,
    int? age,
    String? registrationNumber,
    bool available = true,
    Map<String, double?> geneticIndices = const {},
    List<String>? imageUrls,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'species': species.apiValue,
      'breed': breed.apiValue,
      'sex': sexApiValue[sexLabel]!.apiValue,
      'status': available ? 'active' : 'inactive',
      'address': {
        'directions': propertyName,
        'zipCode': zipCode,
        'city': city,
        'state': state.toUpperCase(),
      },
      if (description != null && description.isNotEmpty)
        'description': description,
      'qualityScore': ?qualityScore,
      'age': ?age,
      if (registrationNumber != null && registrationNumber.isNotEmpty)
        'registration_number': registrationNumber,
      if (imageUrls != null && imageUrls.isNotEmpty) 'photoUrls': imageUrls,
    };

    final filteredIndices = {
      for (final e in geneticIndices.entries)
        if (e.value != null) e.key: e.value,
    };
    if (filteredIndices.isNotEmpty) payload['geneticIndices'] = filteredIndices;

    this.state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(herdRepositoryProvider).updateAnimal(id, payload),
    );

    if (result is AsyncData<HerdAnimal>) {
      ref.read(herdProvider.notifier).updateOne(result.value);
    }

    this.state = result.whenData((_) {});
  }
}

final updateAnimalProvider =
    AsyncNotifierProvider<UpdateAnimalNotifier, void>(UpdateAnimalNotifier.new);

// ── Toggle animal status ──────────────────────────────────────────────────────

class ToggleAnimalNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggle(String id, {required bool currentlyActive}) async {
    final newStatus = currentlyActive ? 'paused' : 'active';
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(herdRepositoryProvider)
          .updateAnimal(id, {'status': newStatus}),
    );
    if (result is AsyncData<HerdAnimal>) {
      ref.read(herdProvider.notifier).updateOne(result.value);
      ref.invalidate(breederStatisticsProvider);
    }
    state = result.whenData((_) {});
  }
}

final toggleAnimalProvider =
    AsyncNotifierProvider<ToggleAnimalNotifier, void>(ToggleAnimalNotifier.new);

// ── Delete animal ─────────────────────────────────────────────────────────────

class DeleteAnimalNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteAnimal(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(herdRepositoryProvider).deleteAnimal(id),
    );
    if (result is AsyncData) {
      ref.read(herdProvider.notifier).remove(id);
      ref.invalidate(breederStatisticsProvider);
    }
    state = result;
  }
}

final deleteAnimalProvider =
    AsyncNotifierProvider<DeleteAnimalNotifier, void>(DeleteAnimalNotifier.new);
