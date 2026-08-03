import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/domain/breeder_association.dart';

part 'breeder.freezed.dart';
part 'breeder.g.dart';

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

String _breederStatusToJson(BreederStatus status) => status.name;

@freezed
abstract class Breeder with _$Breeder {
  const Breeder._();

  const factory Breeder({
    required String id,
    required String name,
    required String email,
    @JsonKey(name: 'pictureUrl') String? avatarUrl,
    String? phone,
    @JsonKey(name: 'propertyName') String? farmName,
    String? city,
    String? state,
    String? associationId,
    @Default(<BreederAssociation>[]) List<BreederAssociation> associations,
    @JsonKey(
      name: 'profileStatus',
      fromJson: BreederStatus.fromJson,
      toJson: _breederStatusToJson,
    )
    @Default(BreederStatus.pending)
    BreederStatus status,
  }) = _Breeder;

  bool get verifiedBreeder => status == BreederStatus.active;

  factory Breeder.fromJson(Map<String, dynamic> json) =>
      _$BreederFromJson(json);
}
