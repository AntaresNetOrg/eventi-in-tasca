import 'package:eventi_bc/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app loads and shows the provisional title', (tester) async {
    await tester.pumpWidget(const EventiBcApp());

    expect(find.text(EventiBcApp.titoloProvvisorio), findsOneWidget);
  });
}
