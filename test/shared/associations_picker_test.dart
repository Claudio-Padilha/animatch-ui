import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/profile/providers/profile_provider.dart';
import 'package:animatch/shared/domain/association.dart';
import 'package:animatch/shared/domain/breeder_association.dart';
import 'package:animatch/shared/widgets/associations_picker.dart';

const _allAssociations = [
  Association(code: 'ABCZ', name: 'ABCZ'),
  Association(code: 'ABQM', name: 'ABQM'),
];

Future<void> _pumpPicker(
  WidgetTester tester, {
  List<BreederAssociation> initialValue = const [],
  required ValueChanged<List<BreederAssociation>> onChanged,
  List<Association> available = _allAssociations,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        associationsProvider.overrideWith((ref) async => available),
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
  });
}
