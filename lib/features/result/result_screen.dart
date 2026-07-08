import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';

class ResultScreen extends StatelessWidget {
  final bool isClear;
  final int correctCount;
  final int finalFloor;
  final int remainingHp;
  final HeeCard? obtainedCard;

  const ResultScreen({
    super.key,
    required this.isClear,
    required this.correctCount,
    required this.finalFloor,
    required this.remainingHp,
    this.obtainedCard,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: DungeonPalette.dungeonBottom,
        body: DungeonBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    RibbonTitle(
                      text: isClear ? 'ダンジョンクリア！' : 'たびのしっぱい...',
                      icon: isClear
                          ? Icons.emoji_events
                          : Icons.sentiment_dissatisfied,
                    ),
                    const SizedBox(height: 18),
                    ParchmentPanel(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statBadge(
                                Icons.check_circle_outline,
                                '正解数',
                                '$correctCount / 5問',
                              ),
                              const SizedBox(width: 10),
                              _statBadge(
                                Icons.favorite,
                                '残りHP',
                                '$remainingHp',
                              ),
                              const SizedBox(width: 10),
                              _statBadge(
                                Icons.map_outlined,
                                '到達',
                                '${finalFloor}F',
                              ),
                            ],
                          ),
                          if (isClear && obtainedCard != null) ...[
                            const SizedBox(height: 22),
                            const Text(
                              'へぇカードをゲット！',
                              style: TextStyle(
                                color: DungeonPalette.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 420;
                                final detail = _rewardDetail();
                                if (narrow) {
                                  return Column(
                                    children: [
                                      _rewardCard(),
                                      const SizedBox(height: 14),
                                      detail,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _rewardCard(),
                                    const SizedBox(width: 18),
                                    Expanded(child: detail),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
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
                        child: const Text(
                          'ホームに戻る',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rewardCard() {
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        width: 132,
        height: 168,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DungeonPalette.teal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DungeonPalette.gold, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              obtainedCard!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF86BBD8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.landscape,
                  color: Colors.white,
                  size: 58,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardDetail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5D2E), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            obtainedCard!.title,
            style: const TextStyle(
              color: DungeonPalette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            obtainedCard!.shortText,
            style: TextStyle(
              color: DungeonPalette.ink.withValues(alpha: 0.78),
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5D2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              obtainedCard!.category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B5D2E), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: DungeonPalette.teal),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: DungeonPalette.ink.withValues(alpha: 0.68),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: DungeonPalette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
