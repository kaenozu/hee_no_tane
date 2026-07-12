import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';

import '../helpers/fake_save_repository.dart';

void main() {
  testWidgets('home shows a retryable error instead of empty save data', (
    tester,
  ) async {
    final repository = FakeSaveRepository()
      ..setLoadedData(SaveData(onboardingCompleted: true))
      ..failLoads();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          allQuestions: const [],
          allCards: const [],
          saveRepository: repository,
          rewardService: RewardService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('データを読み込めませんでした'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-load-retry')), findsOneWidget);

    repository.clearLoadFailure();
    await tester.tap(find.byKey(const ValueKey('home-load-retry')));
    await tester.pumpAndSettle();

    expect(find.text('利用可能な問題がありません'), findsOneWidget);
    expect(repository.loadCallCount, 2);
  });
}
