import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

class RewardService {
  /// `today` に既に報酬を取得済みなら null を返す。
  /// 未取得の場合は todayQuestions から未所有カードを探して返す。
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
    return saveData.copyWith(
      ownedCardIds: [...saveData.ownedCardIds, card.id],
    );
  }

  SaveData updatePlayStats(SaveData saveData, String today, bool isClear) {
    final newPlayCount = saveData.totalPlayCount + 1;
    final newClearCount =
        isClear ? saveData.totalClearCount + 1 : saveData.totalClearCount;

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
      totalPlayCount: newPlayCount,
      totalClearCount: newClearCount,
      streakDays: newStreak,
      lastPlayedDate: today,
      lastRewardDate: isClear ? today : null,
    );
  }
}
