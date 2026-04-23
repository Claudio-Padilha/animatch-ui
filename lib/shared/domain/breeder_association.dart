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
        registrationNumber: json['registrationNumber'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        if (registrationNumber != null)
          'registrationNumber': registrationNumber,
      };
}
