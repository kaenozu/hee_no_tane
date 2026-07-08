import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/daily_dungeon_service.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/dungeon/dungeon_map_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_list_screen.dart';
import 'package:hee_no_tane_app/features/result/result_screen.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';
import 'package:hee_no_tane_app/widgets/home_painters.dart';

class HomeScreen extends StatefulWidget {
  final List<Question> allQuestions;
  final List<HeeCard> allCards;
  final List<Enemy> allEnemies;
  final SaveRepository saveRepository;
  final BattleService battleService;
  final RewardService rewardService;
  final GameAudioService audioService;

  const HomeScreen({
    super.key,
    required this.allQuestions,
    required this.allCards,
    required this.allEnemies,
    required this.saveRepository,
    required this.battleService,
    required this.rewardService,
    required this.audioService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SaveData _saveData = SaveData();
  BattleState? _lastBattleState;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaveData();
  }

  Future<void> _loadSaveData() async {
    final data = await widget.saveRepository.load();
    setState(() {
      _saveData = data;
      _loading = false;
    });
  }

  Future<void> _startDungeon() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final normalEnemies = widget.allEnemies
        .where((e) => e.type == 'normal')
        .toList();
    if (widget.allEnemies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('敵データが不足しています')));
      }
      return;
    }

    final bossEnemy = widget.allEnemies.firstWhere(
      (e) => e.type == 'boss',
      orElse: () => widget.allEnemies.first,
    );
    final dungeonService = DailyDungeonService(normalEnemies, bossEnemy);
    final questions = dungeonService.generateQuestions(
      dateStr,
      widget.allQuestions,
    );

    if (questions.length < 5) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('問題データが不足しています')));
      }
      return;
    }

    unawaited(widget.audioService.playBgm());

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DungeonMapScreen(
          questions: questions,
          dungeonService: dungeonService,
          battleService: widget.battleService,
          audioService: widget.audioService,
          onStateChanged: _onBattleStateChanged,
          onDungeonComplete: () =>
              _onDungeonComplete(questions, dungeonService, dateStr),
        ),
      ),
    );
    if (result == true) await _loadSaveData();
  }

  void _onBattleStateChanged(BattleState state) {
    _lastBattleState = state;
  }

  Future<void> _onDungeonComplete(
    List<Question> questions,
    DailyDungeonService dungeonService,
    String dateStr,
  ) async {
    final finalState = _lastBattleState!;
    final isClear = finalState.floor == 5 && finalState.enemyHp <= 0;

    HeeCard? obtainedCard;
    if (isClear) {
      obtainedCard = widget.rewardService.determineReward(
        todayQuestions: questions,
        ownedCardIds: _saveData.ownedCardIds,
        allCards: widget.allCards,
        today: dateStr,
        lastRewardDate: _saveData.lastRewardDate,
      );
      if (obtainedCard != null) {
        _saveData = widget.rewardService.applyReward(_saveData, obtainedCard);
      }
    }

    _saveData = widget.rewardService.updatePlayStats(
      _saveData,
      dateStr,
      isClear,
    );
    await widget.saveRepository.save(_saveData);
    setState(() {});

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          isClear: isClear,
          correctCount: finalState.correctCount,
          finalFloor: finalState.floor,
          remainingHp: finalState.playerHp.clamp(0, BattleService.playerMaxHp),
          obtainedCard: obtainedCard,
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: DungeonPalette.dungeonBottom,
        body: const DungeonBackground(
          child: Center(
            child: CircularProgressIndicator(color: DungeonPalette.gold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DungeonPalette.dungeonBottom,
      body: DungeonBackground(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _heroHeader(),
              const SizedBox(height: 14),
              Expanded(
                child: ParchmentPanel(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    children: [
                      const RibbonTitle(
                        text: '知識で進む 1分ダンジョン',
                        icon: Icons.lightbulb,
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/images/backgrounds/home_dungeon.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => CustomPaint(
                                    painter: HomeDungeonPainter(),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 12,
                              child: AliveMotion(
                                bob: 6,
                                sway: 2,
                                child: _heroCharacter(),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 18,
                              child: AliveMotion(
                                duration: const Duration(milliseconds: 2100),
                                bob: 3,
                                scale: 0.025,
                                reverse: true,
                                child: PulseGlow(
                                  color: DungeonPalette.gold,
                                  blurRadius: 14,
                                  child: _treasureBox(),
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 24,
                              bottom: 24,
                              child: AliveMotion(
                                duration: Duration(milliseconds: 1300),
                                bob: 8,
                                scale: 0.05,
                                reverse: true,
                                child: Text(
                                  '?',
                                  style: TextStyle(
                                    fontSize: 42,
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: PulseGlow(
                          color: DungeonPalette.gold,
                          blurRadius: 10,
                          child: ElevatedButton.icon(
                            onPressed: _startDungeon,
                            icon: const Icon(Icons.arrow_forward, size: 26),
                            label: const Text(
                              '今日のダンジョン',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DungeonPalette.gold,
                              foregroundColor: DungeonPalette.ink,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                  color: DungeonPalette.ink,
                                  width: 2,
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _featureChip(Icons.timer, '1日3分', 'スキマ時間でサクッと！'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _featureChip(Icons.menu_book, '雑学', '遊んで賢くなる！'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCircle(
                    context,
                    '${_saveData.ownedCardIds.length}',
                    'カード',
                  ),
                  _statCircle(context, '${_saveData.streakDays}', '連続日数'),
                  _statCircle(context, '${_saveData.totalPlayCount}', 'プレイ'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _iconButton(context, Icons.collections_bookmark, '図鑑', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CardListScreen(
                          saveData: _saveData,
                          allCards: widget.allCards,
                        ),
                      ),
                    ).then((_) => _loadSaveData());
                  }),
                  _iconButton(context, Icons.settings_outlined, '設定', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          saveRepository: widget.saveRepository,
                          rewardService: widget.rewardService,
                          audioService: widget.audioService,
                          onDataReset: () =>
                              setState(() => _saveData = SaveData()),
                        ),
                      ),
                    ).then((_) => _loadSaveData());
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCircle(BuildContext context, String value, String label) {
    return Expanded(
      child: ParchmentPanel(
        padding: const EdgeInsets.symmetric(vertical: 8),
        radius: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: DungeonPalette.teal,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: DungeonPalette.ink.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xDD171A22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2F3646)),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: 28),
            style: IconButton.styleFrom(
              foregroundColor: DungeonPalette.gold,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _heroHeader() {
    return ParchmentPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      color: const Color(0xFFFFF7E8),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: Color(0xFF8B5D2E), size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'へぇダンジョン',
                  style: TextStyle(
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: DungeonPalette.ink,
                    shadows: [
                      Shadow(
                        color: DungeonPalette.gold.withValues(alpha: 0.75),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '知識で進む1分クイズRPG',
                  style: TextStyle(
                    color: DungeonPalette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.help, color: Color(0xFF5DDCFF), size: 42),
        ],
      ),
    );
  }

  Widget _heroCharacter() {
    return SizedBox(
      height: 136,
      child: Image.asset(
        'assets/images/characters/player.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person, size: 82, color: Colors.white),
      ),
    );
  }

  Widget _treasureBox() {
    return SizedBox(
      width: 94,
      height: 70,
      child: Image.asset(
        'assets/images/ui/treasure_chest.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            CustomPaint(painter: TreasureChestPainter()),
      ),
    );
  }

  Widget _featureChip(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: title == '1日3分' ? DungeonPalette.teal : DungeonPalette.gold,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DungeonPalette.ink, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: title == '1日3分' ? Colors.white : DungeonPalette.ink,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: title == '1日3分' ? Colors.white : DungeonPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (title == '1日3分' ? Colors.white : DungeonPalette.ink)
                        .withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


