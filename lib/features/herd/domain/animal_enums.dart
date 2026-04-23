enum AnimalSpecies {
  cattle('cattle', 'Bovino'),
  horse('horse', 'Equino');

  const AnimalSpecies(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AnimalSpecies fromLabel(String label) =>
      values.firstWhere((e) => e.label == label);

  static AnimalSpecies fromApiValue(String value) =>
      values.firstWhere((e) => e.apiValue == value);
}

enum AnimalSex {
  male('male'),
  female('female');

  const AnimalSex(this.apiValue);

  final String apiValue;

  static AnimalSex fromApiValue(String value) =>
      values.firstWhere((e) => e.apiValue == value,
          orElse: () => AnimalSex.male);

  String displayLabel(AnimalSpecies species) => switch ((this, species)) {
        (AnimalSex.male, AnimalSpecies.cattle) => 'Touro',
        (AnimalSex.female, AnimalSpecies.cattle) => 'Vaca',
        (AnimalSex.male, AnimalSpecies.horse) => 'Garanhão',
        (AnimalSex.female, AnimalSpecies.horse) => 'Égua',
      };
}

enum AnimalBreed {
  // Cattle
  nelore('nelore'),
  brahman('brahman'),
  gir('gir'),
  guzera('guzera'),
  tabapua('tabapua'),
  angus('angus'),
  senepol('senepol'),
  limousin('limousin'),
  simmental('simmental'),
  bonsmara('bonsmara'),
  brangus('brangus'),
  girolando('girolando'),
  sindi('sindi'),
  caracu('caracu'),
  // Horse
  mangalargaMarchador('mangalarga_marchador'),
  quartoDeMillha('quarto_de_milha'),
  crioulo('crioulo'),
  mangalargaPaulista('mangalarga_paulista'),
  paintHorse('paint_horse'),
  arabe('arabe'),
  pantaneiro('pantaneiro'),
  lusitano('lusitano'),
  thoroughbred('thoroughbred'),
  appaloosa('appaloosa');

  const AnimalBreed(this.apiValue);

  final String apiValue;

  static const _lowercase = {'de', 'do', 'da', 'e'};

  String get label => apiValue.split('_').indexed.map((entry) {
        final (i, w) = entry;
        return (i == 0 || !_lowercase.contains(w))
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : w;
      }).join(' ');

  static AnimalBreed fromLabel(String label) =>
      values.firstWhere((e) => e.label == label);

  static AnimalBreed fromApiValue(String value) =>
      values.firstWhere((e) => e.apiValue == value);
}

/// Maps the Portuguese UI label for each sex option to its API value.
const sexApiValue = <String, AnimalSex>{
  'Macho': AnimalSex.male,
  'Fêmea': AnimalSex.female,
};

const breedsBySpecies = {
  AnimalSpecies.cattle: [
    AnimalBreed.nelore,
    AnimalBreed.brahman,
    AnimalBreed.gir,
    AnimalBreed.guzera,
    AnimalBreed.tabapua,
    AnimalBreed.angus,
    AnimalBreed.senepol,
    AnimalBreed.limousin,
    AnimalBreed.simmental,
    AnimalBreed.bonsmara,
    AnimalBreed.brangus,
    AnimalBreed.girolando,
    AnimalBreed.sindi,
    AnimalBreed.caracu,
  ],
  AnimalSpecies.horse: [
    AnimalBreed.mangalargaMarchador,
    AnimalBreed.quartoDeMillha,
    AnimalBreed.crioulo,
    AnimalBreed.mangalargaPaulista,
    AnimalBreed.paintHorse,
    AnimalBreed.arabe,
    AnimalBreed.pantaneiro,
    AnimalBreed.lusitano,
    AnimalBreed.thoroughbred,
    AnimalBreed.appaloosa,
  ],
};

const sexLabelsBySpecies = {
  AnimalSpecies.cattle: ['Macho', 'Fêmea'],
  AnimalSpecies.horse: ['Macho', 'Fêmea'],
};
