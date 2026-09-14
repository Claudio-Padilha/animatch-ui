enum AssociationVerificationStatus {
  unsubmitted,
  pending,
  approved,
  rejected;

  static AssociationVerificationStatus fromJson(String? value) =>
      switch (value) {
        'pending' => pending,
        'approved' => approved,
        'rejected' => rejected,
        _ => unsubmitted,
      };
}

class BreederAssociation {
  const BreederAssociation({
    required this.code,
    required this.name,
    this.registrationNumber,
    this.documentUrl,
    this.verificationStatus = AssociationVerificationStatus.unsubmitted,
    this.rejectionReason,
  });

  final String code;
  final String name;
  final String? registrationNumber;

  /// Cloudinary URL of a photo of the membership card ("carteirinha") or an
  /// animal's Certificado de Registro Genealógico for this association —
  /// evidence backing the self-reported [registrationNumber] for manual
  /// review.
  final String? documentUrl;

  /// Admin-review state of [documentUrl] — set server-side only, never sent
  /// back on `toJson()`. Only present on `/activate` and `PATCH /breeders/:id`
  /// responses (not `/auth/sync-breeder`, which omits `associations`
  /// entirely).
  final AssociationVerificationStatus verificationStatus;

  /// Set by an admin when [verificationStatus] is `rejected`; null otherwise.
  final String? rejectionReason;

  factory BreederAssociation.fromJson(Map<String, dynamic> json) =>
      BreederAssociation(
        code: json['code'] as String,
        name: json['name'] as String? ?? json['code'] as String,
        registrationNumber: (json['registration_number'] ??
            json['registrationNumber']) as String?,
        documentUrl:
            (json['document_url'] ?? json['documentUrl']) as String?,
        verificationStatus: AssociationVerificationStatus.fromJson(
            json['verificationStatus'] as String?),
        rejectionReason: json['rejectionReason'] as String?,
      );

  /// The `associations` item on `PATCH /breeders/:id/activate` uses a
  /// snake_case `registration_number` key (the one place associations accept
  /// a registration number — `PATCH /breeders/:id` drops `associations`).
  /// `document_url` follows the same snake_case convention.
  /// `verificationStatus`/`rejectionReason` are admin-only and never sent by
  /// the client.
  Map<String, dynamic> toJson() => {
        'code': code,
        if (registrationNumber != null && registrationNumber!.isNotEmpty)
          'registration_number': registrationNumber,
        if (documentUrl != null && documentUrl!.isNotEmpty)
          'document_url': documentUrl,
      };
}
