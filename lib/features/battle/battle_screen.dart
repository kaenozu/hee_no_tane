import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/daily_dungeon_service.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';
import 'package:hee_no_tane_app/features/battle/battle_ui_phase.dart';
import 'package:hee_no_tane_app/features/battle/battle_stage.dart';
import 'package:hee_no_tane_app/features/battle/quiz_panel.dart';

class BattleScreen extends StatefulWidget {
  final BattleState initialState;
  final BattleService battleService;
  final DailyDungeonService dungeonService;
  final GameAudioService audioService;
  final VoidCallback onDungeonComplete;
  final void Function(BattleState)? onStateChanged;

  const BattleScreen({
    super.key,
    required this.initialState,
    required this.battleService,
    required this.dungeonService,
    required this.audioService,
    required this.onDungeonComplete,
    this.onStateChanged,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late BattleState _state;
  BattleUiPhase _phase = BattleUiPhase.idle;
  int? _selectedIndex;
  BattleAnswerResult? _lastResult;
  int _reactionSerial = 0;

  bool get _isAnswered => _phase != BattleUiPhase.idle;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    widget.onStateChanged?.call(_state);
  }

  void _answer(int index) {
    if (_phase != BattleUiPhase.idle) return;

    widget.audioService.playSelect();
    final result = widget.battleService.answer(
      state: _state,
      selectedIndex: index,
    );

    setState(() {
      _phase = BattleUiPhase.resolving;
      _selectedIndex = index;
      _lastResult = result;
      _reactionSerial++;
      _state = _state.copyWith(
        playerHp: result.playerHpAfter,
        enemyHp: result.enemyHpAfter,
        combo: result.comboAfter,
        correctCount: _state.correctCount + (result.isCorrect ? 1 : 0),
      );
    });
    widget.onStateChanged?.call(_state);
    _playAnswerAudio(result);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _lastResult != result) return;
      setState(() {
        if (result.isClear) {
          _phase = BattleUiPhase.dungeonClear;
        } else if (result.isGameOver) {
          _phase = BattleUiPhase.gameOver;
        } else if (result.isFloorCleared) {
          _phase = BattleUiPhase.floorClear;
        } else {
          _phase = BattleUiPhase.showExplanation;
        }
      });
    });
  }

  void _playAnswerAudio(BattleAnswerResult result) {
    if (result.isCorrect) {
      widget.audioService.playCorrect();
      widget.audioService.playHit();
      if (result.isFloorCleared) {
        Future.delayed(const Duration(milliseconds: 280), () {
          widget.audioService.playEnemyDown();
        });
        Future.delayed(const Duration(milliseconds: 620), () {
          if (result.isClear) {
            widget.audioService.playReward();
          } else {
            widget.audioService.playFloorClear();
          }
        });
      }
    } else {
      widget.audioService.playWrong();
      Future.delayed(const Duration(milliseconds: 260), () {
        widget.audioService.playHit();
      });
    }
  }

  void _continueAfterResult() {
    final result = _lastResult;
    if (result == null) return;

    if (result.isClear || result.isGameOver) {
      widget.onDungeonComplete();
      return;
    }

    if (result.isFloorCleared) {
      _advanceFloor();
      return;
    }

    setState(() {
      _phase = BattleUiPhase.idle;
      _selectedIndex = null;
      _lastResult = null;
    });
  }

  void _advanceFloor() {
    final nextFloor = _state.floor + 1;
    final nextEnemy = widget.dungeonService.getEnemyForFloor(nextFloor);
    setState(() {
      _state = _state.copyWith(
        floor: nextFloor,
        enemyHp: nextEnemy.maxHp,
        enemy: nextEnemy,
        currentQuestionIndex: _state.currentQuestionIndex + 1,
        combo: _state.combo,
      );
      _phase = BattleUiPhase.idle;
      _selectedIndex = null;
      _lastResult = null;
      _reactionSerial++;
    });
    widget.onStateChanged?.call(_state);
  }

  @override
  Widget build(BuildContext context) {
    final question = _state.questions[_state.currentQuestionIndex];
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: DungeonPalette.dungeonBottom,
      body: DungeonBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isWide ? 20 : 12),
            child: Column(
              children: [
                _battleHud(),
                const SizedBox(height: 12),
                Expanded(
                  child: isWide
                      ? _wideBattle(question)
                      : _compactBattle(question),
                ),
                const SizedBox(height: 10),
                _bottomInventory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wideBattle(Question question) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: BattleStage(
            phase: _phase,
            lastResult: _lastResult,
            enemy: _state.enemy,
            reactionSerial: _reactionSerial,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 4,
          child: QuizPanel(
            phase: _phase,
            lastResult: _lastResult,
            question: question,
            selectedIndex: _selectedIndex,
            isAnswered: _isAnswered,
            enemyMaxHp: _state.enemyMaxHp,
            onAnswer: _answer,
            onContinue: _continueAfterResult,
          ),
        ),
      ],
    );
  }

  Widget _compactBattle(Question question) {
    return ListView(
      children: [
        SizedBox(
          height: 240,
          child: BattleStage(
            phase: _phase,
            lastResult: _lastResult,
            enemy: _state.enemy,
            reactionSerial: _reactionSerial,
          ),
        ),
        const SizedBox(height: 12),
        QuizPanel(
          phase: _phase,
          lastResult: _lastResult,
          question: question,
          selectedIndex: _selectedIndex,
          isAnswered: _isAnswered,
          enemyMaxHp: _state.enemyMaxHp,
          onAnswer: _answer,
          onContinue: _continueAfterResult,
        ),
      ],
    );
  }

  Widget _battleHud() {
    return ParchmentPanel(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF171A22),
      radius: 14,
      child: Row(
        children: [
          Expanded(
            child: GameHudBar(
              label: 'HP',
              value: _state.playerHp,
              maxValue: _state.playerMaxHp,
              color: const Color(0xFF7ED957),
              icon: Icons.favorite,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                const Icon(Icons.timer, color: DungeonPalette.gold),
                Text(
                  '${_state.floor}F / 5F',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GameHudBar(
              label: _state.enemy.name,
              value: _state.enemyHp,
              maxValue: _state.enemyMaxHp,
              color: const Color(0xFFE94235),
              icon: Icons.local_fire_department,
            ),
          ),
        ],
      ),
    );
  }



  Widget _bottomInventory() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _inventoryChip(Icons.account_balance, '${_state.floor}F / 5F'),
          _inventoryChip(Icons.monetization_on, '--'),
          _inventoryChip(Icons.diamond, '--'),
          _inventoryChip(Icons.key, '--'),
          _inventoryChip(Icons.backpack, 'もちもの'),
          _inventoryChip(Icons.menu_book, 'メモ'),
        ],
      ),
    );
  }

  Widget _inventoryChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD171A22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2F3646)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: DungeonPalette.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

}
