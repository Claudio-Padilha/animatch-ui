import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/profile/domain/breeder_profile.dart';
import 'package:animatch/shared/domain/breeder_association.dart';

void main() {
  group('copyWith', () {
    test('every field is included — no silent drops (hand-rolled, not '
        'freezed; same class of bug M-1 fixed in Breeder)', () {
      const original = BreederProfile(
        name: 'A',
        email: 'a@x.com',
        phone: '111',
        farmName: 'Farm A',
        city: 'CityA',
        state: 'SA',
        status: BreederStatus.pending,
        associationId: 'assoc1',
        avatarUrl: 'http://a',
        plan: 'Plan A',
        planRenewal: '01/01/2026',
      );

      final updated = original.copyWith(
        name: 'B',
        email: 'b@x.com',
        phone: '222',
        farmName: 'Farm B',
        city: 'CityB',
        state: 'SB',
        status: BreederStatus.active,
        associationId: 'assoc2',
        associations: const [
          BreederAssociation(code: 'ABCZ', name: 'ABCZ Assoc'),
        ],
        avatarUrl: 'http://b',
        plan: 'Plan B',
        planRenewal: '02/02/2026',
      );

      expect(updated.name, 'B');
      expect(updated.email, 'b@x.com');
      expect(updated.phone, '222');
      expect(updated.farmName, 'Farm B');
      expect(updated.city, 'CityB');
      expect(updated.state, 'SB');
      expect(updated.status, BreederStatus.active);
      expect(updated.associationId, 'assoc2');
      expect(updated.associations, hasLength(1));
      expect(updated.avatarUrl, 'http://b');
      expect(updated.plan, 'Plan B');
      expect(updated.planRenewal, '02/02/2026');
    });

    test('omitted fields fall back to the original values, not defaults',
        () {
      const original = BreederProfile(
        name: 'A',
        email: 'a@x.com',
        phone: '111',
        farmName: 'Farm A',
        city: 'CityA',
        state: 'SA',
        status: BreederStatus.active,
        associationId: 'assoc1',
        plan: 'Plan A',
        planRenewal: '01/01/2026',
      );

      final updated = original.copyWith(name: 'B');

      expect(updated.name, 'B');
      expect(updated.email, 'a@x.com');
      expect(updated.status, BreederStatus.active);
      expect(updated.plan, 'Plan A');
    });
  });

  group('isActive', () {
    test('true only when status is active', () {
      const active = BreederProfile(
        name: '',
        email: '',
        phone: '',
        farmName: '',
        city: '',
        state: '',
        status: BreederStatus.active,
        associationId: '',
        plan: '',
        planRenewal: '',
      );
      const pending = BreederProfile(
        name: '',
        email: '',
        phone: '',
        farmName: '',
        city: '',
        state: '',
        status: BreederStatus.pending,
        associationId: '',
        plan: '',
        planRenewal: '',
      );

      expect(active.isActive, isTrue);
      expect(pending.isActive, isFalse);
    });
  });

  group('location', () {
    test('joins city and state when both are present', () {
      const profile = BreederProfile(
        name: '',
        email: '',
        phone: '',
        farmName: '',
        city: 'Uberaba',
        state: 'MG',
        status: BreederStatus.pending,
        associationId: '',
        plan: '',
        planRenewal: '',
      );

      expect(profile.location, 'Uberaba, MG');
    });

    test('empty when either city or state is missing', () {
      const noState = BreederProfile(
        name: '',
        email: '',
        phone: '',
        farmName: '',
        city: 'Uberaba',
        state: '',
        status: BreederStatus.pending,
        associationId: '',
        plan: '',
        planRenewal: '',
      );
      const noCity = BreederProfile(
        name: '',
        email: '',
        phone: '',
        farmName: '',
        city: '',
        state: 'MG',
        status: BreederStatus.pending,
        associationId: '',
        plan: '',
        planRenewal: '',
      );

      expect(noState.location, '');
      expect(noCity.location, '');
    });
  });
}
