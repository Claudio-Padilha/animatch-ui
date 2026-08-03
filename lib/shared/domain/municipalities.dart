class Municipalities {
  const Municipalities(this._citiesByState);

  final Map<String, List<String>> _citiesByState;

  factory Municipalities.fromJson(Map<String, dynamic> json) => Municipalities(
        json.map(
          (state, cities) => MapEntry(state, List<String>.from(cities as List)),
        ),
      );

  List<String> get states => _citiesByState.keys.toList()..sort();

  List<String> citiesOf(String state) => _citiesByState[state] ?? const [];
}
