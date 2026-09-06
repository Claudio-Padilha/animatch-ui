import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/locations/providers/locations_provider.dart';
import 'package:animatch/shared/domain/municipalities.dart';
import 'package:animatch/shared/widgets/address_form_fields.dart';

// ─── Input formatters (pure, no widget pump needed) ───────────────────────────

TextEditingValue _apply(TextInputFormatter formatter, String text) =>
    formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)),
    );

void main() {
  group('ZipInputFormatter', () {
    final formatter = ZipInputFormatter();

    test('inserts a dash after 5 digits', () {
      expect(_apply(formatter, '12345000').text, '12345-000');
    });

    test('strips non-digit characters', () {
      expect(_apply(formatter, '12.345-000').text, '12345-000');
    });

    test('caps at 8 digits', () {
      expect(_apply(formatter, '123450009999').text, '12345-000');
    });
  });

  group('CpfInputFormatter', () {
    final formatter = CpfInputFormatter();

    test('formats as 000.000.000-00', () {
      expect(_apply(formatter, '12345678901').text, '123.456.789-01');
    });

    test('caps at 11 digits', () {
      expect(_apply(formatter, '1234567890199').text, '123.456.789-01');
    });
  });

  group('UpperCaseInputFormatter', () {
    final formatter = UpperCaseInputFormatter();

    test('uppercases the entered text', () {
      expect(_apply(formatter, 'mg').text, 'MG');
    });
  });

  // ─── Widget behavior ────────────────────────────────────────────────────────

  group('AddressFormFields', () {
    late TextEditingController city;
    late TextEditingController state;
    late TextEditingController zip;

    setUp(() {
      city = TextEditingController();
      state = TextEditingController();
      zip = TextEditingController();
    });

    tearDown(() {
      city.dispose();
      state.dispose();
      zip.dispose();
    });

    testWidgets('shows a loading indicator while municipalities are loading',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          municipalitiesProvider
              .overrideWith((ref) => Completer<Municipalities>().future),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Form(
              child: AddressFormFields(
                cityController: city,
                stateController: state,
                zipController: zip,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets(
        'state -> city dependent dropdowns: selecting a state populates '
        'its cities; changing state clears the previously selected city',
        (tester) async {
      final municipalities = Municipalities.fromJson({
        'MG': ['Uberaba', 'Uberlândia'],
        'SP': ['Ribeirão Preto'],
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          municipalitiesProvider.overrideWith((ref) async => municipalities),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Form(
              child: AddressFormFields(
                cityController: city,
                stateController: state,
                zipController: zip,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

      // Select state MG.
      await tester.tap(find.text('Estado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MG').last);
      await tester.pumpAndSettle();

      expect(state.text, 'MG');
      expect(city.text, isEmpty);

      // Select a city under MG.
      await tester.tap(find.text('Cidade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uberaba').last);
      await tester.pumpAndSettle();

      expect(city.text, 'Uberaba');

      // Changing state to SP clears the previously selected city.
      await tester.tap(find.text('MG').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SP').last);
      await tester.pumpAndSettle();

      expect(state.text, 'SP');
      expect(city.text, isEmpty);
    });

    testWidgets(
        'falls back to free-text city/state fields when municipalitiesProvider '
        'errors, so the form stays usable', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          municipalitiesProvider
              .overrideWith((ref) async => throw Exception('offline')),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Form(
              child: AddressFormFields(
                cityController: city,
                stateController: state,
                zipController: zip,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Cidade'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Estado'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Cidade'), 'Uberaba');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Estado'), 'mg');
      await tester.pump();

      expect(city.text, 'Uberaba');
      // UpperCaseInputFormatter is applied to the free-text state field.
      expect(state.text, 'MG');
    });
  });
}
