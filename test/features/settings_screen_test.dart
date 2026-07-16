import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';

import '../helpers/fake_save_repository.dart';

void main() {
  testWidgets('reset data clears all saved data and refreshes parent', (
    tester,
  ) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);
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

  testWidgets('settings shows privacy policy link', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          onDataReset: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('プライバシーポリシー'), findsOneWidget);
    expect(find.text('データの取り扱いについて'), findsOneWidget);
  });

  testWidgets('settings shows support link', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          onDataReset: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('サポート'), findsOneWidget);
    expect(find.text('不具合報告・お問い合わせ'), findsOneWidget);
  });

  testWidgets('settings shows version info', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          onDataReset: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('バージョン情報'), findsOneWidget);
    expect(find.text('へぇのタネ v1.0.0 (1)'), findsOneWidget);
  });

  testWidgets('tapping privacy policy navigates to privacy screen', (
    tester,
  ) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          onDataReset: () async {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pumpAndSettle();

    expect(find.text('プライバシーポリシー'), findsWidgets);
    expect(find.text('収集する情報'), findsOneWidget);
  });

  testWidgets('tapping support navigates to support screen', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          onDataReset: () async {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('サポート'));
    await tester.pumpAndSettle();

    expect(find.text('お問い合わせ'), findsOneWidget);
  });

  testWidgets('tapping version navigates to version screen', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          onDataReset: () async {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('バージョン情報'));
    await tester.pumpAndSettle();

    expect(find.text('アプリ情報'), findsOneWidget);
    expect(find.text('v1.0の機能'), findsOneWidget);
  });
}
