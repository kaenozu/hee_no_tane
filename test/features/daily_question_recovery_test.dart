import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';

import '../helpers/fake_save_repository.dart';
import '../helpers/release_content.dart';

Future<void> _pushScreen(
  WidgetTester tester, {
  required FakeSaveRepository repository,
  required DateTime Function() dateProvider,
  required String questionDate,
}) async {
  final pair = releaseContentPair(id: 'recovery');
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => DailyQuestionScreen(
                        question: pair.question,
                        questionDate: questionDate,
                        relatedCard: pair.card,
                        saveRepository: repository,
                        rewardService: RewardService(),
                        dateProvider: dateProvider,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('failed save can be discarded and returned home', (tester) async {
    final repository = FakeSaveRepository()..holdNextSave();
    await _pushScreen(
      tester,
      repository: repository,
      questionDate: '2026-07-16',
      dateProvider: () => DateTime(2026, 7, 16, 12),
    );

    await tester.tap(find.text('A'));
    await tester.pump();
    repository.failSave();
    await tester.pumpAndSettle();

    expect(find.text('保存エラー'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    expect(find.text('破棄してホームへ戻る'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    final discardButton = find.text('破棄してホームへ戻る');
    await tester.ensureVisible(discardButton);
    await tester.tap(discardButton);
    await tester.pumpAndSettle();
    expect(find.text('回答を破棄しますか？'), findsOneWidget);

    await tester.tap(find.text('破棄して戻る'));
    await tester.pumpAndSettle();

    expect(find.byType(DailyQuestionScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('stale question is never saved after the calendar day changes', (
    tester,
  ) async {
    final repository = FakeSaveRepository();
    await _pushScreen(
      tester,
      repository: repository,
      questionDate: '2026-07-16',
      dateProvider: () => DateTime(2026, 7, 17, 0, 1),
    );

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    expect(repository.saveCallCount, 0);
    expect(find.textContaining('日付が変わりました'), findsOneWidget);
    expect(find.text('再試行'), findsNothing);
    expect(find.text('破棄してホームへ戻る'), findsOneWidget);
  });
}
