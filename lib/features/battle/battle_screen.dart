import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/daily_dungeon_service.dart';
import 'package:hee_no_tane_app/widgets/animated_shake.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';

enum BattleUiPhase {
  idle,
  resolving,
  showExplanation,
  floorClear,
  dungeonClear,
  gameOver,
}

class BattleScreen extends StatefulWidget {
  final BattleState initialState;
  final BattleService battleService;
  final DailyDungeonService dungeonService;
  final GameAudioService audioService;
  final VoidCallback onDungeonComplete;
  final ValueNotifier<BattleState> battleStateNotifier;

  const BattleScreen({
    super.key,
    required this.initialState,
    required this.battleService,
    required this.dungeonService,
    required this.audioService,
    required this.onDungeonComplete,
    required this.battleStateNotifier,
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
    widget.battleStateNotifier.value = _state;
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
    widget.battleStateNotifier.value = _state;
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
    widget.battleStateNotifier.value = _state;
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
        Expanded(flex: 3, child: _stage()),
        const SizedBox(width: 14),
        Expanded(flex: 4, child: _quizPanel(question)),
      ],
    );
  }

  Widget _compactBattle(Question question) {
    return ListView(
      children: [
        SizedBox(height: 240, child: _stage()),
        const SizedBox(height: 12),
        _quizPanel(question),
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

  Widget _stage() {
    final result = _lastResult;
    final correctResolving =
        _phase == BattleUiPhase.resolving && result?.isCorrect == true;
    final wrongResolving =
        _phase == BattleUiPhase.resolving && result?.isCorrect == false;
    final defeated =
        result?.isFloorCleared == true &&
        (_phase == BattleUiPhase.floorClear ||
            _phase == BattleUiPhase.dungeonClear);

    return ParchmentPanel(
      padding: EdgeInsets.zero,
      color: const Color(0xFF1B2431),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/battle_stage.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF24344A), Color(0xFF0F1722)],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.72, 0.45),
              child: AnimatedSlide(
                offset: correctResolving
                    ? const Offset(0.14, -0.04)
                    : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: AnimatedShake(
                  trigger: wrongResolving ? _reactionSerial : 0,
                  distance: 10,
                  child: AliveMotion(
                    duration: const Duration(milliseconds: 1600),
                    bob: 5,
                    sway: 2,
                    child: _characterImage(
                      'assets/images/characters/player.png',
                      112,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.7, 0.34),
              child: AnimatedOpacity(
                opacity: defeated ? 0 : 1,
                duration: const Duration(milliseconds: 360),
                child: AnimatedScale(
                  scale: defeated ? 0.4 : 1,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeInBack,
                  child: AnimatedShake(
                    trigger: correctResolving ? _reactionSerial : 0,
                    distance: 13,
                    child: AliveMotion(
                      duration: const Duration(milliseconds: 1350),
                      bob: 6,
                      scale: 0.025,
                      reverse: true,
                      child: _enemyImage(_state.enemy, 136),
                    ),
                  ),
                ),
              ),
            ),
            if (correctResolving) _effectImage('slash.png', 0.58, 0.28, 180),
            if (correctResolving)
              _effectImage('hit_spark.png', 0.67, 0.34, 150),
            if (wrongResolving) _stampImage('stamp_wrong.png'),
            if (result?.isCorrect == true && _phase != BattleUiPhase.idle)
              _stampImage(
                'stamp_correct.png',
                align: const Alignment(-0.18, -0.7),
              ),
            if (defeated) _effectImage('defeat_smoke.png', 0.7, 0.48, 180),
            if (_isAnswered) _damagePopup(),
            if (_phase == BattleUiPhase.floorClear ||
                _phase == BattleUiPhase.dungeonClear)
              _clearBanner(_phase == BattleUiPhase.dungeonClear),
          ],
        ),
      ),
    );
  }

  Widget _effectImage(String name, double x, double y, double size) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$name-$_reactionSerial'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: (1.1 - value).clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.75 + value * 0.35, child: child),
          );
        },
        child: Align(
          alignment: Alignment(x * 2 - 1, y * 2 - 1),
          child: Image.asset('assets/images/effects/$name', width: size),
        ),
      ),
    );
  }

  Widget _stampImage(String name, {Alignment align = Alignment.center}) {
    return Align(
      alignment: align,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$name-$_reactionSerial'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.rotate(
            angle: -0.14 + value * 0.14,
            child: Transform.scale(scale: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Image.asset('assets/images/effects/$name', width: 126),
      ),
    );
  }

  Widget _clearBanner(bool dungeonClear) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: dungeonClear ? DungeonPalette.gold : DungeonPalette.teal,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DungeonPalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          dungeonClear ? 'ダンジョンクリア！' : 'フロアクリア！',
          style: TextStyle(
            color: dungeonClear ? DungeonPalette.ink : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _damagePopup() {
    final result = _lastResult;
    final isCorrect = result?.isCorrect ?? false;
    final label = isCorrect
        ? '-${result?.damageDealt ?? 0}'
        : '-${result?.damageTaken ?? 0} HP';
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_reactionSerial),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: (1.25 - value).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -38 * value),
              child: Transform.scale(scale: 0.55 + value * 0.55, child: child),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isCorrect ? DungeonPalette.ember : const Color(0xFF4B5563),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _quizPanel(Question question) {
    return ParchmentPanel(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        child: _phase == BattleUiPhase.idle || _phase == BattleUiPhase.resolving
            ? _questionChoices(question)
            : _explanationPanel(),
      ),
    );
  }

  Widget _questionChoices(Question question) {
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
            (i) => _choiceButton(question, i),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DungeonPalette.teal,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0A4D49), width: 2),
          ),
          child: Text(
            _phase == BattleUiPhase.resolving
                ? (_lastResult?.isCorrect == true ? '攻撃中！' : '敵の反撃！')
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

  Widget _explanationPanel() {
    final result = _lastResult!;
    final correctAnswer = result.question.choices[result.question.answerIndex];
    final isTerminal =
        _phase == BattleUiPhase.dungeonClear ||
        _phase == BattleUiPhase.gameOver;
    final title = switch (_phase) {
      BattleUiPhase.floorClear => 'フロアクリア！',
      BattleUiPhase.dungeonClear => 'ボス撃破！',
      BattleUiPhase.gameOver => 'ゲームオーバー',
      _ => result.isCorrect ? '正解！' : 'ざんねん...',
    };
    final buttonLabel = switch (_phase) {
      BattleUiPhase.floorClear => '次の階へ',
      BattleUiPhase.dungeonClear => '報酬を見る',
      BattleUiPhase.gameOver => '結果へ',
      _ => '続ける',
    };

    return Column(
      key: ValueKey('explanation-${_phase.name}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              result.isCorrect ? Icons.bolt : Icons.shield,
              color: result.isCorrect ? DungeonPalette.ember : Colors.blueGrey,
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
              ? '${result.damageDealt}ダメージ！ 敵HP ${result.enemyHpAfter}/${_state.enemyMaxHp}'
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
        if (_phase == BattleUiPhase.dungeonClear) ...[
          const SizedBox(height: 12),
          _rewardOverlayCard(),
        ],
        if (isTerminal) const SizedBox(height: 2),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _continueAfterResult,
          style: ElevatedButton.styleFrom(
            backgroundColor: DungeonPalette.gold,
            foregroundColor: DungeonPalette.ink,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: DungeonPalette.ink, width: 2),
            ),
          ),
          child: Text(
            buttonLabel,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
        border: Border.all(color: DungeonPalette.gold, width: 3),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/ui/treasure_chest.png', width: 74),
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

  Widget _choiceButton(Question question, int i) {
    final isSelected = _selectedIndex == i;
    final isAnswer = i == question.answerIndex;
    final bgColor = _isAnswered && isAnswer
        ? const Color(0xFF16A34A)
        : _isAnswered && isSelected
        ? const Color(0xFFE95A2A)
        : const Color(0xFFFFFBED);

    return ElevatedButton(
      onPressed: _isAnswered ? null : () => _answer(i),
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: bgColor,
        disabledForegroundColor: DungeonPalette.ink,
        backgroundColor: bgColor,
        foregroundColor: DungeonPalette.ink,
        elevation: _isAnswered ? 0 : 3,
        shadowColor: const Color(0x77000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? DungeonPalette.gold : const Color(0xFF8B5D2E),
            width: 2,
          ),
        ),
      ),
      child: Text(
        question.choices[i],
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _isAnswered && (isAnswer || isSelected)
              ? Colors.white
              : DungeonPalette.ink,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _bottomInventory() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _inventoryChip(Icons.account_balance, '${_state.floor}F / 5F'),
          _inventoryChip(Icons.monetization_on, '128'),
          _inventoryChip(Icons.diamond, '23'),
          _inventoryChip(Icons.key, '1'),
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

  Widget _enemyImage(Enemy enemy, double size) {
    if (enemy.imageAsset.isNotEmpty) {
      return SizedBox(
        height: size,
        width: size,
        child: Image.asset(enemy.imageAsset, fit: BoxFit.contain),
      );
    }
    return SizedBox(
      height: size,
      child: const Icon(
        Icons.local_fire_department,
        size: 64,
        color: Colors.red,
      ),
    );
  }

  Widget _characterImage(String asset, double size) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person, color: Colors.white, size: 72),
      ),
    );
  }
}
