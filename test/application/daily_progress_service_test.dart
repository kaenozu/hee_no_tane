import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/application/daily_progress_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

void main() {
  test(
    'daily assignment is persisted and cannot change on the same date',
    () async {
      final repository = SaveRepository(store: _MemoryPreferenceStore());
      final service = DailyProgressService(
        saveRepository: repository,
        rewardService: RewardService(),
      );

      final assigned = await service.ensureAssignment(
        date: '2026-07-17',
        questionId: 'q_1',
        cardId: 'c_1',
      );

      expect(
        assigned.hasDailyAssignment(
          date: '2026-07-17',
          questionId: 'q_1',
          cardId: 'c_1',
        ),
        isTrue,
      );
      await expectLater(
        service.ensureAssignment(
          date: '2026-07-17',
          questionId: 'q_2',
          cardId: 'c_2',
        ),
        throwsA(isA<SaveException>()),
      );
    },
  );

  test(
    'daily answer update is idempotent and keeps assignment identity',
    () async {
      final repository = SaveRepository(store: _MemoryPreferenceStore());
      final service = DailyProgressService(
        saveRepository: repository,
        rewardService: RewardService(),
      );
      final question = _question();
      final card = _card();

      await service.ensureAssignment(
        date: '2026-07-17',
        questionId: question.id,
        cardId: card.id,
      );
      final first = await service.submitAnswer(
        date: '2026-07-17',
        question: question,
        card: card,
      );
      final second = await service.submitAnswer(
        date: '2026-07-17',
        question: question,
        card: card,
      );

      expect(first.alreadyCompleted, isFalse);
      expect(first.cardWasOwnedBeforeAnswer, isFalse);
      expect(second.alreadyCompleted, isTrue);
      expect(second.saveData.totalPlayCount, 1);
      expect(second.saveData.streakDays, 1);
      expect(second.saveData.ownedCardIds, <String>[card.id]);
      expect(
        second.saveData.hasDailyAssignment(
          date: '2026-07-17',
          questionId: question.id,
          cardId: card.id,
        ),
        isTrue,
      );
      expect(
        second.saveData.hasDailyCompletion(
          date: '2026-07-17',
          questionId: question.id,
          cardId: card.id,
        ),
        isTrue,
      );
    },
  );

  test('version 3 completion fields migrate into the assignment fields', () {
    final data = SaveData.fromJson(<String, dynamic>{
      'version': 3,
      'lastDailyQuestionDate': '2026-07-16',
      'lastDailyQuestionId': 'q_legacy',
      'lastDailyCardId': 'c_legacy',
      'ownedCardIds': <String>['c_legacy'],
    });

    expect(data.dailyAssignmentDate, '2026-07-16');
    expect(data.dailyAssignmentQuestionId, 'q_legacy');
    expect(data.dailyAssignmentCardId, 'c_legacy');
    expect(data.toJson()['version'], 4);
  });
}

Question _question() => Question(
  id: 'q_1',
  category: 'science',
  difficulty: 'easy',
  question: 'テスト質問',
  choices: const <String>['A', 'B'],
  answerIndex: 0,
  explanation: 'テスト解説',
  relatedCardId: 'c_1',
  sourceNote: 'テスト出典',
  verified: true,
);

HeeCard _card() => const HeeCard(
  id: 'c_1',
  title: 'テストカード',
  category: 'science',
  shortText: '短文',
  detailText: '詳細文',
  imageAsset: 'assets/images/cards/c_1.webp',
  rarity: 'common',
  sourceNote: 'テスト出典',
);

final class _MemoryPreferenceStore implements PreferenceStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
