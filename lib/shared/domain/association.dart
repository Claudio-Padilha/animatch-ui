class Association {
  const Association({required this.code, required this.name});

  final String code;
  final String name;

  factory Association.fromJson(Map<String, dynamic> json) => Association(
        code: json['code'] as String,
        name: json['name'] as String? ?? json['code'] as String,
      );
}
