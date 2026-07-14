import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/features/settings/legal_information_screen.dart';
import 'package:hee_no_tane_app/features/startup/startup_error_screen.dart';

void main() {
  testWidgets('startup failure shows a user-readable recovery screen', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupErrorApp());

    expect(find.text('起動できませんでした'), findsOneWidget);
    expect(find.textContaining('再度起動'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('legal screen explains local storage and data deletion', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LegalInformationScreen()));

    expect(find.text('データの取り扱い'), findsOneWidget);
    expect(find.textContaining('端末内に保存'), findsWidgets);

    final listFinder = find.byType(ListView);
    await tester.drag(listFinder, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('保存データの削除'), findsOneWidget);
  });
}
