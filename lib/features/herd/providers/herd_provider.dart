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

/// The 4 keys the `geneticIndices` object must carry — all-or-nothing: the
/// backend rejects a partial object (and a `0`, which must be `null`).
const _geneticIndexKeys = [
  'birth_weight',
  'milk_restriction_weight',
  'weight_18m',
  'fertility_index',
];

/// Shared payload shape for `POST /animals` and `PATCH /animals/:id`.
/// Both endpoints share `CreateAnimalBody`; `PATCH` is a shallow partial, so
/// `address` still needs `city`/`state` and `geneticIndices` still needs all
/// four keys — which is exactly what this always sends.
Map<String, dynamic> buildAnimalPayload({
  required String name,
  required AnimalSpecies species,
  required AnimalBreed breed,
  required String sexLabel,
  required String propertyName,
  required String zipCode,
  required String city,
  required String state,
  required bool available,
  String? description,
  int? age,
  String? registrationNumber,
  Map<String, double?> geneticIndices = const {},
  List<String>? imageUrls,
}) {
  final payload = <String, dynamic>{
    'name': name,
    'species': species.apiValue,
    'breed': breed.apiValue,
    'sex': sexApiValue[sexLabel]!.apiValue,
    // status enum is 'active' | 'paused' — never 'inactive'.
    'status': available ? 'active' : 'paused',
    'address': {
      'directions': propertyName,
      'zipCode': zipCode,
      'city': city,
      'state': state.toUpperCase(),
    },
    if (description != null && description.isNotEmpty) 'description': description,
    'age': ?age,
    // Canonical key is camelCase `registrationNumber` on both POST and PATCH
    // (was inconsistently snake_case on update — K-1).
    if (registrationNumber != null && registrationNumber.isNotEmpty)
      'registrationNumber': registrationNumber,
    if (imageUrls != null && imageUrls.isNotEmpty) 'photoUrls': imageUrls,
  };

  final indices = {
    for (final k in _geneticIndexKeys) k: _positiveOrNull(geneticIndices[k]),
  };
  if (indices.values.any((v) => v != null)) payload['geneticIndices'] = indices;

  return payload;
}

/// The backend requires each genetic index to be `> 0` or `null` — a `0` (or a
/// stray negative) is a 400, so collapse those to `null`.
double? _positiveOrNull(double? v) => (v != null && v > 0) ? v : null;

/// Fetches one of the caller's **own** animals by id (`GET /animals/:id` is
/// owner-only). Used by `myAnimalDetail` / `editAnimal`.
final animalDetailProvider = FutureProvider.autoDispose
    .family<HerdAnimal, String>((ref, id) =>
        ref.read(herdRepositoryProvider).getAnimal(id));

// ── Herd list state ───────────────────────────────────────────────────────────

class HerdNotifier extends AsyncNotifier<List<HerdAnimal>> {
  @override
  Future<List<HerdAnimal>> build() async {
    // Watch auth so the herd reloads on login/logout; the backend scopes
    // `GET /animals` to the token holder, so no id is passed.
    final loggedIn = ref.watch(authNotifierProvider) != null;
    if (!loggedIn) return [];
    return ref.read(herdRepositoryProvider).getAnimals();
  }

  Future<void> refresh() async {
    if (ref.read(authNotifierProvider) == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(herdRepositoryProvider).getAnimals(),
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
    int? age,
    String? registrationNumber,
    bool available = true,
    Map<String, double?> geneticIndices = const {},
    List<String> imageUrls = const [],
  }) async {
    final payload = buildAnimalPayload(
      name: name,
      species: species,
      breed: breed,
      sexLabel: sexLabel,
      propertyName: propertyName,
      zipCode: zipCode,
      city: city,
      state: state,
      available: available,
      description: description,
      age: age,
      registrationNumber: registrationNumber,
      geneticIndices: geneticIndices,
      imageUrls: imageUrls.isEmpty ? null : imageUrls,
    );

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
    int? age,
    String? registrationNumber,
    bool available = true,
    Map<String, double?> geneticIndices = const {},
    List<String>? imageUrls,
  }) async {
    final payload = buildAnimalPayload(
      name: name,
      species: species,
      breed: breed,
      sexLabel: sexLabel,
      propertyName: propertyName,
      zipCode: zipCode,
      city: city,
      state: state,
      available: available,
      description: description,
      age: age,
      registrationNumber: registrationNumber,
      geneticIndices: geneticIndices,
      imageUrls: imageUrls,
    );

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
