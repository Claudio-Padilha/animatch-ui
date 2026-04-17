enum MatchStatus { confirmado, pendente }

class MatchAnimal {
  const MatchAnimal({
    required this.name,
    required this.breed,
    required this.imagePath,
    this.age,
    this.score,
    this.registry,
    this.depPeso,
    this.depConf,
    this.location,
  });

  final String name;
  final String breed; // e.g. "Nelore · Touro"
  final String imagePath;
  final int? age; // anos
  final int? score; // 0–100
  final String? registry; // e.g. "ABCZ: 4521-MG"
  final double? depPeso; // DEP Peso Desmame
  final double? depConf; // DEP Conformação
  final String? location; // e.g. "Triângulo Mineiro, MG"
}

class MatchContact {
  const MatchContact({
    required this.breederName,
    required this.phone, // digits only, no country code — used for Ligar/WhatsApp
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
}

// ─── Stub data ────────────────────────────────────────────────────────────────

const stubMatches = [
  MatchItem(
    id: 'm1',
    status: MatchStatus.confirmado,
    timeLabel: '2 dias atrás',
    yourAnimal: MatchAnimal(
      name: 'Imperador da Serra',
      breed: 'Nelore · Touro',
      imagePath: 'assets/images/bovino1.jpg',
      age: 4,
      score: 87,
      registry: 'ABCZ: 4521-MG',
      depPeso: 12.4,
      depConf: 8.1,
      location: 'Triângulo Mineiro, MG',
    ),
    theirAnimal: MatchAnimal(
      name: 'Estrela Real',
      breed: 'Nelore · Vaca',
      imagePath: 'assets/images/bovino3.jpeg',
      age: 3,
      score: 91,
      registry: 'ABCZ: 7834-GO',
      depPeso: 14.2,
      depConf: 9.5,
      location: 'Sul Goiano, GO',
    ),
    contact: MatchContact(
      breederName: 'João Mendonça',
      phone: '34991234567',
      email: 'joao@fazendaxyz.com.br',
      website: 'fazendaxyz.com.br',
    ),
  ),
  MatchItem(
    id: 'm2',
    status: MatchStatus.pendente,
    timeLabel: 'Hoje',
    yourAnimal: MatchAnimal(
      name: 'Sultão do Cerrado',
      breed: 'Nelore · Touro',
      imagePath: 'assets/images/bovino2.jpeg',
      age: 5,
      score: 79,
      registry: 'ABCZ: 3312-MT',
      depPeso: 9.7,
      depConf: 6.3,
      location: 'Médio-Norte, MT',
    ),
    theirAnimal: MatchAnimal(
      name: 'Lua Nova',
      breed: 'Nelore · Vaca',
      imagePath: 'assets/images/bovino5.jpeg',
      age: 4,
      score: 85,
      registry: 'ABCZ: 5519-MS',
      depPeso: 11.8,
      depConf: 7.9,
      location: 'Pantanal, MS',
    ),
    contact: MatchContact(
      breederName: 'Maria Fernandes',
      phone: '62987654321',
      email: 'maria@fazendanova.com.br',
    ),
  ),
  MatchItem(
    id: 'm3',
    status: MatchStatus.confirmado,
    timeLabel: '5 dias atrás',
    yourAnimal: MatchAnimal(
      name: 'Dom Carlos',
      breed: 'Nelore · Touro',
      imagePath: 'assets/images/bovino2.jpeg',
      age: 6,
      score: 72,
      registry: 'ABCZ: 2201-MS',
      depPeso: 7.5,
      depConf: 5.2,
      location: 'Pantanal, MS',
    ),
    theirAnimal: MatchAnimal(
      name: 'Trovoada da Serra',
      breed: 'Nelore · Vaca',
      imagePath: 'assets/images/bovino4.jpeg',
      age: 4,
      score: 88,
      registry: 'ABCZ: 6643-PR',
      depPeso: 13.1,
      depConf: 8.7,
      location: 'Norte Pioneiro, PR',
    ),
    contact: MatchContact(
      breederName: 'Pedro Albuquerque',
      phone: '67996543210',
      email: 'pedro@rebanhoalbuquerque.com.br',
      website: 'rebanhoalbuquerque.com.br',
    ),
  ),
];
