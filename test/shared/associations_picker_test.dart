import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/core/services/cloudinary_uploader.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';
import 'package:animatch/shared/domain/association.dart';
import 'package:animatch/shared/domain/breeder_association.dart';
import 'package:animatch/shared/widgets/associations_picker.dart';

import '../helpers/fakes.dart';

const _allAssociations = [
  Association(code: 'ABCZ', name: 'ABCZ'),
  Association(code: 'ABQM', name: 'ABQM'),
];

Future<void> _pumpPicker(
  WidgetTester tester, {
  List<BreederAssociation> initialValue = const [],
  required ValueChanged<List<BreederAssociation>> onChanged,
  List<Association> available = _allAssociations,
  CloudinaryUploader? cloudinaryUploader,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        associationsProvider.overrideWith((ref) async => available),
        cloudinaryUploaderProvider.overrideWithValue(
          cloudinaryUploader ?? FakeCloudinaryUploader(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Form(
            child: AssociationsPicker(
              initialValue: initialValue,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('AssociationsPicker', () {
    testWidgets('add: opens the bottom sheet, picking an association adds a '
        'row with its code chip', (tester) async {
      List<BreederAssociation>? lastChanged;
      await _pumpPicker(tester, onChanged: (v) => lastChanged = v);

      await tester.tap(find.text('Adicionar associação'));
      await tester.pumpAndSettle();
      expect(find.text('Selecionar associação'), findsOneWidget);

      await tester.tap(find.text('ABCZ').last);
      await tester.pumpAndSettle();

      expect(find.text('ABCZ'), findsOneWidget);
      expect(lastChanged, hasLength(1));
      expect(lastChanged!.single.code, 'ABCZ');
    });

    testWidgets(
        '_selectedCodes prevents duplicates: the add button hides once '
        'every available association has been added', (tester) async {
      await _pumpPicker(
        tester,
        initialValue: const [
          BreederAssociation(code: 'ABCZ', name: 'ABCZ'),
          BreederAssociation(code: 'ABQM', name: 'ABQM'),
        ],
        onChanged: (_) {},
      );

      expect(find.text('Adicionar associação'), findsNothing);
    });

    testWidgets('remove: tapping the row\'s close button removes it and '
        'notifies onChanged', (tester) async {
      List<BreederAssociation>? lastChanged;
      await _pumpPicker(
        tester,
        initialValue: const [BreederAssociation(code: 'ABCZ', name: 'ABCZ')],
        onChanged: (v) => lastChanged = v,
      );

      expect(find.text('ABCZ'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('ABCZ'), findsNothing);
      expect(lastChanged, isEmpty);
    });

    testWidgets(
        'registration-number-required validation per row', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            associationsProvider
                .overrideWith((ref) async => _allAssociations),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: AssociationsPicker(
                  initialValue: const [
                    BreederAssociation(code: 'ABCZ', name: 'ABCZ'),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets(
        'disposal: adding then removing several rows does not throw a '
        '"TextEditingController used after dispose" assertion',
        (tester) async {
      await _pumpPicker(tester, onChanged: (_) {});

      // Add both available associations.
      await tester.tap(find.text('Adicionar associação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABCZ').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adicionar associação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABQM').last);
      await tester.pumpAndSettle();

      expect(find.text('Adicionar associação'), findsNothing);

      // Remove both.
      final closeButtons = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButtons.first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'document attachment: tapping "Anexar" opens the source chooser, '
        'uploads via CloudinaryUploader, and shows a thumbnail',
        (tester) async {
      List<BreederAssociation>? lastChanged;
      final uploader = FakeCloudinaryUploader(
        result: 'https://cdn.example.com/carteirinha.jpg',
      );
      await _pumpPicker(
        tester,
        initialValue: const [BreederAssociation(code: 'ABCZ', name: 'ABCZ')],
        onChanged: (v) => lastChanged = v,
        cloudinaryUploader: uploader,
      );

      expect(find.text('Anexar carteirinha ou certificado'), findsOneWidget);

      await tester.tap(find.text('Anexar carteirinha ou certificado'));
      await tester.pumpAndSettle();
      expect(find.text('Tirar foto'), findsOneWidget);

      await tester.tap(find.text('Tirar foto'));
      await tester.pumpAndSettle();

      expect(uploader.pickAndUploadCalls, 1);
      expect(find.text('Documento anexado'), findsOneWidget);
      expect(find.text('Anexar carteirinha ou certificado'), findsNothing);
      expect(lastChanged!.single.documentUrl,
          'https://cdn.example.com/carteirinha.jpg');
    });

    testWidgets(
        'document attachment: upload failure shows an error SnackBar and '
        'leaves documentUrl unset', (tester) async {
      List<BreederAssociation>? lastChanged;
      final uploader = FakeCloudinaryUploader(error: Exception('boom'));
      await _pumpPicker(
        tester,
        initialValue: const [BreederAssociation(code: 'ABCZ', name: 'ABCZ')],
        onChanged: (v) => lastChanged = v,
        cloudinaryUploader: uploader,
      );

      await tester.tap(find.text('Anexar carteirinha ou certificado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tirar foto'));
      await tester.pumpAndSettle();

      expect(uploader.pickAndUploadCalls, 1);
      expect(find.textContaining('Erro ao enviar documento'), findsOneWidget);
      expect(find.text('Anexar carteirinha ou certificado'), findsOneWidget);
      expect(find.text('Documento anexado'), findsNothing);
      expect(lastChanged, isNull);
    });

    testWidgets(
        'document attachment: the delete button clears the document and '
        'notifies onChanged', (tester) async {
      List<BreederAssociation>? lastChanged;
      await _pumpPicker(
        tester,
        initialValue: const [
          BreederAssociation(
            code: 'ABCZ',
            name: 'ABCZ',
            documentUrl: 'https://cdn.example.com/carteirinha.jpg',
          ),
        ],
        onChanged: (v) => lastChanged = v,
      );

      expect(find.text('Documento anexado'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump();

      expect(find.text('Documento anexado'), findsNothing);
      expect(find.text('Anexar carteirinha ou certificado'), findsOneWidget);
      expect(lastChanged!.single.documentUrl, isNull);
    });

    testWidgets(
        'verification status: shows "em análise" for a pending document',
        (tester) async {
      await _pumpPicker(
        tester,
        initialValue: const [
          BreederAssociation(
            code: 'ABCZ',
            name: 'ABCZ',
            documentUrl: 'https://cdn.example.com/carteirinha.jpg',
            verificationStatus: AssociationVerificationStatus.pending,
          ),
        ],
        onChanged: (_) {},
      );

      expect(find.text('Documento em análise'), findsOneWidget);
    });

    testWidgets('verification status: shows "aprovado" for an approved document',
        (tester) async {
      await _pumpPicker(
        tester,
        initialValue: const [
          BreederAssociation(
            code: 'ABCZ',
            name: 'ABCZ',
            documentUrl: 'https://cdn.example.com/carteirinha.jpg',
            verificationStatus: AssociationVerificationStatus.approved,
          ),
        ],
        onChanged: (_) {},
      );

      expect(find.text('Documento aprovado'), findsOneWidget);
    });

    testWidgets(
        'verification status: shows the rejection reason for a rejected '
        'document', (tester) async {
      await _pumpPicker(
        tester,
        initialValue: const [
          BreederAssociation(
            code: 'ABCZ',
            name: 'ABCZ',
            documentUrl: 'https://cdn.example.com/carteirinha.jpg',
            verificationStatus: AssociationVerificationStatus.rejected,
            rejectionReason: 'Foto ilegível',
          ),
        ],
        onChanged: (_) {},
      );

      expect(find.text('Documento rejeitado: Foto ilegível'), findsOneWidget);
    });

    testWidgets(
        'verification status: nothing shown for unsubmitted, even with a '
        'document attached', (tester) async {
      await _pumpPicker(
        tester,
        initialValue: const [
          BreederAssociation(
            code: 'ABCZ',
            name: 'ABCZ',
            documentUrl: 'https://cdn.example.com/carteirinha.jpg',
          ),
        ],
        onChanged: (_) {},
      );

      expect(find.textContaining('Documento em análise'), findsNothing);
      expect(find.textContaining('Documento aprovado'), findsNothing);
      expect(find.textContaining('Documento rejeitado'), findsNothing);
    });
  });
}
