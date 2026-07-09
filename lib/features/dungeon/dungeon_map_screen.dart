import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/daily_dungeon_service.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/features/battle/battle_screen.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';

class DungeonMapScreen extends StatelessWidget {
  final List<Question> questions;
  final DailyDungeonService dungeonService;
  final BattleService battleService;
  final GameAudioService audioService;
  final void Function(BattleState) onStateChanged;
  final VoidCallback onDungeonComplete;

  const DungeonMapScreen({
    super.key,
    required this.questions,
    required this.dungeonService,
    required this.battleService,
    required this.audioService,
    required this.onStateChanged,
    required this.onDungeonComplete,
  });

  String _enemyName(int floor) {
    return dungeonService.getEnemyForFloor(floor).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DungeonPalette.dungeonBottom,
      body: DungeonBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              children: [
                const RibbonTitle(text: '今日のダンジョン', icon: Icons.explore),
                const SizedBox(height: 10),
                const Text(
                  '5問でクリア',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 18, bottom: 16),
                    children: [
                      ParchmentPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 18,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 560;
                            return compact
                                ? _compactFloorList()
                                : _wideFloorRoute();
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      _rewardPanel(),
                    ],
                  ),
                ),
                SizedBox(
                  key: const ValueKey('enter-dungeon-cta'),
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'ダンジョンに入る',
                    child: ElevatedButton.icon(
                      onPressed: () => _enterDungeon(context),
                      icon: const Icon(Icons.shield),
                      label: const Text(
                        'ダンジョンに入る',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DungeonPalette.gold,
                        foregroundColor: DungeonPalette.ink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: DungeonPalette.ink,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rewardPanel() {
    return ParchmentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: DungeonPalette.teal),
              const SizedBox(width: 8),
              const Text(
                '今日の報酬',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: DungeonPalette.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DungeonPalette.ember,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'New!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 104,
                height: 88,
                decoration: BoxDecoration(
                  color: DungeonPalette.teal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DungeonPalette.ink, width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.landscape, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'へぇカードをゲット！\nクリアすると知識カードが1枚発芽します。',
                  style: TextStyle(
                    color: DungeonPalette.ink.withValues(alpha: 0.86),
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wideFloorRoute() {
    return Row(
      children: List.generate(9, (index) {
        if (index.isOdd) {
          return const Expanded(
            child: Divider(color: DungeonPalette.gold, thickness: 4),
          );
        }
        final floor = index ~/ 2 + 1;
        return DungeonFloorNode(
          floor: floor,
          isBoss: floor == 5,
          isCurrent: floor == 1,
          icon: _floorIcon(floor),
        );
      }),
    );
  }

  Widget _compactFloorList() {
    return Column(
      children: List.generate(5, (index) {
        final floor = index + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              DungeonFloorNode(
                floor: floor,
                isBoss: floor == 5,
                isCurrent: floor == 1,
                icon: _floorIcon(floor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _enemyName(floor),
                  style: const TextStyle(
                    color: DungeonPalette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _floorIcon(int floor) {
    final enemy = dungeonService.getEnemyForFloor(floor);
    if (enemy.imageAsset.isEmpty) {
      return Icon(
        floor == 5 ? Icons.menu_book : Icons.question_mark,
        color: DungeonPalette.ink,
      );
    }
    return Image.asset(
      enemy.imageAsset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        floor == 5 ? Icons.menu_book : Icons.question_mark,
        color: DungeonPalette.ink,
      ),
    );
  }

  void _enterDungeon(BuildContext context) {
    final firstEnemy = dungeonService.getEnemyForFloor(1);
    final initialState = BattleState(
      playerHp: BattleService.playerMaxHp,
      playerMaxHp: BattleService.playerMaxHp,
      enemyHp: firstEnemy.maxHp,
      enemyMaxHp: firstEnemy.maxHp,
      combo: 0,
      floor: 1,
      currentQuestionIndex: 0,
      questions: questions,
      enemy: firstEnemy,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BattleScreen(
          initialState: initialState,
          battleService: battleService,
          dungeonService: dungeonService,
          audioService: audioService,
          onDungeonComplete: onDungeonComplete,
          onStateChanged: onStateChanged,
        ),
      ),
    );
  }
}
