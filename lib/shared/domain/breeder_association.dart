class BreederAssociation {
  const BreederAssociation({
    required this.code,
    required this.name,
    this.registrationNumber,
  });

  final String code;
  final String name;
  final String? registrationNumber;

  factory BreederAssociation.fromJson(Map<String, dynamic> json) =>
      BreederAssociation(
        code: json['code'] as String,
        name: json['name'] as String? ?? json['code'] as String,
        registrationNumber: (json['registration_number'] ??
            json['registrationNumber']) as String?,
      );

  /// The `associations` item on `PATCH /breeders/:id/activate` uses a
  /// snake_case `registration_number` key (the one place associations accept
  /// a registration number — `PATCH /breeders/:id` drops `associations`).
  Map<String, dynamic> toJson() => {
        'code': code,
        if (registrationNumber != null && registrationNumber!.isNotEmpty)
          'registration_number': registrationNumber,
      };
}
