import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

final class _MemoryPreferenceStore implements PreferenceStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  test('a completed prior day does not overwrite the next daily assignment', () async {
    final repository = SaveRepository(store: _MemoryPreferenceStore());
    await repository.save(
      SaveData(
        totalPlayCount: 1,
        streakDays: 1,
        lastPlayedDate: '2026-07-16',
        lastDailyQuestionDate: '2026-07-16',
        lastDailyQuestionId: 'q_day_1',
        lastDailyCardId: 'card_day_1',
        dailyAssignmentDate: '2026-07-16',
        dailyAssignmentQuestionId: 'q_day_1',
        dailyAssignmentCardId: 'card_day_1',
        ownedCardIds: const <String>['card_day_1'],
        onboardingCompleted: true,
      ),
    );

    final updated = await repository.update(
      (current) => current.copyWith(
        dailyAssignmentDate: '2026-07-17',
        dailyAssignmentQuestionId: 'q_day_2',
        dailyAssignmentCardId: 'card_day_2',
      ),
    );

    expect(updated.dailyAssignmentDate, '2026-07-17');
    expect(updated.dailyAssignmentQuestionId, 'q_day_2');
    expect(updated.dailyAssignmentCardId, 'card_day_2');
    expect(updated.lastDailyQuestionDate, '2026-07-16');
    expect(updated.lastDailyQuestionId, 'q_day_1');
    expect(updated.lastDailyCardId, 'card_day_1');
    expect(updated.totalPlayCount, 1);
    expect(updated.streakDays, 1);
  });
}
