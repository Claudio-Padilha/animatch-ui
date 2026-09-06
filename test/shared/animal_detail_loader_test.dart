import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/shared/domain/animal_detail_data.dart';
import 'package:animatch/shared/screens/animal_detail_screen.dart';

const _extraAnimal = AnimalDetailData(
  id: 'from-extra',
  name: 'Trovão',
  species: 'cattle',
  breed: 'Nelore',
  sex: 'Macho',
  photoUrls: [],
  locationCity: 'Uberaba',
  locationState: 'MG',
);

Future<void> _pumpLoader(
  WidgetTester tester, {
  AnimalDetailData? animal,
}) async {
  final router = GoRouter(
    initialLocation: '/animal/x',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Text('discover-screen'),
      ),
      GoRoute(
        path: '/animal/:animalId',
        builder: (context, state) => AnimalDetailLoader(
          animalId: state.pathParameters['animalId']!,
          animal: animal,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AnimalDetailLoader', () {
    testWidgets('extra present: renders it directly', (tester) async {
      await _pumpLoader(tester, animal: _extraAnimal);
      expect(find.text('Trovão'), findsOneWidget);
    });

    testWidgets('extra absent (cold deep-link): redirects to discovery — '
        'a lone candidate can no longer be fetched by id', (tester) async {
      await _pumpLoader(tester);
      expect(find.text('discover-screen'), findsOneWidget);
    });
  });
}
