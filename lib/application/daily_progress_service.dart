import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

class DailyAnswerResult {
  final SaveData saveData;
  final bool cardWasOwnedBeforeAnswer;
  final bool alreadyCompleted;

  const DailyAnswerResult({
    required this.saveData,
    required this.cardWasOwnedBeforeAnswer,
    required this.alreadyCompleted,
  });
}

class DailyProgressService {
  final SaveRepository _saveRepository;
  final RewardService _rewardService;

  const DailyProgressService({
    required SaveRepository saveRepository,
    required RewardService rewardService,
  }) : _saveRepository = saveRepository,
       _rewardService = rewardService;

  Future<SaveData> ensureAssignment({
    required String date,
    required String questionId,
    required String cardId,
  }) {
    _requireAssignmentValues(date, questionId, cardId);
    return _saveRepository.update((current) {
      final exactCompletion = current.hasDailyCompletion(
        date: date,
        questionId: questionId,
        cardId: cardId,
      );
      final legacyCompletion =
          current.lastDailyQuestionDate == date &&
          current.lastDailyQuestionId.isEmpty &&
          current.lastDailyCardId.isEmpty &&
          current.ownedCardIds.contains(cardId);
      if (current.lastDailyQuestionDate == date &&
          !exactCompletion &&
          !legacyCompletion) {
        throw const SaveException(
          '本日の回答履歴と割り当てられた問題が一致しません。アプリを更新して再度お試しください。',
        );
      }

      if (current.dailyAssignmentDate == date) {
        if (current.hasDailyAssignment(
          date: date,
          questionId: questionId,
          cardId: cardId,
        )) {
          return current;
        }
        if (current.dailyAssignmentQuestionId.isNotEmpty ||
            current.dailyAssignmentCardId.isNotEmpty) {
          throw const SaveException(
            '本日分として別の問題がすでに割り当てられています。ホームを再読み込みしてください。',
          );
        }
      }

      return current.copyWith(
        dailyAssignmentDate: date,
        dailyAssignmentQuestionId: questionId,
        dailyAssignmentCardId: cardId,
      );
    });
  }

  Future<DailyAnswerResult> submitAnswer({
    required String date,
    required Question question,
    HeeCard? card,
  }) async {
    final cardId = card?.id ?? question.relatedCardId;
    _requireAssignmentValues(date, question.id, cardId);

    var cardWasOwnedBeforeAnswer = true;
    var alreadyCompleted = false;
    final updated = await _saveRepository.update((current) {
      final hasStoredAssignmentIds =
          current.dailyAssignmentQuestionId.isNotEmpty ||
          current.dailyAssignmentCardId.isNotEmpty;
      if (current.dailyAssignmentDate == date &&
          hasStoredAssignmentIds &&
          !current.hasDailyAssignment(
            date: date,
            questionId: question.id,
            cardId: cardId,
          )) {
        throw const SaveException(
          '本日分として割り当てられた問題と回答対象が一致しません。ホームへ戻って最新の問題を開いてください。',
        );
      }

      var assigned = current;
      if (!current.hasDailyAssignment(
        date: date,
        questionId: question.id,
        cardId: cardId,
      )) {
        assigned = current.copyWith(
          dailyAssignmentDate: date,
          dailyAssignmentQuestionId: question.id,
          dailyAssignmentCardId: cardId,
        );
      }

      if (assigned.lastDailyQuestionDate == date) {
        final exactMatch = assigned.hasDailyCompletion(
          date: date,
          questionId: question.id,
          cardId: cardId,
        );
        final legacyMatch =
            assigned.lastDailyQuestionId.isEmpty &&
            assigned.lastDailyCardId.isEmpty &&
            assigned.ownedCardIds.contains(cardId);
        if (exactMatch || legacyMatch) {
          alreadyCompleted = true;
          cardWasOwnedBeforeAnswer = true;
          return legacyMatch
              ? assigned.copyWith(
                  lastDailyQuestionId: question.id,
                  lastDailyCardId: cardId,
                )
              : assigned;
        }
        throw const SaveException(
          '同じ日付に別の問題の回答履歴があります。ホームへ戻って最新の問題を開いてください。',
        );
      }

      cardWasOwnedBeforeAnswer =
          card == null || assigned.ownedCardIds.contains(card.id);
      var result = _rewardService.recordDailyAnswer(assigned, date);
      result = result.copyWith(
        lastDailyQuestionDate: date,
        lastDailyQuestionId: question.id,
        lastDailyCardId: cardId,
      );
      if (card != null && !assigned.ownedCardIds.contains(card.id)) {
        result = _rewardService.applyReward(result, card);
      }
      return result;
    });

    return DailyAnswerResult(
      saveData: updated,
      cardWasOwnedBeforeAnswer: cardWasOwnedBeforeAnswer,
      alreadyCompleted: alreadyCompleted,
    );
  }

  static void _requireAssignmentValues(
    String date,
    String questionId,
    String cardId,
  ) {
    if (date.trim().isEmpty ||
        questionId.trim().isEmpty ||
        cardId.trim().isEmpty) {
      throw ArgumentError(
        'Daily assignment date, question id, and card id are required.',
      );
    }
  }
}
