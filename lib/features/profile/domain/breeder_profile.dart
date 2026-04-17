import '../../auth/domain/breeder.dart';

class BreederProfile {
  const BreederProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.farmName,
    required this.city,
    required this.state,
    required this.status,
    required this.associationId,
    required this.plan,
    required this.planRenewal,
    required this.statsAnimals,
    required this.statsMatches,
    required this.statsLikes,
  });

  final String name;
  final String email;
  final String phone;
  final String farmName;
  final String city;
  final String state;
  final BreederStatus status;
  final String associationId;

  bool get isActive => status == BreederStatus.active;
  final String plan;
  final String planRenewal;
  final int statsAnimals;
  final int statsMatches;
  final int statsLikes;

  String get location =>
      (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : '';

  BreederProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? farmName,
    String? city,
    String? state,
    BreederStatus? status,
    String? associationId,
    String? plan,
    String? planRenewal,
    int? statsAnimals,
    int? statsMatches,
    int? statsLikes,
  }) {
    return BreederProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      farmName: farmName ?? this.farmName,
      city: city ?? this.city,
      state: state ?? this.state,
      status: status ?? this.status,
      associationId: associationId ?? this.associationId,
      plan: plan ?? this.plan,
      planRenewal: planRenewal ?? this.planRenewal,
      statsAnimals: statsAnimals ?? this.statsAnimals,
      statsMatches: statsMatches ?? this.statsMatches,
      statsLikes: statsLikes ?? this.statsLikes,
    );
  }
}

const stubProfile = BreederProfile(
  name: '',
  email: '',
  phone: '',
  farmName: '',
  city: '',
  state: '',
  status: BreederStatus.pending,
  associationId: '',
  plan: 'Premium Individual',
  planRenewal: '14/08/2026',
  statsAnimals: 12,
  statsMatches: 8,
  statsLikes: 34,
);
