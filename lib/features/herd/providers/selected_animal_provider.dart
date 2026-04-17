import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/herd_animal.dart';

final selectedAnimalProvider = StateProvider<HerdAnimal?>((ref) => null);
