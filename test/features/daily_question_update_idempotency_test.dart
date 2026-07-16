import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';

import '../helpers/fake_save_repository.dart';

class CommitThenThrowRepository extends SaveRepository {
  SaveData data = SaveData();
  int saveCallCount = 0;
  bool _throwAfterFirstWrite = true;

  CommitThenThrowRepository() : super(store: InMemoryPreferenceStore());

  @override
  Future<SaveData> loadOrThrow() async => SaveData.fromJson(data.toJson());

  @override
  Future<void> save(SaveData next) async {
    saveCallCount++;
    data = SaveData.fromJson(next.toJson());
    if (_throwAfterFirstWrite) {
      _throwAfterFirstWrite = false;
      throw const SaveException('保存結果を確認できませんでした');
    }
  }
}

void main() {
  testWidgets(
    'U6. retry after committed-but-reported-failed save is idempotent',
    (tester) async {
      final repository = CommitThenThrowRepository();
      final card = HeeCard(
        id: 'card_retry',
        title: '再試行カード',
        category: 'science',
        shortText: '短文',
        detailText: '詳細',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: '出典',
      );
      final question = Question(
        id: 'question_retry',
        category: 'science',
        difficulty: 'easy',
        question: '再試行しても二重加算されない？',
        choices: const ['A', 'B', 'C'],
        answerIndex: 0,
        explanation: '同日回答済みなら更新はno-opです。',
        relatedCardId: card.id,
        sourceNote: '出典',
        verified: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DailyQuestionScreen(
            question: question,
            relatedCard: card,
            saveRepository: repository,
            rewardService: RewardService(),
          ),
        ),
      );

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('保存エラー'), findsOneWidget);
      expect(repository.data.totalPlayCount, 1);
      expect(repository.data.ownedCardIds, [card.id]);

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      expect(find.text('保存エラー'), findsNothing);
      expect(find.text('新しい知識カードを発見'), findsOneWidget);
      expect(repository.data.totalPlayCount, 1);
      expect(
        repository.data.ownedCardIds.where((id) => id == card.id),
        hasLength(1),
      );
      expect(repository.data.lastDailyQuestionDate, isNotEmpty);
      expect(repository.data.lastDailyQuestionId, question.id);
      expect(repository.data.lastDailyCardId, card.id);
      expect(repository.saveCallCount, 2);
    },
  );
}
