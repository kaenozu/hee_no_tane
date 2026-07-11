import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: const [],
        allCards: const [],
        saveData: SaveData(),
        saveRepository: SaveRepository(),
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
    SharedPreferences.setMockInitialValues({});

    final questions = List.generate(
      5,
      (index) => Question(
        id: 'q$index',
        category: 'test',
        difficulty: 'easy',
        question: '問題$index',
        choices: const ['正解', 'B', 'C', 'D'],
        answerIndex: 0,
        explanation: '解説$index',
        relatedCardId: 'card$index',
        sourceNote: 'test',
        verified: true,
      ),
    );
    final cards = List.generate(
      5,
      (index) => HeeCard(
        id: 'card$index',
        title: 'カード$index',
        category: 'nature_geography',
        shortText: '説明$index',
        detailText: '詳細$index',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: 'test',
      ),
    );

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: questions,
        allCards: cards,
        saveData: SaveData(),
        saveRepository: SaveRepository(),
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
