import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/features/startup/startup_error_screen.dart';

void main() {
  testWidgets('uses the system dark theme during startup failure', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(
      tester.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    await tester.pumpWidget(
      const StartupErrorApp(details: '保存データを読み込めませんでした。'),
    );
    await tester.pump();

    final scaffoldContext = tester.element(find.byType(Scaffold));
    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
  });

  testWidgets('shows a safe concrete failure detail', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(details: 'データの読み込みに失敗しました。もう一度お試しください。'),
    );
    await tester.pump();

    expect(find.text('起動できませんでした'), findsOneWidget);
    expect(
      find.text('データの読み込みに失敗しました。もう一度お試しください。'),
      findsOneWidget,
    );
  });
}
