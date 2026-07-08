import 'package:hee_no_tane_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const HeeNoTaneApp());
    expect(find.text('へぇ'), findsOneWidget);
  });
}
