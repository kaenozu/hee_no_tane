import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('reset data clears all saved data and refreshes parent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = SaveRepository();
    var refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          onDataReset: () async {
            refreshed = true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('データリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リセット'));
    await tester.pumpAndSettle();

    expect((await repository.load()).ownedCardIds, isEmpty);
    expect(refreshed, isTrue);
  });
}
