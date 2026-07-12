import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

import '../helpers/fake_save_repository.dart';

void main() {
  group('SaveRepository.update', () {
    late FakeSaveRepository repository;

    setUp(() {
      repository = FakeSaveRepository();
      repository.setLoadedData(SaveData());
    });

    test('U1. concurrent updates run FIFO and preserve both changes', () async {
      repository.holdNextSave();

      final first = repository.update(
        (current) =>
            current.copyWith(totalBrowseCount: current.totalBrowseCount + 1),
      );
      await pumpEventQueue();
      expect(repository.loadCallCount, 1);
      expect(repository.saveCallCount, 1);

      final second = repository.update(
        (current) =>
            current.copyWith(ownedCardIds: [...current.ownedCardIds, 'card_a']),
      );
      await pumpEventQueue();

      expect(repository.loadCallCount, 1);
      repository.completeSave();

      await first;
      final result = await second;
      expect(result.totalBrowseCount, 1);
      expect(result.ownedCardIds, ['card_a']);
      expect(repository.loadCallCount, 2);
      expect(repository.saveCallCount, 2);
    });

    test('U2. card view and daily answer updates both survive', () async {
      const today = '2026-07-12';
      final rewardService = RewardService();
      final card = HeeCard(
        id: 'card_daily',
        title: '競合テストカード',
        category: 'science',
        shortText: '短文',
        detailText: '詳細',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: '出典',
      );
      repository.setLoadedData(
        SaveData(settings: const GameSettings(themeMode: ThemeMode.dark)),
      );
      repository.holdNextSave();

      final cardView = repository.update(
        (current) => rewardService.updatePlayStats(current, today),
      );
      await pumpEventQueue();

      final dailyAnswer = repository.update((current) {
        if (current.lastDailyQuestionDate == today) return current;
        var updated = rewardService.updatePlayStats(current, today);
        updated = updated.copyWith(lastDailyQuestionDate: today);
        return rewardService.applyReward(updated, card);
      });

      repository.completeSave();
      await cardView;
      final result = await dailyAnswer;

      expect(result.totalBrowseCount, 2);
      expect(result.lastDailyQuestionDate, today);
      expect(result.ownedCardIds, [card.id]);
      expect(result.settings.themeMode, ThemeMode.dark);
    });

    test('U3. load failure skips save', () async {
      repository.failLoads();

      await expectLater(
        repository.update((current) => current),
        throwsA(isA<SaveLoadException>()),
      );
      expect(repository.saveCallCount, 0);
    });

    test('U4. updater failure skips save', () async {
      await expectLater(
        repository.update((_) => throw StateError('updater failed')),
        throwsA(isA<StateError>()),
      );
      expect(repository.saveCallCount, 0);
    });

    test('U5. save failure does not block a later update', () async {
      repository.holdNextSave();
      final failedUpdate = repository.update(
        (current) => current.copyWith(totalBrowseCount: 1),
      );
      await pumpEventQueue();

      final failureExpectation = expectLater(
        failedUpdate,
        throwsA(isA<SaveException>()),
      );
      repository.failSave();
      await failureExpectation;

      final result = await repository.update(
        (current) => current.copyWith(ownedCardIds: ['card_after']),
      );
      expect(result.totalBrowseCount, 0);
      expect(result.ownedCardIds, ['card_after']);
      expect(repository.saveCallCount, 2);
    });
  });
}
