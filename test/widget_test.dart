import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_save_repository.dart';
import 'helpers/release_content.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    final store = InMemoryPreferenceStore();

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: const [],
        allCards: const [],
        saveData: SaveData(),
        saveRepository: SaveRepository(store: store),
        rewardService: RewardService(),
      ),
    );
    for (var i = 0; i < 20 && find.text('へぇのタネ').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('へぇのタネ'), findsOneWidget);
  });

  testWidgets('App home shows daily question section', (
    WidgetTester tester,
  ) async {
    final store = InMemoryPreferenceStore();

    final pairs = List.generate(
      5,
      (index) => releaseContentPair(
        id: 'widget_$index',
        category: 'nature_geography',
        questionText: '問題$index',
        choices: const ['正解', 'B', 'C', 'D'],
        explanation: '解説$index',
        title: 'カード$index',
        shortText: '説明$index',
        detailText: '詳細$index',
      ),
    );
    final questions = pairs.map((pair) => pair.question).toList();
    final cards = pairs.map((pair) => pair.card).toList();

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: questions,
        allCards: cards,
        saveData: SaveData(onboardingCompleted: true),
        saveRepository: SaveRepository(store: store),
        rewardService: RewardService(),
      ),
    );
    for (var i = 0; i < 20 && find.text('今日の1問').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('今日の1問'), findsOneWidget);
    expect(find.text('約30秒'), findsOneWidget);
    expect(find.text('今日の1問を始める'), findsOneWidget);
    expect(find.text('連続'), findsOneWidget);
    expect(find.text('図鑑'), findsOneWidget);
    expect(find.text('閲覧'), findsOneWidget);
  });
}
