import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/locations/providers/locations_provider.dart';
import 'package:animatch/features/profile/ui/profile_completion_screen.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(id: 'b1', name: 'Fazenda X', email: 'x@example.com');

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  FakeAuthRepository? authRepository,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
      authRepositoryProvider.overrideWithValue(authRepository ?? FakeAuthRepository()),
      // Force the free-text city/state fallback (rather than the dropdown
      // widgets) — simpler to drive here; the dropdown interaction itself
      // is already covered by test/shared/address_form_fields_test.dart.
      municipalitiesProvider.overrideWith((ref) async => throw Exception('offline')),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileCompletionScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('ProfileCompletionScreen', () {
    testWidgets('required-field validation blocks submit when name/address '
        'are empty', (tester) async {
      final repo = FakeAuthRepository(syncBreederResult: _breeder);
      await _pumpScreen(tester, authRepository: repo);

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsWidgets);
      expect(repo.syncBreederCalls, isEmpty);
    });

    testWidgets(
        'submit calls syncBreeder() with trimmed values (Logradouro is '
        'required on this screen, unlike edit_profile_screen)',
        (tester) async {
      final repo = FakeAuthRepository(syncBreederResult: _breeder);
      await _pumpScreen(tester, authRepository: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo'),
        '  João Criador  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Logradouro'),
        '  Rua das Flores, 100  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cidade'),
        'Uberaba',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Estado'),
        'MG',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'CEP'), '12345000');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump();

      final call = repo.syncBreederCalls.single;
      expect(call['name'], 'João Criador');
      expect(call['directions'], 'Rua das Flores, 100');
      expect(call['city'], 'Uberaba');
      expect(call['state'], 'MG');
    });

    testWidgets('error SnackBar shown on failure', (tester) async {
      final repo = FakeAuthRepository(syncBreederError: Exception('boom'));
      await _pumpScreen(tester, authRepository: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo'),
        'João Criador',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Logradouro'),
        'Rua das Flores, 100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cidade'),
        'Uberaba',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Estado'),
        'MG',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'CEP'), '12345000');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Erro ao salvar. Tente novamente.'), findsOneWidget);
    });
  });
}
