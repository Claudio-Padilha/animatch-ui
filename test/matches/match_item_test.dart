import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/matches/domain/match_item.dart';

Map<String, dynamic> _matchJson({required String status}) => {
      'id': 'm1',
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
      'firstAnimal': {
        'id': 'me',
        'name': 'MyBull',
        'breed': 'nelore',
        'sex': 'male',
      },
      'secondAnimal': {
        'id': 'them',
        'name': 'TheirCow',
        'breed': 'nelore',
        'sex': 'female',
        'breederName': 'Fazenda Y',
      },
    };

Map<String, dynamic> _detailJson({required String status}) => {
      'id': 'm1',
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
      'yourAnimal': {
        'id': 'me',
        'name': 'MyBull',
        'breed': 'nelore',
        'sex': 'male',
      },
      'theirAnimal': {
        'id': 'them',
        'name': 'TheirCow',
        'breed': 'nelore',
        'sex': 'female',
      },
      'theirBreeder': {
        'name': 'Fazenda Y',
        if (status == 'confirmed') 'phone': '5511999998888',
        if (status == 'confirmed') 'email': 'y@example.com',
      },
    };

void main() {
  test('fromJson resolves yours vs. theirs from animalId', () {
    final json = _matchJson(status: 'confirmed');
    final match = MatchItem.fromJson(json, animalId: 'me');

    expect(match.yourAnimal.name, 'MyBull');
    expect(match.theirAnimal.name, 'TheirCow');
    expect(match.contact.breederName, 'Fazenda Y');
    // The list endpoint no longer embeds breeder contact — email comes from
    // GET /matches/:id (fromDetailJson) now.
    expect(match.contact.email, isNull);
    expect(match.status, MatchStatus.confirmado);
  });

  group('fromDetailJson (GET /matches/:id)', () {
    test('reads yours/theirs directly and pulls contact from theirBreeder', () {
      final match = MatchItem.fromDetailJson(_detailJson(status: 'confirmed'));

      expect(match.yourAnimal.name, 'MyBull');
      expect(match.theirAnimal.name, 'TheirCow');
      expect(match.contact.breederName, 'Fazenda Y');
      expect(match.contact.phone, '5511999998888');
      expect(match.contact.email, 'y@example.com');
      expect(match.status, MatchStatus.confirmado);
    });

    test('leaves phone/email empty when the match is not confirmed', () {
      final match = MatchItem.fromDetailJson(_detailJson(status: 'pending'));

      expect(match.status, MatchStatus.pendente);
      expect(match.contact.phone, '');
      expect(match.contact.email, isNull);
    });

    test('tolerates a null phone on a confirmed match (breeders.phone is '
        'nullable) — falls back to empty, which hides the WhatsApp row', () {
      final json = _detailJson(status: 'confirmed')
        ..['theirBreeder'] = {'name': 'Fazenda Y', 'phone': null, 'email': 'y@e.com'};
      final match = MatchItem.fromDetailJson(json);

      expect(match.contact.phone, '');
      expect(match.contact.email, 'y@e.com');
    });
  });

  test('fromJson flips yours/theirs when animalId matches the other side', () {
    final json = _matchJson(status: 'pending');
    final match = MatchItem.fromJson(json, animalId: 'them');

    expect(match.yourAnimal.name, 'TheirCow');
    expect(match.theirAnimal.name, 'MyBull');
    expect(match.status, MatchStatus.pendente);
  });

  test('generated equality treats same-value instances as equal', () {
    final json = _matchJson(status: 'confirmed');
    final a = MatchItem.fromJson(json, animalId: 'me');
    final b = MatchItem.fromJson(json, animalId: 'me');
    expect(a, b);
  });

  test('MatchAnimal.imagePath falls back to empty string with no photos', () {
    const animal = MatchAnimal(name: 'X', breed: 'Nelore · Macho');
    expect(animal.imagePath, '');
  });

  test('MatchAnimal.depPeso/depConf read through geneticIndices', () {
    const animal = MatchAnimal(
      name: 'X',
      breed: 'Nelore · Macho',
      geneticIndices: GeneticIndices(milkRestrictionWeight: 12.5, conformacao: 7),
    );
    expect(animal.depPeso, 12.5);
    expect(animal.depConf, 7);
  });

  test('MatchAnimal.fromJson falls back to the raw API value when breed is '
      'not a known AnimalBreed enum value, instead of throwing', () {
    final animal = MatchAnimal.fromJson({
      'id': 'a1',
      'name': 'X',
      'breed': 'some_future_breed',
      'sex': 'male',
    });

    expect(animal.breed, 'some_future_breed · Macho');
  });

  test('MatchAnimal.fromJson flattens city/state address into location',
      () {
    final animal = MatchAnimal.fromJson({
      'id': 'a1',
      'name': 'X',
      'breed': 'nelore',
      'sex': 'male',
      'address': {'city': 'Uberaba', 'state': 'MG'},
    });

    expect(animal.location, 'Uberaba, MG');
  });

  test('MatchAnimal.fromJson renders "state only" when the city is masked '
      '(non-owner view of a free-tier animal)', () {
    final animal = MatchAnimal.fromJson({
      'id': 'a1',
      'name': 'X',
      'breed': 'nelore',
      'sex': 'male',
      'address': {'city': null, 'state': 'MG'},
    });

    expect(animal.location, 'MG');
    expect(animal.locationDirections, isNull);
  });

  group('_timeLabelFrom (via MatchItem.fromJson\'s createdAt)', () {
    test('"Hoje" for a match created earlier today', () {
      final json = _matchJson(status: 'pending')
        ..['createdAt'] = DateTime.now().toIso8601String();
      final match = MatchItem.fromJson(json, animalId: 'me');
      expect(match.timeLabel, 'Hoje');
    });

    test('singular "1 dia atrás" for exactly one day ago', () {
      final json = _matchJson(status: 'pending')
        ..['createdAt'] =
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final match = MatchItem.fromJson(json, animalId: 'me');
      expect(match.timeLabel, '1 dia atrás');
    });

    test('plural "X dias atrás" for more than one day ago', () {
      final json = _matchJson(status: 'pending')
        ..['createdAt'] =
            DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      final match = MatchItem.fromJson(json, animalId: 'me');
      expect(match.timeLabel, '5 dias atrás');
    });

    test('malformed createdAt falls back to "now" (Hoje) instead of '
        'crashing fromJson', () {
      final json = _matchJson(status: 'pending')..['createdAt'] = 'not-a-date';
      final match = MatchItem.fromJson(json, animalId: 'me');
      expect(match.timeLabel, 'Hoje');
    });
  });
}
