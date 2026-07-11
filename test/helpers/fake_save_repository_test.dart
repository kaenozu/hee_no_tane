/// test/helpers/fake_save_repository_test.dart
///
/// FakeSaveRepository の永続化動作を直接検証する。
library;

///
/// 関連:
///   - fake_save_repository.dart
///   - ../../lib/domain/models/save_data.dart
///   - ../../lib/data/repositories/save_repository.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'fake_save_repository.dart';

void main() {
  group('G. FakeSaveRepository persistence', () {
    late FakeSaveRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeSaveRepository();
    });

    test('G1. successful save updates load data', () async {
      final originalData = SaveData(
        lastDailyQuestionDate: '2026-07-10',
        ownedCardIds: ['card_a'],
        totalBrowseCount: 5,
        streakDays: 3,
      );
      fakeRepo.setLoadedData(originalData);

      final newData = SaveData(
        lastDailyQuestionDate: '2026-07-11',
        ownedCardIds: ['card_a', 'card_b'],
        totalBrowseCount: 6,
        streakDays: 4,
      );

      fakeRepo.holdNextSave();
      final saveFuture = fakeRepo.save(newData);
      fakeRepo.completeSave();
      await saveFuture;

      final loaded = await fakeRepo.load();
      expect(loaded.lastDailyQuestionDate, '2026-07-11');
      expect(loaded.ownedCardIds, ['card_a', 'card_b']);
      expect(loaded.totalBrowseCount, 6);
      expect(loaded.streakDays, 4);
    });

    test('G2. failed save keeps original load data', () async {
      final originalData = SaveData(
        lastDailyQuestionDate: '2026-07-10',
        ownedCardIds: ['card_a'],
        totalBrowseCount: 5,
        streakDays: 3,
      );
      fakeRepo.setLoadedData(originalData);

      final newData = SaveData(
        lastDailyQuestionDate: '2026-07-11',
        ownedCardIds: ['card_a', 'card_b'],
        totalBrowseCount: 6,
        streakDays: 4,
      );

      fakeRepo.holdNextSave();
      final saveFuture = fakeRepo.save(newData);
      fakeRepo.failSave();

      await expectLater(saveFuture, throwsA(isA<SaveException>()));

      final loaded = await fakeRepo.load();
      expect(loaded.lastDailyQuestionDate, '2026-07-10');
      expect(loaded.ownedCardIds, ['card_a']);
      expect(loaded.totalBrowseCount, 5);
      expect(loaded.streakDays, 3);
    });
  });
}
