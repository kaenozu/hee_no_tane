import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('reset data clears all saved data and notifies the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = SaveRepository();
    var resetNotified = false;
    await repository.save(
      SaveData(
        onboardingCompleted: true,
        ownedCardIds: const ['card-a'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          rewardService: RewardService(),
          onDataReset: () => resetNotified = true,
        ),
      ),
    );

    await tester.tap(find.text('データリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リセット'));
    await tester.pumpAndSettle();

    expect((await repository.load()).ownedCardIds, isEmpty);
    expect(resetNotified, isTrue);
  });

  testWidgets('reset failure keeps the screen open and shows an error', (
    tester,
  ) async {
    final repository = _ResetFailingRepository();
    var resetNotified = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          rewardService: RewardService(),
          onDataReset: () => resetNotified = true,
        ),
      ),
    );

    await tester.tap(find.text('データリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リセット'));
    await tester.pumpAndSettle();

    expect(find.text('初期化できませんでした'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
    expect(resetNotified, isFalse);
  });

  testWidgets('privacy policy is available inside the app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: SaveRepository(),
          rewardService: RewardService(),
          onDataReset: () {},
        ),
      ),
    );

    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pumpAndSettle();

    expect(find.text('保存する情報'), findsOneWidget);
    expect(find.text('外部への送信'), findsOneWidget);
    expect(find.textContaining('利用状況の分析'), findsOneWidget);
  });
}

class _ResetFailingRepository extends SaveRepository {
  @override
  Future<void> reset() async {
    throw const SaveException('初期化できませんでした');
  }
}
