import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/daily_dungeon_service.dart';
import 'package:hee_no_tane_app/features/battle/battle_screen.dart';
import 'package:hee_no_tane_app/features/dungeon/dungeon_map_screen.dart';

void main() {
  testWidgets('enter dungeon button stays tappable on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final questions = List.generate(5, (index) {
      return Question(
        id: 'q$index',
        category: 'test',
        difficulty: 'easy',
        question: '問題$index',
        choices: const ['A', 'B', 'C', 'D'],
        answerIndex: 0,
        explanation: '解説$index',
        relatedCardId: 'card$index',
        sourceNote: 'test',
        verified: true,
      );
    });
    final enemy = Enemy(
      id: 'enemy',
      name: 'テスト敵',
      type: 'normal',
      maxHp: 24,
      attack: 8,
      imageAsset: '',
    );
    final boss = Enemy(
      id: 'boss',
      name: 'テストボス',
      type: 'boss',
      maxHp: 36,
      attack: 12,
      imageAsset: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DungeonMapScreen(
          questions: questions,
          dungeonService: DailyDungeonService([enemy], boss),
          battleService: BattleService(),
          audioService: GameAudioService(enabled: false),
          onStateChanged: (_) {},
          onDungeonComplete: () {},
        ),
      ),
    );

    expect(find.text('ダンジョンに入る'), findsOneWidget);
    await tester.tap(find.text('ダンジョンに入る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BattleScreen), findsOneWidget);
  });
}
