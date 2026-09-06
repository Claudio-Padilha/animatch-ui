import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/profile/domain/breeder_statistics.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';
import 'package:animatch/features/profile/ui/profile_screen.dart';

import '../helpers/fakes.dart';

const _verifiedBreeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  status: BreederStatus.active,
  city: 'Uberaba',
  state: 'MG',
);

const _pendingBreeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  status: BreederStatus.pending,
);

Future<ProviderContainer> _pumpProfileScreen(
  WidgetTester tester, {
  Breeder breeder = _verifiedBreeder,
  Breeder? refreshBreederResult,
  FutureOr<BreederStatistics> Function()? statistics,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(refreshBreederResult: refreshBreederResult),
      ),
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder)),
      if (statistics != null)
        breederStatisticsProvider.overrideWith(() => _FakeStatisticsNotifier(statistics)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pump();
  return container;
}

class _FakeStatisticsNotifier extends BreederStatisticsNotifier {
  _FakeStatisticsNotifier(this._build);
  final FutureOr<BreederStatistics> Function() _build;

  @override
  Future<BreederStatistics> build() async => _build();
}

void main() {
  group('ProfileScreen', () {
    testWidgets(
        'refreshBreeder() on init syncs the fresh breeder into '
        'authNotifierProvider', (tester) async {
      final updated = _verifiedBreeder.copyWith(name: 'Fazenda Atualizada');
      final container = await _pumpProfileScreen(
        tester,
        refreshBreederResult: updated,
        statistics: () => const BreederStatistics(
          activeAnimals: 0,
          likes: 0,
          breederMatches: 0,
        ),
      );
      await tester.pump();

      expect(container.read(authNotifierProvider)?.name, 'Fazenda Atualizada');
    });

    testWidgets('verified breeder shows the verified badge, not the CTA',
        (tester) async {
      await _pumpProfileScreen(
        tester,
        statistics: () => const BreederStatistics(
          activeAnimals: 0,
          likes: 0,
          breederMatches: 0,
        ),
      );

      expect(find.text('Criador Verificado'), findsOneWidget);
      expect(find.text('Verificar perfil de criador'), findsNothing);
    });

    testWidgets('unverified breeder shows the verification CTA, not the badge',
        (tester) async {
      await _pumpProfileScreen(
        tester,
        breeder: _pendingBreeder,
        statistics: () => const BreederStatistics(
          activeAnimals: 0,
          likes: 0,
          breederMatches: 0,
        ),
      );

      expect(find.text('Verificar perfil de criador'), findsOneWidget);
      expect(find.text('Criador Verificado'), findsNothing);
    });

    testWidgets('statistics card: loading state', (tester) async {
      await _pumpProfileScreen(
        tester,
        statistics: () => Completer<BreederStatistics>().future,
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('statistics card: error state', (tester) async {
      await _pumpProfileScreen(
        tester,
        statistics: () async => throw Exception('boom'),
      );
      await tester.pump();

      expect(
        find.text('Não foi possível carregar estatísticas.'),
        findsOneWidget,
      );
    });

    testWidgets('statistics card: data state', (tester) async {
      await _pumpProfileScreen(
        tester,
        statistics: () => const BreederStatistics(
          activeAnimals: 4,
          likes: 7,
          breederMatches: 2,
        ),
      );
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('sign-out: cancel on the confirm dialog does nothing',
        (tester) async {
      final container = await _pumpProfileScreen(
        tester,
        statistics: () => const BreederStatistics(
          activeAnimals: 0,
          likes: 0,
          breederMatches: 0,
        ),
      );

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(container.read(authNotifierProvider), isNotNull);
    });

    testWidgets(
        'sign-out: confirm calls logout() and shows a loading spinner '
        'meanwhile', (tester) async {
      final fakeAuthRepo = _SlowLogoutAuthRepository();
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          authNotifierProvider.overrideWith(() => SeededAuthNotifier(_verifiedBreeder)),
          breederStatisticsProvider.overrideWith(
            () => _FakeStatisticsNotifier(
              () => const BreederStatistics(
                activeAnimals: 0,
                likes: 0,
                breederMatches: 0,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pump(); // dialog pop + setState(_isLoading = true)

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      fakeAuthRepo.completeLogout();
      await tester.pumpAndSettle();
      expect(fakeAuthRepo.logoutCalls, 1);
    });
  });
}

/// A [FakeAuthRepository] whose `logout()` doesn't resolve until
/// [completeLogout] is called, so the intermediate loading-spinner state is
/// observable — the base [FakeAuthRepository.logout] resolves within a
/// single microtask, too fast for `pump()` to catch mid-flight.
class _SlowLogoutAuthRepository extends FakeAuthRepository {
  final _completer = Completer<void>();

  @override
  Future<void> logout() async {
    await _completer.future;
    await super.logout();
  }

  void completeLogout() => _completer.complete();
}
