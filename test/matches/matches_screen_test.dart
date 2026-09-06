import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/herd/domain/animal_enums.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/herd/providers/selected_animal_provider.dart';
import 'package:animatch/features/matches/domain/match_item.dart';
import 'package:animatch/features/matches/providers/match_provider.dart';
import 'package:animatch/features/matches/ui/matches_screen.dart';
import 'package:animatch/shared/widgets/unverified_profile_prompt.dart';

import '../helpers/fakes.dart';

const _verifiedBreeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  status: BreederStatus.active,
);

final _selected = HerdAnimal(
  id: 'sel1',
  name: 'Trovão',
  breed: 'Nelore',
  sex: 'Macho',
  species: AnimalSpecies.cattle,
  available: true,
);

MatchItem _match({required MatchStatus status, String id = 'm1'}) => MatchItem(
      id: id,
      status: status,
      timeLabel: 'Hoje',
      yourAnimal: const MatchAnimal(name: 'Trovão', breed: 'Nelore · Macho'),
      theirAnimal: const MatchAnimal(name: 'Estrela', breed: 'Nelore · Fêmea'),
      contact: const MatchContact(breederName: 'Fazenda Y', phone: ''),
    );

Future<ProviderContainer> _pumpMatchesScreen(
  WidgetTester tester, {
  Breeder? breeder = _verifiedBreeder,
  bool selectAnimal = true,
  FutureOr<List<MatchItem>> Function()? matches,
  bool settle = true,
}) async {
  final container = ProviderContainer(overrides: [
    authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder)),
    if (selectAnimal && matches != null)
      matchesProvider(_selected.id).overrideWith((ref) => matches()),
  ]);
  addTearDown(container.dispose);
  if (selectAnimal) {
    container.read(selectedAnimalProvider.notifier).select(_selected);
  }

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const MatchesScreen()),
    GoRoute(
      path: AppRoutes.matchDetail,
      builder: (context, state) =>
          Text('match-detail:${state.pathParameters['matchId']}'),
    ),
  ]);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

void main() {
  group('MatchesScreen', () {
    testWidgets('shows UnverifiedProfilePrompt when the breeder is not verified',
        (tester) async {
      await _pumpMatchesScreen(
        tester,
        breeder: const Breeder(id: 'b1', name: 'X', email: 'x@x.com'),
        matches: () => [],
      );

      expect(find.text('Nenhum match ainda'), findsNothing);
      expect(find.byType(UnverifiedProfilePrompt), findsOneWidget);
    });

    testWidgets('shows the "choose an animal" CTA when none is selected',
        (tester) async {
      await _pumpMatchesScreen(
        tester,
        selectAnimal: false,
        matches: () => [],
      );

      expect(find.text('Escolha um animal'), findsOneWidget);
    });

    testWidgets('shows a loading indicator while matchesProvider is loading',
        (tester) async {
      await _pumpMatchesScreen(
        tester,
        matches: () => Completer<List<MatchItem>>().future,
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the error state when matchesProvider errors',
        (tester) async {
      await _pumpMatchesScreen(
        tester,
        matches: () async => throw Exception('boom'),
      );

      expect(find.text('Não foi possível carregar os matches'), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no matches',
        (tester) async {
      await _pumpMatchesScreen(tester, matches: () => []);

      expect(find.text('Nenhum match ainda'), findsOneWidget);
    });

    testWidgets('shows a card per match when populated', (tester) async {
      await _pumpMatchesScreen(
        tester,
        matches: () => [
          _match(status: MatchStatus.confirmado, id: 'm1'),
          _match(status: MatchStatus.pendente, id: 'm2'),
        ],
      );

      expect(find.text('Estrela'), findsNWidgets(2));
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
    });

    testWidgets('tapping a confirmed match navigates to matchDetail with extra',
        (tester) async {
      final match = _match(status: MatchStatus.confirmado, id: 'm1');
      await _pumpMatchesScreen(tester, matches: () => [match]);

      await tester.tap(find.text('Estrela'));
      await tester.pumpAndSettle();

      expect(find.text('match-detail:m1'), findsOneWidget);
    });

    testWidgets('tapping a pending match is a no-op', (tester) async {
      final match = _match(status: MatchStatus.pendente, id: 'm2');
      await _pumpMatchesScreen(tester, matches: () => [match]);

      await tester.tap(find.text('Estrela'));
      await tester.pumpAndSettle();

      expect(find.text('match-detail:m2'), findsNothing);
      expect(find.text('Estrela'), findsOneWidget);
    });
  });
}
