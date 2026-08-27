import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';

import '../helpers/fake_save_repository.dart';
import '../helpers/release_content.dart';

class _MutableClock {
  DateTime value;

  _MutableClock(this.value);

  DateTime call() => value;
}

void main() {
  testWidgets('resuming after midnight replaces the stale daily question', (
    tester,
  ) async {
    final pairs = [
      releaseContentPair(id: 'resume_0'),
      releaseContentPair(id: 'resume_1'),
      releaseContentPair(id: 'resume_2'),
    ];
    final questions = pairs.map((pair) => pair.question).toList();
    final cards = pairs.map((pair) => pair.card).toList();
    final clock = _MutableClock(DateTime(2026, 7, 16, 12));
    final service = DailyQuestionService(dateProvider: clock.call);
    final repository = FakeSaveRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          allQuestions: questions,
          allCards: cards,
          saveRepository: repository,
          rewardService: RewardService(),
          dailyQuestionService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = service
        .generateTodayQuestions(
          questions,
          allCards: cards,
          count: 1,
          dateTime: clock.value,
        )
        .single;
    await tester.tap(find.text('今日の1問を始める'));
    await tester.pumpAndSettle();
    expect(find.text(first.question), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DailyQuestionScreen), findsNothing);

    clock.value = DateTime(2026, 7, 17, 8);
    final second = service
        .generateTodayQuestions(
          questions,
          allCards: cards,
          count: 1,
          dateTime: clock.value,
        )
        .single;
    expect(second.id, isNot(first.id));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    await tester.tap(find.text('今日の1問を始める'));
    await tester.pumpAndSettle();
    expect(find.text(second.question), findsOneWidget);
    expect(find.text(first.question), findsNothing);
  });

  testWidgets(
    'home keeps the collection action above the system navigation inset',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 48)),
          child: MaterialApp(
            home: HomeScreen(
              allQuestions: [releaseContentPair(id: 'inset_0').question],
              allCards: [releaseContentPair(id: 'inset_0').card],
              saveRepository: FakeSaveRepository(),
              rewardService: RewardService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea).first);
      expect(safeArea.bottom, isFalse);
      final bottomPadding = tester.widget<SliverPadding>(
        find.byType(SliverPadding).last,
      );
      expect(bottomPadding.padding, const EdgeInsets.only(bottom: 72));
    },
  );
}
