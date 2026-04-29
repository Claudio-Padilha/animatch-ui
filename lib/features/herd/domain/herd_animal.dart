import 'animal_enums.dart';

class GeneticIndices {
  const GeneticIndices({
    this.birthWeight,
    this.milkRestrictionWeight,
    this.weight18m,
    this.fertilityIndex,
  });

  final double? birthWeight;
  final double? milkRestrictionWeight;
  final double? weight18m;
  final double? fertilityIndex;

  bool get isEmpty =>
      birthWeight == null &&
      milkRestrictionWeight == null &&
      weight18m == null &&
      fertilityIndex == null;

  factory GeneticIndices.fromJson(Map<String, dynamic> json) => GeneticIndices(
        birthWeight: (json['birth_weight'] as num?)?.toDouble(),
        milkRestrictionWeight:
            (json['milk_restriction_weight'] as num?)?.toDouble(),
        weight18m: (json['weight_18m'] as num?)?.toDouble(),
        fertilityIndex: (json['fertility_index'] as num?)?.toDouble(),
      );
}

class HerdAnimal {
  const HerdAnimal({
    required this.id,
    required this.name,
    required this.breed,
    required this.sex,
    required this.species,
    required this.score,
    required this.available,
    this.imagePaths = const [],
    this.registration,
    this.location,
    this.city,
    this.state,
    this.zipCode,
    this.propertyName,
    this.age,
    this.description,
    this.geneticIndices,
  });

  final String id;
  final String name;
  final String breed;
  /// Portuguese display label ("Macho" / "Fêmea").
  final String sex;
  final AnimalSpecies species;
  final int score;
  final bool available;
  final List<String> imagePaths;
  final String? registration;
  /// Formatted "City, ST" — for display only.
  final String? location;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? propertyName;
  final int? age;
  final String? description;
  final GeneticIndices? geneticIndices;

  factory HerdAnimal.fromJson(Map<String, dynamic> json) {
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
      score: (json['qualityScore'] as num?)?.toInt() ?? 0,
      available: (json['status'] as String?) == 'active',
      imagePaths: (json['photoUrls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      age: (json['age'] as num?)?.toInt(),
      registration: json['registration_number'] as String?,
      location: address != null
          ? '${address['city']}, ${address['state']}'
          : null,
      city: address?['city'] as String?,
      state: address?['state'] as String?,
      zipCode: address?['zipCode'] as String?,
      propertyName: address?['directions'] as String?,
      description: json['description'] as String?,
      geneticIndices:
          indicesJson != null ? GeneticIndices.fromJson(indicesJson) : null,
    );
  }

  static String _breedLabel(String apiValue) {
    try {
      return AnimalBreed.fromApiValue(apiValue).label;
    } catch (_) {
      return apiValue;
    }
  }

  HerdAnimal copyWith({
    String? id,
    String? name,
    String? breed,
    String? sex,
    AnimalSpecies? species,
    int? score,
    bool? available,
    List<String>? imagePaths,
    String? registration,
    String? location,
    String? city,
    String? state,
    String? zipCode,
    String? propertyName,
    int? age,
    String? description,
    GeneticIndices? geneticIndices,
  }) {
    return HerdAnimal(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      species: species ?? this.species,
      score: score ?? this.score,
      available: available ?? this.available,
      imagePaths: imagePaths ?? this.imagePaths,
      registration: registration ?? this.registration,
      location: location ?? this.location,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      propertyName: propertyName ?? this.propertyName,
      age: age ?? this.age,
      description: description ?? this.description,
      geneticIndices: geneticIndices ?? this.geneticIndices,
    );
  }
}
