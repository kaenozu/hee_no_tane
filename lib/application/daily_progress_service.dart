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

/// A daily-answer save failed after the updater had already determined the
/// pre-answer reward state.
///
/// Persistent stores can fail after a write has reached storage but before the
/// caller receives confirmation. Retaining this metadata lets the UI retry the
/// idempotent update without changing an initial "new card" result into an
/// "already owned" result.
class DailyAnswerSaveException extends SaveException {
  final bool cardWasOwnedBeforeAnswer;

  const DailyAnswerSaveException(
    super.message, {
    super.cause,
    required this.cardWasOwnedBeforeAnswer,
  });
}

class DailyProgressService {
  final SaveRepository saveRepository;
  final RewardService rewardService;

  const DailyProgressService({
    required this.saveRepository,
    required this.rewardService,
  });

  Future<SaveData> ensureAssignment({
    required String date,
    required String questionId,
    required String cardId,
  }) {
    _requireAssignmentValues(date, questionId, cardId);
    return saveRepository.update((current) {
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

  Future<SaveData> repairAssignment({
    required String date,
    required String questionId,
    required String cardId,
  }) {
    _requireAssignmentValues(date, questionId, cardId);
    return saveRepository.update((current) {
      if (current.lastDailyQuestionDate == date) {
        throw const SaveException('回答済みの日次割り当ては変更できません。');
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
    _requireAnswerValues(date, question.id);

    bool? cardWasOwnedBeforeAnswer;
    var alreadyCompleted = false;
    late final SaveData updated;
    try {
      updated = await saveRepository.update((current) {
        cardWasOwnedBeforeAnswer = null;
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
        if (cardId.isNotEmpty &&
            !current.hasDailyAssignment(
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
        var result = rewardService.recordDailyAnswer(assigned, date);
        // lastDailyCardIdとして永続するIDは必ず回答時点で所有済みにする。
        // card未解決でrelatedCardIdが未所有の場合は、ここで所有を先に付与し
        // 割り当て・履歴・所有の三点一致を保つ。これを怠ると、割り当てに
        // 含まれる未所有カードを翌起動のホーム所有チェックが拒否し、
        // 回答導線が恒久的に塞がる。
        final grantsRewardCard =
            card != null && !assigned.ownedCardIds.contains(card.id);
        final grantsRelatedCard =
            card == null &&
            cardId.isNotEmpty &&
            !assigned.ownedCardIds.contains(cardId);
        final effectiveOwnedCards = <String>{...assigned.ownedCardIds};
        if (grantsRewardCard) effectiveOwnedCards.add(card.id);
        if (grantsRelatedCard) effectiveOwnedCards.add(cardId);
        final persistableCardId = effectiveOwnedCards.contains(cardId)
            ? cardId
            : '';
        result = result.copyWith(
          lastDailyQuestionDate: date,
          lastDailyQuestionId: question.id,
          lastDailyCardId: persistableCardId,
        );
        if (grantsRewardCard) {
          result = rewardService.applyReward(result, card);
        } else if (grantsRelatedCard) {
          result = result.copyWith(
            ownedCardIds: <String>[...result.ownedCardIds, cardId],
          );
        }
        return result;
      });
    } on SaveException catch (error) {
      final ownership = cardWasOwnedBeforeAnswer;
      if (ownership != null) {
        throw DailyAnswerSaveException(
          error.message,
          cause: error.cause,
          cardWasOwnedBeforeAnswer: ownership,
        );
      }
      rethrow;
    }

    return DailyAnswerResult(
      saveData: updated,
      cardWasOwnedBeforeAnswer: cardWasOwnedBeforeAnswer ?? true,
      alreadyCompleted: alreadyCompleted,
    );
  }

  static void _requireAnswerValues(String date, String questionId) {
    if (date.trim().isEmpty || questionId.trim().isEmpty) {
      throw ArgumentError('Daily answer date and question id are required.');
    }
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
