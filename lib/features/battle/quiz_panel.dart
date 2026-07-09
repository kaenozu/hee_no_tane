/// クイズパネル（問題表示・選択肢・解説）を描画するウィジェット
///
/// BattleScreen の _quizPanel() / _questionChoices() / _explanationPanel()
/// から抽出したクイズ出題・結果表示部分。
///
/// 関連ファイル:
/// - battle_screen.dart (このウィジェットを使用)
/// - battle_stage.dart (画面左/上半分)
/// - battle_ui_phase.dart (UIフェーズ定義)
library;
import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/features/battle/battle_ui_phase.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';

class QuizPanel extends StatelessWidget {
  final BattleUiPhase phase;
  final BattleAnswerResult? lastResult;
  final Question question;
  final int? selectedIndex;
  final bool isAnswered;
  final int enemyMaxHp;
  final void Function(int) onAnswer;
  final VoidCallback onContinue;

  const QuizPanel({
    super.key,
    required this.phase,
    required this.lastResult,
    required this.question,
    required this.selectedIndex,
    required this.isAnswered,
    required this.enemyMaxHp,
    required this.onAnswer,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ParchmentPanel(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        child: phase == BattleUiPhase.idle || phase == BattleUiPhase.resolving
            ? _questionChoices()
            : _explanationPanel(),
      ),
    );
  }

  Widget _questionChoices() {
    return Column(
      key: const ValueKey('choices'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.search, size: 34, color: DungeonPalette.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question.question,
                style: const TextStyle(
                  color: DungeonPalette.ink,
                  fontSize: 19,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 3.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: List.generate(
            question.choices.length,
            (i) => _choiceButton(i),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DungeonPalette.teal,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0A4D49), width: 2),
          ),
          child: Text(
            phase == BattleUiPhase.resolving
                ? (lastResult?.isCorrect == true ? '攻撃中！' : '敵の反撃！')
                : '正解するとダメージ +12',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _choiceButton(int i) {
    final isSelected = selectedIndex == i;
    final isAnswer = i == question.answerIndex;
    final bgColor = isAnswered && isAnswer
        ? const Color(0xFF16A34A)
        : isAnswered && isSelected
            ? const Color(0xFFE95A2A)
            : const Color(0xFFFFFBED);

    return ElevatedButton(
      onPressed: isAnswered ? null : () => onAnswer(i),
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: bgColor,
        disabledForegroundColor: DungeonPalette.ink,
        backgroundColor: bgColor,
        foregroundColor: DungeonPalette.ink,
        elevation: isAnswered ? 0 : 3,
        shadowColor: const Color(0x77000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color:
                isSelected ? DungeonPalette.gold : const Color(0xFF8B5D2E),
            width: 2,
          ),
        ),
      ),
      child: Text(
        question.choices[i],
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isAnswered && (isAnswer || isSelected)
              ? Colors.white
              : DungeonPalette.ink,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _explanationPanel() {
    final result = lastResult;
    if (result == null) return const SizedBox.shrink();
    final correctAnswer =
        result.question.choices[result.question.answerIndex];
    final isTerminal = phase == BattleUiPhase.dungeonClear ||
        phase == BattleUiPhase.gameOver;
    final title = switch (phase) {
      BattleUiPhase.floorClear => 'フロアクリア！',
      BattleUiPhase.dungeonClear => 'ボス撃破！',
      BattleUiPhase.gameOver => 'ゲームオーバー',
      _ => result.isCorrect ? '正解！' : 'ざんねん...',
    };
    final buttonLabel = switch (phase) {
      BattleUiPhase.floorClear => '次の階へ',
      BattleUiPhase.dungeonClear => '報酬を見る',
      BattleUiPhase.gameOver => '結果へ',
      _ => '続ける',
    };

    return Column(
      key: ValueKey('explanation-${phase.name}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              result.isCorrect ? Icons.bolt : Icons.shield,
              color:
                  result.isCorrect ? DungeonPalette.ember : Colors.blueGrey,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: DungeonPalette.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          result.isCorrect
              ? '${result.damageDealt}ダメージ！ 敵HP ${result.enemyHpAfter}/$enemyMaxHp'
              : '${result.damageTaken}ダメージを受けた。正解は「$correctAnswer」',
          style: const TextStyle(
            color: DungeonPalette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC6934B), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'へぇ解説',
                style: TextStyle(
                  color: DungeonPalette.teal,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.question.explanation,
                style: const TextStyle(
                  color: DungeonPalette.ink,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (phase == BattleUiPhase.dungeonClear) ...[
          const SizedBox(height: 12),
          _rewardOverlayCard(),
        ],
        if (isTerminal) const SizedBox(height: 2),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: DungeonPalette.gold,
            foregroundColor: DungeonPalette.ink,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side:
                  const BorderSide(color: DungeonPalette.ink, width: 2),
            ),
          ),
          child: Text(
            buttonLabel,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _rewardOverlayCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: DungeonPalette.gold, width: 3),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/ui/treasure_chest.png',
              width: 74),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'へぇカード獲得チャンス！',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
