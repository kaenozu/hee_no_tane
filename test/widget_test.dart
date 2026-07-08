import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: const [],
        allCards: const [],
        allEnemies: const [],
        saveData: SaveData(),
        saveRepository: SaveRepository(),
        battleService: BattleService(),
        rewardService: RewardService(),
      ),
    );
    for (var i = 0; i < 20 && find.text('へぇダンジョン').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('へぇダンジョン'), findsOneWidget);
  });
}
