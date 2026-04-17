class HerdAnimal {
  const HerdAnimal({
    required this.name,
    required this.breed,
    required this.sex,
    required this.score,
    required this.available,
    this.imagePaths = const [],
    this.registration,
    this.location,
    this.age,
  });

  final String name;
  final String breed;
  final String sex;
  final int score;
  final bool available;
  final List<String> imagePaths;
  final String? registration;
  final String? location;
  final int? age;

  HerdAnimal copyWith({
    String? name,
    String? breed,
    String? sex,
    int? score,
    bool? available,
    List<String>? imagePaths,
    String? registration,
    String? location,
    int? age,
  }) {
    return HerdAnimal(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      score: score ?? this.score,
      available: available ?? this.available,
      imagePaths: imagePaths ?? this.imagePaths,
      registration: registration ?? this.registration,
      location: location ?? this.location,
      age: age ?? this.age,
    );
  }
}

const stubHerdAnimals = [
  HerdAnimal(
    name: 'Imperador da Serra',
    breed: 'Nelore',
    sex: 'Touro',
    score: 87,
    available: true,
    imagePaths: [
      'assets/images/bovino1.jpg',
      'assets/images/bovino1_1.jpg',
      'assets/images/bovino1_2.jpg',
    ],
    registration: 'ABCZ: 4521-MG',
    location: 'Triângulo Mineiro, MG',
    age: 4,
  ),
  HerdAnimal(
    name: 'Dom Carlos IV',
    breed: 'Nelore',
    sex: 'Touro',
    score: 72,
    available: false,
    imagePaths: ['assets/images/bovino3.jpeg'],
    registration: 'ABCZ: 7832-GO',
    location: 'Sul Goiano, GO',
    age: 6,
  ),
  HerdAnimal(
    name: 'Estrela do Sul',
    breed: 'Mangalarga Marchador',
    sex: 'Égua',
    score: 91,
    available: true,
    imagePaths: ['assets/images/bovino5.jpeg'],
    registration: 'ABCCMM: 1204-MG',
    location: 'Zona da Mata, MG',
    age: 3,
  ),
];
