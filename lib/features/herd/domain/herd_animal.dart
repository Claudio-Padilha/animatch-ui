import 'package:freezed_annotation/freezed_annotation.dart';

import 'animal_enums.dart';

part 'herd_animal.freezed.dart';
part 'herd_animal.g.dart';

@freezed
abstract class GeneticIndices with _$GeneticIndices {
  const GeneticIndices._();

  const factory GeneticIndices({
    @JsonKey(name: 'birth_weight') double? birthWeight,
    @JsonKey(name: 'milk_restriction_weight') double? milkRestrictionWeight,
    @JsonKey(name: 'weight_18m') double? weight18m,
    @JsonKey(name: 'fertility_index') double? fertilityIndex,
    double? conformacao,
  }) = _GeneticIndices;

  bool get isEmpty =>
      birthWeight == null &&
      milkRestrictionWeight == null &&
      weight18m == null &&
      fertilityIndex == null &&
      conformacao == null;

  factory GeneticIndices.fromJson(Map<String, dynamic> json) =>
      _$GeneticIndicesFromJson(json);
}

@freezed
abstract class HerdAnimal with _$HerdAnimal {
  const HerdAnimal._();

  const factory HerdAnimal({
    required String id,
    required String name,
    required String breed,
    /// Portuguese display label ("Macho" / "Fêmea").
    required String sex,
    required AnimalSpecies species,
    required bool available,
    @Default(<String>[]) List<String> imagePaths,
    String? registration,
    /// Formatted "City, ST" — for display only.
    String? location,
    String? city,
    String? state,
    String? zipCode,
    String? propertyName,
    int? age,
    String? description,
    GeneticIndices? geneticIndices,
  }) = _HerdAnimal;

  /// Hand-written — not a freezed/json_serializable `factory fromJson`,
  /// since this does derived-field transforms (breed/sex labels, status
  /// to bool, address flattening) that don't fit the generated
  /// field-for-field mapping. Naming it `fromJson` still works as a call
  /// site (`HerdAnimal.fromJson(json)`) because it's a static method, not
  /// a factory constructor — freezed only special-cases the latter.
  static HerdAnimal fromJson(Map<String, dynamic> json) {
    final species = AnimalSpecies.fromApiValue(json['species'] as String);
    final sex = AnimalSex.fromApiValue(json['sex'] as String? ?? 'male');
    final address = json['address'] as Map<String, dynamic>?;
    final indicesJson = json['geneticIndices'] as Map<String, dynamic>?;
    final breedApiValue = json['breed'] as String;
    final breedLabel = _breedLabel(breedApiValue);
    return HerdAnimal(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: breedLabel,
      sex: sex == AnimalSex.male ? 'Macho' : 'Fêmea',
      species: species,
      available: (json['status'] as String?) == 'active',
      imagePaths: (json['photoUrls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      age: (json['age'] as num?)?.toInt(),
      registration: (json['registrationNumber'] ?? json['registration_number'])
          as String?,
      // city/zipCode/directions come back null on non-owner views of
      // free-tier animals — compose from whatever parts are present so the
      // label degrades to "state only" instead of rendering "null, SP".
      location: _locationLabel(
        address?['city'] as String?,
        address?['state'] as String?,
      ),
      city: address?['city'] as String?,
      state: address?['state'] as String?,
      zipCode: address?['zipCode'] as String?,
      propertyName: address?['directions'] as String?,
      description: json['description'] as String?,
      geneticIndices:
          indicesJson != null ? GeneticIndices.fromJson(indicesJson) : null,
    );
  }

  static String? _locationLabel(String? city, String? state) {
    final parts = [city, state].where((s) => s != null && s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String _breedLabel(String apiValue) {
    try {
      return AnimalBreed.fromApiValue(apiValue).label;
    } catch (_) {
      return apiValue;
    }
  }
}
