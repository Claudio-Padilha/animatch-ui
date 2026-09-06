import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/matches/domain/match_item.dart';
import 'package:animatch/features/matches/providers/match_provider.dart';
import 'package:animatch/features/matches/ui/match_detail_screen.dart';

import '../helpers/fakes.dart';

MatchItem _match({
  double? depPeso,
  double? depConf,
  MatchStatus status = MatchStatus.confirmado,
  String? yourAnimalId = 'sel1',
  String? theirAnimalId = 'cand1',
}) =>
    MatchItem(
      id: 'm1',
      status: status,
      timeLabel: 'Hoje',
      yourAnimal: MatchAnimal(
        id: yourAnimalId,
        name: 'Trovão',
        breed: 'Nelore · Macho',
        geneticIndices: (depPeso != null || depConf != null)
            ? GeneticIndices(milkRestrictionWeight: depPeso, conformacao: depConf)
            : null,
      ),
      theirAnimal: MatchAnimal(
        id: theirAnimalId,
        name: 'Estrela',
        breed: 'Nelore · Fêmea',
      ),
      contact: const MatchContact(
        breederName: 'Fazenda Y',
        phone: '',
        email: 'y@example.com',
      ),
    );

Future<void> _pumpMatchDetail(
  WidgetTester tester, {
  required MatchItem match,
  FakeMatchRepository? repo,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(overrides: [
    matchRepositoryProvider.overrideWithValue(
      repo ?? FakeMatchRepository(getMatchResult: match),
    ),
  ]);
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MatchDetailScreen(matchId: 'm1'),
    ),
    GoRoute(
      path: AppRoutes.matches,
      builder: (context, state) => const Text('matches-screen'),
    ),
    GoRoute(
      path: AppRoutes.matchChat,
      builder: (context, state) =>
          Text('chat:${state.pathParameters['matchId']}'),
    ),
    GoRoute(
      path: AppRoutes.matchAnimalDetail,
      builder: (context, state) => Text(
        'animal-detail:${state.pathParameters['matchId']}/'
        '${state.pathParameters['side']}',
      ),
    ),
  ]);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MatchDetailScreen', () {
    testWidgets('renders both animals and the contact card', (tester) async {
      await _pumpMatchDetail(tester, match: _match());

      // Each animal's name renders twice: once in the photo pair header,
      // once in the info card below.
      expect(find.text('Trovão'), findsNWidgets(2));
      expect(find.text('Estrela'), findsNWidgets(2));
      expect(find.text('Fazenda Y'), findsOneWidget);
      expect(find.text('y@example.com'), findsOneWidget);
    });

    testWidgets('shows a phone/WhatsApp row when contact.phone is present',
        (tester) async {
      final match = _match().copyWith(
        contact: const MatchContact(
          breederName: 'Fazenda Y',
          phone: '5511988887777',
          email: 'y@example.com',
        ),
      );
      await _pumpMatchDetail(tester, match: match);
      expect(find.text('5511988887777'), findsOneWidget);
    });

    testWidgets('hides DEP rows when depPeso/depConf are null', (tester) async {
      await _pumpMatchDetail(tester, match: _match());
      expect(find.text('DEP Peso Desmame'), findsNothing);
      expect(find.text('DEP Conformação'), findsNothing);
    });

    testWidgets('shows DEP rows when depPeso/depConf are non-null',
        (tester) async {
      await _pumpMatchDetail(
        tester,
        match: _match(depPeso: 5.2, depConf: -1.3),
      );
      expect(find.text('DEP Peso Desmame'), findsOneWidget);
      expect(find.text('DEP Conformação'), findsOneWidget);
      expect(find.text('+5.2'), findsOneWidget);
      expect(find.text('-1.3'), findsOneWidget);
    });

    testWidgets('Chat CTA navigates to the match chat route', (tester) async {
      await _pumpMatchDetail(tester, match: _match());

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.text('chat:m1'), findsOneWidget);
    });

    testWidgets('a pending match hides the Chat CTA', (tester) async {
      await _pumpMatchDetail(
        tester,
        match: _match(status: MatchStatus.pendente),
      );

      expect(find.text('Chat'), findsNothing);
      expect(
        find.textContaining('quando o outro criador confirmar'),
        findsOneWidget,
      );
    });

    testWidgets('tapping the other animal photo navigates by match id + side',
        (tester) async {
      await _pumpMatchDetail(tester, match: _match());

      // Pair header GestureDetectors are in render order [yours, theirs].
      await tester.tap(find.byType(GestureDetector).at(1));
      await tester.pumpAndSettle();

      expect(find.text('animal-detail:m1/theirs'), findsOneWidget);
    });

    testWidgets(
        'unmatch flow: confirm dialog -> deleteMatch -> navigates to /matches',
        (tester) async {
      final repo = FakeMatchRepository(getMatchResult: _match());
      await _pumpMatchDetail(tester, match: _match(), repo: repo);

      await tester.tap(find.text('Cancelar match'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar match?'), findsOneWidget);

      await tester.tap(find.text('Cancelar match').last);
      await tester.pumpAndSettle();

      expect(repo.deleteMatchCalls, ['m1']);
      expect(find.text('matches-screen'), findsOneWidget);
    });

    testWidgets('cancel on the confirm dialog does nothing', (tester) async {
      final repo = FakeMatchRepository(getMatchResult: _match());
      await _pumpMatchDetail(tester, match: _match(), repo: repo);

      await tester.tap(find.text('Cancelar match'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(repo.deleteMatchCalls, isEmpty);
      expect(find.text('Trovão'), findsNWidgets(2));
    });

    testWidgets(
        'unmatch flow does NOT navigate when deleteMatch fails — shows an '
        'error SnackBar instead (K-3 fixed)', (tester) async {
      final repo = FakeMatchRepository(
        getMatchResult: _match(),
        deleteMatchError: Exception('boom'),
      );
      await _pumpMatchDetail(tester, match: _match(), repo: repo);

      await tester.tap(find.text('Cancelar match'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar match').last);
      await tester.pumpAndSettle();

      expect(repo.deleteMatchCalls, ['m1']);
      expect(find.text('matches-screen'), findsNothing);
      expect(find.textContaining('Erro ao cancelar'), findsOneWidget);
    });
  });
}
