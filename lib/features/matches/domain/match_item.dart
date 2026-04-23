import '../../herd/domain/animal_enums.dart';

enum MatchStatus { confirmado, pendente }

class MatchAnimal {
  const MatchAnimal({
    this.id,
    required this.name,
    required this.breed,
    this.imagePath = '',
    this.age,
    this.score,
    this.registry,
    this.depPeso,
    this.depConf,
    this.location,
  });

  final String? id;
  final String name;
  final String breed; // e.g. "Nelore · Macho"
  final String imagePath;
  final int? age;
  final int? score;
  final String? registry;
  final double? depPeso;
  final double? depConf;
  final String? location;

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

    return MatchAnimal(
      id: json['id'] as String?,
      name: json['name'] as String,
      breed: '$breedLabel · $sexLabel',
      age: (json['age'] as num?)?.toInt(),
      score: (json['qualityScore'] as num?)?.toInt(),
      registry: json['registrationNumber'] as String?,
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
    final first =
        MatchAnimal.fromJson(json['firstAnimal'] as Map<String, dynamic>);
    final second =
        MatchAnimal.fromJson(json['secondAnimal'] as Map<String, dynamic>);

    final yours = first.id == animalId ? first : second;
    final theirs = first.id == animalId ? second : first;

    return MatchItem(
      id: json['id'] as String,
      status: _statusFrom(json['status'] as String),
      timeLabel: _timeLabelFrom(json['createdAt'] as String),
      yourAnimal: yours,
      theirAnimal: theirs,
      contact: const MatchContact(breederName: '', phone: ''),
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
