enum DistanceRange {
  upTo50,
  upTo100,
  upTo250,
  upTo500,
  upTo1000,
  any;

  String get label => switch (this) {
        DistanceRange.upTo50 => 'Até 50 km',
        DistanceRange.upTo100 => 'Até 100 km',
        DistanceRange.upTo250 => 'Até 250 km',
        DistanceRange.upTo500 => 'Até 500 km',
        DistanceRange.upTo1000 => 'Até 1.000 km',
        DistanceRange.any => 'Qualquer distância',
      };

  int? get maxKm => switch (this) {
        DistanceRange.upTo50 => 50,
        DistanceRange.upTo100 => 100,
        DistanceRange.upTo250 => 250,
        DistanceRange.upTo500 => 500,
        DistanceRange.upTo1000 => 1000,
        DistanceRange.any => null,
      };

  static DistanceRange fromLabel(String label) =>
      DistanceRange.values.firstWhere((e) => e.label == label);
}
