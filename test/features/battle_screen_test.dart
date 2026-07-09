import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/daily_dungeon_service.dart';
import 'package:hee_no_tane_app/features/battle/battle_screen.dart';

void main() {
  testWidgets('answer shows explanation on the battle screen', (tester) async {
    final question = Question(
      id: 'q1',
      category: 'science',
      difficulty: 'easy',
      question: '一番軽い元素は？',
      choices: const ['水素', '酸素', '鉄', '金'],
      answerIndex: 0,
      explanation: '水素は元素番号1で、もっとも軽い元素です。',
      relatedCardId: 'card1',
      sourceNote: 'test',
      verified: true,
    );
    final enemy = Enemy(
      id: 'e1',
      name: 'テストスライム',
      type: 'normal',
      maxHp: 24,
      attack: 8,
      imageAsset: '',
    );
    final boss = Enemy(
      id: 'boss',
      name: 'テストボス',
      type: 'boss',
      maxHp: 24,
      attack: 10,
      imageAsset: '',
    );
    final state = BattleState(
      playerHp: BattleService.playerMaxHp,
      playerMaxHp: BattleService.playerMaxHp,
      enemyHp: enemy.maxHp,
      enemyMaxHp: enemy.maxHp,
      combo: 0,
      floor: 1,
      currentQuestionIndex: 0,
      questions: [question],
      enemy: enemy,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          initialState: state,
          battleService: BattleService(),
          dungeonService: DailyDungeonService([enemy], boss),
          audioService: GameAudioService(enabled: false),
          onDungeonComplete: () {},
          onStateChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('水素'));
    await tester.pump();
    expect(find.textContaining('攻撃中'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('へぇ解説'), findsOneWidget);
    expect(find.textContaining('もっとも軽い元素'), findsOneWidget);
  });
}
