/// Card reward and user statistics rules.
library;

import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

class RewardService {
  HeeCard? determineReward({
    required List<Question> todayQuestions,
    required List<String> ownedCardIds,
    required List<HeeCard> allCards,
    required String today,
    required String lastRewardDate,
  }) {
    if (lastRewardDate == today) return null;
    final cardMap = {for (final card in allCards) card.id: card};
    for (final question in todayQuestions) {
      if (ownedCardIds.contains(question.relatedCardId)) continue;
      final card = cardMap[question.relatedCardId];
      if (card != null) return card;
    }
    return null;
  }

  SaveData applyReward(SaveData saveData, HeeCard card) {
    if (saveData.ownedCardIds.contains(card.id)) return saveData;
    return saveData.copyWith(
      ownedCardIds: <String>[...saveData.ownedCardIds, card.id],
    );
  }

  /// Records one completed daily answer and updates the answer streak.
  SaveData recordDailyAnswer(SaveData saveData, String today) {
    final newPlayCount = saveData.totalPlayCount + 1;
    int newStreak;
    if (saveData.lastPlayedDate == today) {
      newStreak = saveData.streakDays;
    } else if (saveData.lastPlayedDate.isEmpty) {
      newStreak = 1;
    } else {
      final last = DateTime.tryParse(saveData.lastPlayedDate);
      final now = DateTime.tryParse(today);
      if (last != null && now != null) {
        final diff = DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(last.year, last.month, last.day)).inDays;
        newStreak = diff == 1 ? saveData.streakDays + 1 : 1;
      } else {
        newStreak = saveData.streakDays;
      }
    }
    return saveData.copyWith(
      totalPlayCount: newPlayCount,
      streakDays: newStreak,
      lastPlayedDate: today,
    );
  }

  /// Records a card-detail view without changing answer streak statistics.
  SaveData recordCardView(SaveData saveData) =>
      saveData.copyWith(totalBrowseCount: saveData.totalBrowseCount + 1);
}
