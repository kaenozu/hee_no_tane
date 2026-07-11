/// lib/domain/services/reward_service.dart
///
/// カード収集報酬ロジック。
library;
/// 今日の問題に関連する未所有カードを特定し、コレクションに追加する。
///
/// 関連:
///   - ../models/question.dart
///   - ../models/hee_card.dart
///   - ../models/save_data.dart

import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
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

    final cardMap = {for (final c in allCards) c.id: c};

    for (final q in todayQuestions) {
      if (ownedCardIds.contains(q.relatedCardId)) continue;
      final card = cardMap[q.relatedCardId];
      if (card != null) return card;
    }

    return null;
  }

  SaveData applyReward(SaveData saveData, HeeCard card) {
    if (saveData.ownedCardIds.contains(card.id)) return saveData;
    return saveData.copyWith(ownedCardIds: [...saveData.ownedCardIds, card.id]);
  }

  SaveData updatePlayStats(SaveData saveData, String today) {
    final newPlayCount = saveData.totalBrowseCount + 1;

    int newStreak;
    if (saveData.lastPlayedDate == today) {
      newStreak = saveData.streakDays;
    } else if (saveData.lastPlayedDate.isEmpty) {
      newStreak = 1;
    } else {
      final last = DateTime.tryParse(saveData.lastPlayedDate);
      final now = DateTime.tryParse(today);
      if (last != null && now != null) {
        final diff = now.difference(last).inDays;
        newStreak = (diff == 1) ? saveData.streakDays + 1 : 1;
      } else {
        newStreak = saveData.streakDays;
      }
    }

    return saveData.copyWith(
      totalBrowseCount: newPlayCount,
      streakDays: newStreak,
      lastPlayedDate: today,
    );
  }
}
