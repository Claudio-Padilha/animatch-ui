import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AnimatchApp()));
    await tester.pumpAndSettle();
    expect(find.text('Animatch'), findsOneWidget);
  });
}
