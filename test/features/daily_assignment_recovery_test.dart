import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/home/daily_assignment_gate.dart';

import '../helpers/fake_save_repository.dart';
import '../helpers/release_content.dart';

void main() {
  const date = '2026-07-18';

  testWidgets('removed unanswered assignment is repaired to current content', (
    tester,
  ) async {
    final pair = releaseContentPair(id: 'replacement');
    final repository = FakeSaveRepository()
      ..setLoadedData(
        SaveData(
          onboardingCompleted: true,
          dailyAssignmentDate: date,
          dailyAssignmentQuestionId: 'q_removed',
          dailyAssignmentCardId: 'card_removed',
        ),
      );

    await tester.pumpWidget(
      _app(
        pair: pair,
        repository: repository,
        key: const ValueKey('first-load'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日の1問を始める'), findsOneWidget);
    expect(find.text('今日の問題を準備できませんでした'), findsNothing);
    expect(
      repository.lastSavedData?.hasDailyAssignment(
        date: date,
        questionId: pair.question.id,
        cardId: pair.card.id,
      ),
      isTrue,
    );
    expect(repository.lastSavedData?.totalPlayCount, 0);
    expect(repository.lastSavedData?.streakDays, 0);
  });

  testWidgets('removed answered content remains completed and accessible', (
    tester,
  ) async {
    final pair = releaseContentPair(id: 'current');
    final repository = FakeSaveRepository()
      ..setLoadedData(
        SaveData(
          onboardingCompleted: true,
          totalPlayCount: 1,
          streakDays: 1,
          lastPlayedDate: date,
          lastDailyQuestionDate: date,
          lastDailyQuestionId: 'q_removed',
          lastDailyCardId: 'card_removed',
          dailyAssignmentDate: date,
          dailyAssignmentQuestionId: 'q_removed',
          dailyAssignmentCardId: 'card_removed',
          ownedCardIds: const <String>['card_removed'],
        ),
      );

    await tester.pumpWidget(
      _app(
        pair: pair,
        repository: repository,
        key: const ValueKey('completed-load-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日の1問は完了しました'), findsOneWidget);
    expect(find.textContaining('アプリ更新により本日の問題は表示できません'), findsOneWidget);
    expect(find.text('今日の1問を始める'), findsNothing);
    expect(find.byTooltip('設定'), findsOneWidget);
    expect(repository.saveCallCount, 0);

    await tester.pumpWidget(
      _app(
        pair: pair,
        repository: repository,
        key: const ValueKey('completed-load-2'),
      ),
    );
    await tester.pumpAndSettle();

    final reloaded = await repository.loadOrThrow();
    expect(reloaded.totalPlayCount, 1);
    expect(reloaded.streakDays, 1);
    expect(reloaded.ownedCardIds, const <String>['card_removed']);
    expect(repository.saveCallCount, 0);
  });
}

Widget _app({
  required TestContentPair pair,
  required FakeSaveRepository repository,
  required Key key,
}) => MaterialApp(
  home: DailyAssignmentGate(
    key: key,
    allQuestions: [pair.question],
    allCards: [pair.card],
    saveRepository: repository,
    rewardService: RewardService(),
    dailyQuestionService: DailyQuestionService(
      dateProvider: () => DateTime(2026, 7, 18, 12),
    ),
  ),
);
