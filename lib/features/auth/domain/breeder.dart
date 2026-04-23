// TODO: migrate to freezed + json_serializable once the API contract is stable

import '../../../shared/domain/breeder_association.dart';

enum BreederStatus {
  pending,
  active,
  rejected;

  static BreederStatus fromJson(String? value) => switch (value) {
        'active' => active,
        'rejected' => rejected,
        _ => pending, // covers 'pending_activation' and any unknown value
      };
}

class Breeder {
  const Breeder({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.farmName,
    this.city,
    this.state,
    this.associationId,
    this.associations = const [],
    this.status = BreederStatus.pending,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String? farmName;
  final String? city;
  final String? state;
  final String? associationId;
  final List<BreederAssociation> associations;
  final BreederStatus status;

  bool get verifiedBreeder => status == BreederStatus.active;

  factory Breeder.fromJson(Map<String, dynamic> json) => Breeder(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['pictureUrl'] as String?,
        phone: json['phone'] as String?,
        farmName: json['propertyName'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        associationId: json['associationId'] as String?,
        associations: (json['associations'] as List<dynamic>? ?? [])
            .map((e) => BreederAssociation.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: BreederStatus.fromJson(json['profileStatus'] as String?),
      );

  Breeder copyWith({
    String? name,
    String? phone,
    String? farmName,
    String? city,
    String? state,
    String? associationId,
    List<BreederAssociation>? associations,
    String? avatarUrl,
    BreederStatus? status,
  }) =>
      Breeder(
        id: id,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        farmName: farmName ?? this.farmName,
        city: city ?? this.city,
        state: state ?? this.state,
        associationId: associationId ?? this.associationId,
        associations: associations ?? this.associations,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        status: status ?? this.status,
      );

}
