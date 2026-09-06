import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/core/services/cloudinary_uploader.dart';
import 'package:animatch/features/auth/data/auth_repository.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/locations/providers/locations_provider.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';
import 'package:animatch/features/profile/ui/edit_profile_screen.dart';
import 'package:animatch/shared/domain/municipalities.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  phone: '119999999',
  farmName: 'Fazenda Boa Vista',
  city: 'Uberaba',
  state: 'MG',
  status: BreederStatus.active,
);

Future<ProviderContainer> _pumpEditProfile(
  WidgetTester tester, {
  FakeProfileRepository? profileRepository,
  CloudinaryUploader? cloudinaryUploader,
}) async {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
      profileRepositoryProvider
          .overrideWithValue(profileRepository ?? FakeProfileRepository()),
      municipalitiesProvider.overrideWith(
        (ref) async => Municipalities.fromJson({
          'MG': ['Uberaba'],
        }),
      ),
      cloudinaryUploaderProvider.overrideWithValue(
        cloudinaryUploader ?? FakeCloudinaryUploader(),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EditProfileScreen(),
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
  await tester.pump();
  return container;
}

void main() {
  group('EditProfileScreen', () {
    testWidgets('form is pre-populated from profileProvider on init',
        (tester) async {
      await _pumpEditProfile(tester);

      expect(find.widgetWithText(TextFormField, 'Nome completo'), findsOneWidget);
      final nameField =
          tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Nome completo'));
      expect(nameField.controller!.text, 'Fazenda X');
    });

    testWidgets('required-field validation blocks save when name is empty',
        (tester) async {
      final repo = FakeProfileRepository(updateProfileResult: _breeder);
      await _pumpEditProfile(tester, profileRepository: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo'),
        '',
      );
      await tester.tap(find.text('Salvar alterações'));
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsOneWidget);
      expect(repo.updateProfileCalls, isEmpty);
    });

    testWidgets(
        'save flow: calls updateProfile() with trimmed/nulled-when-empty '
        'values, shows success snackbar, and navigates to /perfil',
        (tester) async {
      final repo = FakeProfileRepository(updateProfileResult: _breeder);
      await _pumpEditProfile(tester, profileRepository: repo);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo'),
        '  Novo Nome  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone / WhatsApp'),
        '  ',
      );
      await tester.tap(find.text('Salvar alterações'));
      // Bounded pumps, not pumpAndSettle — the SnackBar auto-dismisses
      // after its duration, and pumpAndSettle would pump straight past it.
      await tester.pump();
      await tester.pump();

      final call = repo.updateProfileCalls.single;
      expect(call['name'], 'Novo Nome');
      // Blank after trim -> null, not an empty string.
      expect(call['phone'], isNull);
      // The associations picker wasn't touched -> the key is omitted so the
      // backend's existing set is left untouched.
      expect(call['associations'], isNull);
      expect(find.text('Perfil atualizado'), findsOneWidget);
      expect(find.text('profile-screen'), findsOneWidget);
    });

    testWidgets(
        'CPF field is readOnly and pre-filled empty — typing into it has '
        'no effect', (tester) async {
      await _pumpEditProfile(tester);

      final cpfFinder = find.widgetWithText(TextFormField, 'CPF');
      expect(
        tester.widget<TextFormField>(cpfFinder).controller!.text,
        isEmpty,
      );

      await tester.enterText(cpfFinder, '12345678901');
      await tester.pump();

      expect(
        tester.widget<TextFormField>(cpfFinder).controller!.text,
        isEmpty,
      );
    });

    testWidgets(
        'avatar picker: tapping the camera button opens the source chooser; '
        'choosing a source uploads via CloudinaryUploader and swaps in the '
        'returned URL', (tester) async {
      final uploader =
          FakeCloudinaryUploader(result: 'https://cdn.example.com/avatar.jpg');
      await _pumpEditProfile(tester, cloudinaryUploader: uploader);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Tirar foto'), findsOneWidget);
      expect(find.text('Escolher da galeria'), findsOneWidget);

      // Bounded pumps, not pumpAndSettle — CachedNetworkImage's placeholder
      // is an indeterminate CircularProgressIndicator that never settles.
      await tester.tap(find.text('Escolher da galeria'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(uploader.pickAndUploadCalls, 1);
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        'https://cdn.example.com/avatar.jpg',
      );
    });
  });
}
