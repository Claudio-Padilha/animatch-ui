import 'package:freezed_annotation/freezed_annotation.dart';

import '../../herd/domain/animal_enums.dart';
import '../../herd/domain/herd_animal.dart';

part 'match_item.freezed.dart';

enum MatchStatus { confirmado, pendente }

@freezed
abstract class MatchAnimal with _$MatchAnimal {
  const MatchAnimal._();

  const factory MatchAnimal({
    String? id,
    required String name,
    required String breed, // e.g. "Nelore · Macho"
    @Default('cattle') String species,
    @Default(<String>[]) List<String> photoUrls,
    int? age,
    String? registry,
    String? location,
    String? locationDirections,
    String? description,
    GeneticIndices? geneticIndices,
  }) = _MatchAnimal;

  String get imagePath => photoUrls.isNotEmpty ? photoUrls.first : '';

  double? get depPeso => geneticIndices?.milkRestrictionWeight;
  double? get depConf => geneticIndices?.conformacao;

  /// Hand-written, not a freezed `factory fromJson` — see the equivalent
  /// note on `HerdAnimal.fromJson`.
  static MatchAnimal fromJson(Map<String, dynamic> json) {
    final breedApiValue = json['breed'] as String? ?? '';
    String breedLabel;
    try {
      breedLabel = AnimalBreed.fromApiValue(breedApiValue).label;
    } catch (_) {
      breedLabel = breedApiValue;
    }

    final sexRaw = json['sex'] as String? ?? 'male';
    final sexLabel = sexRaw == 'male' ? 'Macho' : 'Fêmea';

    final photoUrls = (json['photoUrls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final address = json['address'] as Map<String, dynamic>?;
    final city = address?['city'] as String? ?? '';
    final state = address?['state'] as String? ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');

    return MatchAnimal(
      id: json['id'] as String?,
      name: json['name'] as String,
      breed: '$breedLabel · $sexLabel',
      species: json['species'] as String? ?? 'cattle',
      photoUrls: photoUrls,
      age: (json['age'] as num?)?.toInt(),
      registry: json['registrationNumber'] as String?,
      location: location.isNotEmpty ? location : null,
      locationDirections: address?['directions'] as String?,
      description: json['description'] as String?,
      geneticIndices: json['geneticIndices'] is Map
          ? GeneticIndices.fromJson(
              json['geneticIndices'] as Map<String, dynamic>)
          : null,
    );
  }
}

@freezed
abstract class MatchContact with _$MatchContact {
  const factory MatchContact({
    required String breederName,
    required String phone,
    String? email,
    String? website,
  }) = _MatchContact;
}

@freezed
abstract class MatchItem with _$MatchItem {
  const MatchItem._();

  const factory MatchItem({
    required String id,
    required MatchStatus status,
    required String timeLabel,
    required MatchAnimal yourAnimal,
    required MatchAnimal theirAnimal,
    required MatchContact contact,
  }) = _MatchItem;

  /// Hand-written, not a freezed `factory fromJson` — this also takes an
  /// extra required `animalId` param to resolve yours-vs-theirs, which a
  /// generated single-arg `fromJson` couldn't support anyway. See the
  /// equivalent note on `HerdAnimal.fromJson`.
  static MatchItem fromJson(
    Map<String, dynamic> json, {
    required String animalId,
  }) {
    final firstJson = json['firstAnimal'] as Map<String, dynamic>;
    final secondJson = json['secondAnimal'] as Map<String, dynamic>;

    final first = MatchAnimal.fromJson(firstJson);
    final second = MatchAnimal.fromJson(secondJson);

    final isFirst = first.id == animalId;
    final yours = isFirst ? first : second;
    final theirs = isFirst ? second : first;
    final theirJson = isFirst ? secondJson : firstJson;

    return MatchItem(
      id: json['id'] as String,
      status: _statusFrom(json['status'] as String),
      timeLabel: _timeLabelFrom(json['createdAt'] as String),
      yourAnimal: yours,
      theirAnimal: theirs,
      contact: MatchContact(
        breederName: theirJson['breederName'] as String? ?? '',
        phone: '',
        email: theirJson['breederEmail'] as String?,
      ),
    );
  }

  static MatchStatus _statusFrom(String s) =>
      s == 'confirmed' ? MatchStatus.confirmado : MatchStatus.pendente;

  static String _timeLabelFrom(String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return '1 dia atrás';
    return '${diff.inDays} dias atrás';
  }
}
