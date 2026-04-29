import '../../herd/domain/animal_enums.dart';

enum MatchStatus { confirmado, pendente }

class MatchAnimal {
  const MatchAnimal({
    this.id,
    required this.name,
    required this.breed,
    this.species = 'cattle',
    this.photoUrls = const [],
    this.age,
    this.score,
    this.registry,
    this.depPeso,
    this.depConf,
    this.location,
    this.locationDirections,
    this.description,
  });

  final String? id;
  final String name;
  final String breed; // e.g. "Nelore · Macho"
  final String species;
  final List<String> photoUrls;
  final int? age;
  final int? score;
  final String? registry;
  final double? depPeso;
  final double? depConf;
  final String? location;
  final String? locationDirections;
  final String? description;

  String get imagePath => photoUrls.isNotEmpty ? photoUrls.first : '';

  factory MatchAnimal.fromJson(Map<String, dynamic> json) {
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
      score: (json['qualityScore'] as num?)?.toInt(),
      registry: json['registrationNumber'] as String?,
      location: location.isNotEmpty ? location : null,
      locationDirections: address?['directions'] as String?,
      description: json['description'] as String?,
    );
  }
}

class MatchContact {
  const MatchContact({
    required this.breederName,
    required this.phone,
    this.email,
    this.website,
  });

  final String breederName;
  final String phone;
  final String? email;
  final String? website;
}

class MatchItem {
  const MatchItem({
    required this.id,
    required this.status,
    required this.timeLabel,
    required this.yourAnimal,
    required this.theirAnimal,
    required this.contact,
  });

  final String id;
  final MatchStatus status;
  final String timeLabel;
  final MatchAnimal yourAnimal;
  final MatchAnimal theirAnimal;
  final MatchContact contact;

  factory MatchItem.fromJson(
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
