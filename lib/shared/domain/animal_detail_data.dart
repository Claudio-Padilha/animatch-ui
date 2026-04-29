import '../../features/discover/domain/discover_animal.dart';
import '../../features/matches/domain/match_item.dart';

class AnimalDetailData {
  const AnimalDetailData({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.score,
    required this.photoUrls,
    required this.locationCity,
    required this.locationState,
    this.locationDirections,
    this.age,
    this.registrationCode,
    this.description,
    this.pendingMatchId,
  });

  final String id;
  final String name;
  final String species;
  final String breed;
  final String sex; // empty when already combined into breed
  final int score;
  final List<String> photoUrls;
  final String locationCity;
  final String locationState;
  final String? locationDirections;
  final int? age;
  final String? registrationCode;
  final String? description;
  final String? pendingMatchId;

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
        score: a.score,
        photoUrls: a.photoUrls,
        locationCity: a.locationCity,
        locationState: a.locationState,
        locationDirections: a.locationDirections,
        age: a.age,
        registrationCode: a.registrationCode,
        description: a.description,
        pendingMatchId: a.pendingMatchId,
      );

  factory AnimalDetailData.fromMatchAnimal(MatchAnimal a) => AnimalDetailData(
        id: a.id ?? '',
        name: a.name,
        species: a.species,
        breed: a.breed, // already "Breed · Sex" combined
        sex: '',
        score: a.score ?? 0,
        photoUrls: a.photoUrls,
        locationCity: _parseCity(a.location),
        locationState: _parseState(a.location),
        locationDirections: a.locationDirections,
        age: a.age,
        registrationCode: a.registry,
        description: a.description,
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
