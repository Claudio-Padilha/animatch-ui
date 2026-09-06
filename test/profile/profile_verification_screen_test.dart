import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/core/services/cloudinary_uploader.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';
import 'package:animatch/features/profile/ui/profile_verification_screen.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(id: 'b1', name: 'Fazenda X', email: 'x@example.com');

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  FakeProfileRepository? profileRepository,
  FakeCloudinaryUploader? cloudinaryUploader,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
      profileRepositoryProvider
          .overrideWithValue(profileRepository ?? FakeProfileRepository()),
      cloudinaryUploaderProvider
          .overrideWithValue(cloudinaryUploader ?? FakeCloudinaryUploader()),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProfileVerificationScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const Text('profile-screen'),
    ),
  ]);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return container;
}

const _validCpf = '11144477735';

void main() {
  group('ProfileVerificationScreen', () {
    testWidgets('invalid CPF blocks submit with the right error text',
        (tester) async {
      final repo = FakeProfileRepository(activateResult: _breeder);
      await _pumpScreen(tester, profileRepository: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone / WhatsApp'),
        '11999999999',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF'),
        '11111111111',
      );
      await tester.tap(find.text('Enviar solicitação'));
      await tester.pump();

      expect(find.text('CPF inválido'), findsOneWidget);
      expect(repo.activateCalls, isEmpty);
    });

    testWidgets('empty CPF blocks submit with Campo obrigatório',
        (tester) async {
      final repo = FakeProfileRepository(activateResult: _breeder);
      await _pumpScreen(tester, profileRepository: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone / WhatsApp'),
        '11999999999',
      );
      await tester.tap(find.text('Enviar solicitação'));
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsWidgets);
      expect(repo.activateCalls, isEmpty);
    });

    testWidgets(
        'photo required before submit — validated outside the Form, its '
        'own SnackBar, distinct from field validation', (tester) async {
      final repo = FakeProfileRepository(activateResult: _breeder);
      await _pumpScreen(tester, profileRepository: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone / WhatsApp'),
        '11999999999',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF'),
        _validCpf,
      );
      await tester.tap(find.text('Enviar solicitação'));
      await tester.pump();

      expect(
        find.text('Adicione uma foto para continuar.'),
        findsOneWidget,
      );
      expect(repo.activateCalls, isEmpty);
    });

    testWidgets(
        'submit calls profileProvider.notifier.activate() with the right '
        'args, shows the success message, and navigates to /perfil',
        (tester) async {
      final repo = FakeProfileRepository(activateResult: _breeder);
      await _pumpScreen(
        tester,
        profileRepository: repo,
        cloudinaryUploader: FakeCloudinaryUploader(result: 'http://img/1.png'),
      );

      // Photo picker: camera-only source (per the screen's own
      // `_pickPhoto`), no bottom-sheet chooser like edit_profile_screen.
      await tester.tap(find.text('Tirar foto'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome da fazenda (opcional)'),
        'Fazenda Boa Vista',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone / WhatsApp'),
        '11999999999',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF'),
        _validCpf,
      );
      await tester.tap(find.text('Enviar solicitação'));
      await tester.pump();
      await tester.pump();

      final call = repo.activateCalls.single;
      expect(call['name'], 'Fazenda X'); // from authNotifierProvider
      expect(call['phone'], '11999999999');
      expect(call['farmName'], 'Fazenda Boa Vista');
      expect(call['pictureUrl'], 'http://img/1.png');
      expect(
        find.text('Solicitação enviada! Aguarde a análise da equipe.'),
        findsOneWidget,
      );
      expect(find.text('profile-screen'), findsOneWidget);
    });
  });
}
