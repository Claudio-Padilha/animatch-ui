import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/herd_animal.dart';

class _SelectedAnimalNotifier extends Notifier<HerdAnimal?> {
  @override
  HerdAnimal? build() => null;

  void select(HerdAnimal? animal) => state = animal;
}

final selectedAnimalProvider =
    NotifierProvider<_SelectedAnimalNotifier, HerdAnimal?>(
        _SelectedAnimalNotifier.new);
