class BreederStatistics {
  const BreederStatistics({
    required this.activeAnimals,
    required this.likes,
    required this.breederMatches,
  });

  final int activeAnimals;
  final int likes;
  final int breederMatches;

  factory BreederStatistics.fromJson(Map<String, dynamic> json) =>
      BreederStatistics(
        activeAnimals: (json['activeAnimals'] as num).toInt(),
        likes: (json['likes'] as num).toInt(),
        breederMatches: (json['breederMatches'] as num).toInt(),
      );
}
