import '../../features/discover/domain/discover_animal.dart';
import '../../features/herd/domain/herd_animal.dart';
import '../../features/matches/domain/match_item.dart';

class AnimalDetailData {
  const AnimalDetailData({
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
  final String sex; // empty when already combined into breed
  final List<String> photoUrls;
  final String locationCity;
  final String locationState;
  final String? locationDirections;
  final int? age;
  final String? registrationCode;
  final String? description;
  final String? pendingMatchId;
  final GeneticIndices? geneticIndices;

  String get locationFull =>
      [locationCity, locationState].where((s) => s.isNotEmpty).join(', ');

  String get ageLabel =>
      age != null ? '$age ${age == 1 ? 'ano' : 'anos'}' : '';

  factory AnimalDetailData.fromDiscoverAnimal(DiscoverAnimal a) =>
      AnimalDetailData(
        id: a.id,
        name: a.name,
        species: a.species,
        breed: a.breed,
        sex: a.sex,
        photoUrls: a.photoUrls,
        locationCity: a.locationCity,
        locationState: a.locationState,
        locationDirections: a.locationDirections,
        age: a.age,
        registrationCode: a.registrationCode,
        description: a.description,
        pendingMatchId: a.pendingMatchId,
        geneticIndices: a.geneticIndices,
      );

  factory AnimalDetailData.fromMatchAnimal(MatchAnimal a) => AnimalDetailData(
        id: a.id ?? '',
        name: a.name,
        species: a.species,
        breed: a.breed, // already "Breed · Sex" combined
        sex: '',
        photoUrls: a.photoUrls,
        locationCity: _parseCity(a.location),
        locationState: _parseState(a.location),
        locationDirections: a.locationDirections,
        age: a.age,
        registrationCode: a.registry,
        description: a.description,
        geneticIndices: a.geneticIndices,
      );

  /// Used as a provider-backed fallback when navigating to the detail route
  /// without an in-memory `DiscoverAnimal`/`MatchAnimal` already at hand (e.g.
  /// a deep link or restored app state) — see H-6 in docs/production-review.md.
  factory AnimalDetailData.fromHerdAnimal(HerdAnimal a) => AnimalDetailData(
        id: a.id,
        name: a.name,
        species: a.species.apiValue,
        breed: a.breed,
        sex: a.sex,
        photoUrls: a.imagePaths,
        locationCity: a.city ?? '',
        locationState: a.state ?? '',
        locationDirections: a.propertyName,
        age: a.age,
        registrationCode: a.registration,
        description: a.description,
        geneticIndices: a.geneticIndices,
      );

  // location is stored as "City, State" in MatchAnimal
  static String _parseCity(String? location) {
    if (location == null || !location.contains(',')) return location ?? '';
    return location.split(',').first.trim();
  }

  static String _parseState(String? location) {
    if (location == null || !location.contains(',')) return '';
    return location.split(',').last.trim();
  }
}
