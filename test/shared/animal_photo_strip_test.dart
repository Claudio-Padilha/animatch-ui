import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/shared/widgets/animal_photo_strip.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<String> photoUrls,
    VoidCallback? onAdd,
    void Function(int)? onRemove,
    bool isLoading = false,
  }) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimalPhotoStrip(
          photoUrls: photoUrls,
          onAdd: onAdd ?? () {},
          onRemove: onRemove ?? (_) {},
          isLoading: isLoading,
        ),
      ),
    ));
  }

  group('AnimalPhotoStrip', () {
    testWidgets('add tile is shown when below the 3-photo max',
        (tester) async {
      await pump(tester, photoUrls: const ['http://img/1.png']);

      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    });

    testWidgets('add tile is hidden once photoUrls reaches the max (3)',
        (tester) async {
      await pump(tester, photoUrls: const [
        'http://img/1.png',
        'http://img/2.png',
        'http://img/3.png',
      ]);

      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
    });

    testWidgets('tapping the add tile calls onAdd', (tester) async {
      var addCalls = 0;
      await pump(tester, photoUrls: const [], onAdd: () => addCalls++);

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));

      expect(addCalls, 1);
    });

    testWidgets('loading state disables the add tile and shows a spinner',
        (tester) async {
      var addCalls = 0;
      await pump(
        tester,
        photoUrls: const [],
        onAdd: () => addCalls++,
        isLoading: true,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);

      // The add tile's GestureDetector.onTap is null while loading — tap
      // where it would be and confirm onAdd is not invoked.
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(addCalls, 0);
    });

    testWidgets('tapping the remove button on a photo tile calls onRemove '
        'with the right index', (tester) async {
      final removed = <int>[];
      await pump(
        tester,
        photoUrls: const ['http://img/1.png', 'http://img/2.png'],
        onRemove: removed.add,
      );

      await tester.tap(find.byIcon(Icons.close).at(1));

      expect(removed, [1]);
    });
  });
}
