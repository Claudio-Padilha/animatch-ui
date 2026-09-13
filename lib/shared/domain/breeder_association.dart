class BreederAssociation {
  const BreederAssociation({
    required this.code,
    required this.name,
    this.registrationNumber,
    this.documentUrl,
  });

  final String code;
  final String name;
  final String? registrationNumber;

  /// Cloudinary URL of a photo of the membership card ("carteirinha") or an
  /// animal's Certificado de Registro Genealógico for this association —
  /// evidence backing the self-reported [registrationNumber] for manual
  /// review. Not yet consumed by the backend — see PROD-VERIFY-1.
  final String? documentUrl;

  factory BreederAssociation.fromJson(Map<String, dynamic> json) =>
      BreederAssociation(
        code: json['code'] as String,
        name: json['name'] as String? ?? json['code'] as String,
        registrationNumber: (json['registration_number'] ??
            json['registrationNumber']) as String?,
        documentUrl:
            (json['document_url'] ?? json['documentUrl']) as String?,
      );

  /// The `associations` item on `PATCH /breeders/:id/activate` uses a
  /// snake_case `registration_number` key (the one place associations accept
  /// a registration number — `PATCH /breeders/:id` drops `associations`).
  /// `document_url` follows the same snake_case convention — see PROD-VERIFY-1
  /// for the backend work needed before this key is actually stored.
  Map<String, dynamic> toJson() => {
        'code': code,
        if (registrationNumber != null && registrationNumber!.isNotEmpty)
          'registration_number': registrationNumber,
        if (documentUrl != null && documentUrl!.isNotEmpty)
          'document_url': documentUrl,
      };
}
