import '../../herd/domain/animal_enums.dart';

class DiscoverAnimal {
  const DiscoverAnimal({
    required this.id,
    required this.name,
    required this.breed,
    required this.sex,
    required this.age,
    required this.score,
    required this.distanceLabel,
    required this.locationFull,
    required this.breederName,
    required this.isVerified,
    required this.imagePaths,
    required this.depWeight,
    required this.depConf,
    required this.registrationCode,
    this.pendingMatchId,
  });

  final String id;
  final String name;
  final String breed;
  final String sex;
  final String age;
  final int score;
  final String distanceLabel;
  final String locationFull;
  final String breederName;
  final bool isVerified;
  final List<String> imagePaths;
  final double depWeight;
  final double depConf;
  final String registrationCode;
  final String? pendingMatchId;

  factory DiscoverAnimal.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    final breeder = json['breeder'] as Map<String, dynamic>?;
    final genetics = json['geneticIndices'] as Map<String, dynamic>?;
    final distanceKm = (json['distanceKm'] as num?)?.toInt();
    final state = address?['state'] as String?;
    final ageInt = (json['age'] as num?)?.toInt();

    final breedApiValue = json['breed'] as String? ?? '';
    String breedLabel;
    try {
      breedLabel = AnimalBreed.fromApiValue(breedApiValue).label;
    } catch (_) {
      breedLabel = breedApiValue;
    }

    final sexRaw = json['sex'] as String? ?? 'male';
    final sex = sexRaw == 'male' ? 'Macho' : 'Fêmea';

    final imageUrls = (json['imageUrls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final distanceLabel = distanceKm != null
        ? '~$distanceKm km${state != null ? ' · $state' : ''}'
        : (state ?? '');

    return DiscoverAnimal(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: breedLabel,
      sex: sex,
      age: ageInt != null ? '$ageInt ${ageInt == 1 ? 'ano' : 'anos'}' : '',
      score: (json['qualityScore'] as num?)?.toInt() ?? 0,
      distanceLabel: distanceLabel,
      locationFull: address != null
          ? '${address['city']}, ${address['state']}'
          : '',
      breederName: breeder?['name'] as String? ?? '',
      isVerified: breeder?['isVerified'] as bool? ?? false,
      imagePaths: imageUrls,
      depWeight: (genetics?['depWeight'] as num?)?.toDouble() ?? 0.0,
      depConf: (genetics?['depConf'] as num?)?.toDouble() ?? 0.0,
      registrationCode: json['registrationNumber'] as String? ?? '',
      pendingMatchId: json['pendingMatchId'] as String?,
    );
  }
}
