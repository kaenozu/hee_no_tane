import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

class BattleService {
  static const int playerMaxHp = 60;
  static const int baseDamage = 12;
  static const int baseEnemyDamage = 8;
  static const int maxComboBonus = 6;
  static const int comboBonusPerCount = 2;

  int calculateDamage(int combo) {
    final comboBonus = (combo * comboBonusPerCount).clamp(0, maxComboBonus);
    return baseDamage + comboBonus;
  }

  int calculateEnemyDamage(int floor) {
    final floorBonus = floor - 1;
    return baseEnemyDamage + floorBonus;
  }

  bool isCorrect(Question question, int selectedIndex) {
    return question.answerIndex == selectedIndex;
  }

  BattleAnswerResult answer({
    required BattleState state,
    required int selectedIndex,
  }) {
    final question = state.questions[state.currentQuestionIndex];
    final correct = isCorrect(question, selectedIndex);

    int damageDealt = 0;
    int damageTaken = 0;
    int newCombo;
    int newPlayerHp = state.playerHp;
    int newEnemyHp = state.enemyHp;

    if (correct) {
      damageDealt = calculateDamage(state.combo);
      newEnemyHp -= damageDealt;
      newCombo = state.combo + 1;
    } else {
      damageTaken = calculateEnemyDamage(state.floor);
      newPlayerHp -= damageTaken;
      newCombo = 0;
    }

    final isFloorCleared = newEnemyHp <= 0;
    final isBossFloor = state.floor == 5;
    final isClear = isFloorCleared && isBossFloor;
    final isGameOver = newPlayerHp <= 0;

    return BattleAnswerResult(
      isCorrect: correct,
      damageDealt: damageDealt,
      damageTaken: damageTaken,
      playerHpAfter: newPlayerHp.clamp(0, playerMaxHp),
      enemyHpAfter: newEnemyHp.clamp(0, state.enemyMaxHp),
      comboAfter: newCombo,
      isFloorCleared: isFloorCleared,
      isGameOver: isGameOver,
      isClear: isClear,
      question: question,
    );
  }
}
