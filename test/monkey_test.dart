import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

import 'helpers/fake_save_repository.dart';

void main() {
  testWidgets('monkey test: random taps and drags do not crash the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryPreferenceStore();

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: _questions(),
        allCards: _cards(),
        saveData: SaveData(),
        saveRepository: SaveRepository(store: store),
        rewardService: RewardService(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final random = Random(20260709);
    const actions = 120;

    for (var step = 0; step < actions; step++) {
      final action = random.nextInt(10);
      if (action < 7) {
        await tester.tapAt(_randomPoint(random, tester.view.physicalSize));
      } else if (action < 9) {
        await tester.dragFrom(
          _randomPoint(random, tester.view.physicalSize),
          Offset(
            random.nextDouble() * 220 - 110,
            random.nextDouble() * 360 - 180,
          ),
        );
      } else {
        await tester.binding.handlePopRoute();
      }

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 120));

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'Monkey action $step crashed');
    }
  });
}

Offset _randomPoint(Random random, Size size) {
  return Offset(
    12 + random.nextDouble() * (size.width - 24),
    12 + random.nextDouble() * (size.height - 24),
  );
}

List<Question> _questions() {
  return List.generate(
    30,
    (index) => Question(
      id: 'q$index',
      category: 'test',
      difficulty: 'easy',
      question: 'モンキー問題$index',
      choices: const ['正解', 'B', 'C', 'D'],
      answerIndex: 0,
      explanation: 'モンキー解説$index',
      relatedCardId: 'card$index',
      sourceNote: 'test',
      verified: true,
    ),
  );
}

List<HeeCard> _cards() {
  return List.generate(
    30,
    (index) => HeeCard(
      id: 'card$index',
      title: 'モンキーカード$index',
      category: '雑学',
      shortText: '短い説明$index',
      detailText: '詳しい説明$index',
      imageAsset: '',
      rarity: 'normal',
      sourceNote: 'test',
    ),
  );
}
