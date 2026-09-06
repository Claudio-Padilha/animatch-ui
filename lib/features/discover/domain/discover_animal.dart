import '../../herd/domain/animal_enums.dart';
import '../../herd/domain/herd_animal.dart';

class DiscoverAnimal {
  const DiscoverAnimal({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.photoUrls,
    required this.locationCity,
    required this.locationState,
    this.locationDirections,
    this.age,
    this.registrationCode,
    this.description,
    this.pendingMatchId,
    this.geneticIndices,
  });

  final String id;
  final String name;
  final String species;
  final String breed;
  final String sex;
  final List<String> photoUrls;
  final String locationCity;
  final String locationState;
  final String? locationDirections;
  final int? age;
  final String? registrationCode;
  final String? description;
  final String? pendingMatchId;
  final GeneticIndices? geneticIndices;

  /// "City, ST", or just "ST" when the city is masked (non-owner view of a
  /// free-tier animal), or "" when neither is present.
  String get locationFull =>
      [locationCity, locationState].where((s) => s.isNotEmpty).join(', ');
  String get ageLabel => age != null ? '$age ${age == 1 ? 'ano' : 'anos'}' : '';

  factory DiscoverAnimal.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;

    final breedApiValue = json['breed'] as String? ?? '';
    String breedLabel;
    try {
      breedLabel = AnimalBreed.fromApiValue(breedApiValue).label;
    } catch (_) {
      breedLabel = breedApiValue;
    }

    final sexRaw = json['sex'] as String? ?? 'male';
    final sex = sexRaw == 'male' ? 'Macho' : 'Fêmea';

    final photoUrls = (json['photoUrls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return DiscoverAnimal(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String? ?? '',
      breed: breedLabel,
      sex: sex,
      photoUrls: photoUrls,
      locationCity: address?['city'] as String? ?? '',
      locationState: address?['state'] as String? ?? '',
      locationDirections: address?['directions'] as String?,
      age: (json['age'] as num?)?.toInt(),
      registrationCode: json['registrationNumber'] as String?,
      description: json['description'] as String?,
      pendingMatchId: json['pendingMatchId'] as String?,
      geneticIndices: json['geneticIndices'] is Map
          ? GeneticIndices.fromJson(
              json['geneticIndices'] as Map<String, dynamic>)
          : null,
    );
  }
}
