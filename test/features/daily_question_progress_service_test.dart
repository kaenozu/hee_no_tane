import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/application/daily_progress_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';

import '../helpers/fake_save_repository.dart';
import '../helpers/release_content.dart';

class _RecordingDailyProgressService extends DailyProgressService {
  int calls = 0;
  int failuresRemaining;
  String? submittedDate;
  Question? submittedQuestion;
  HeeCard? submittedCard;

  _RecordingDailyProgressService({
    required super.saveRepository,
    required super.rewardService,
    this.failuresRemaining = 0,
  });

  @override
  Future<DailyAnswerResult> submitAnswer({
    required String date,
    required Question question,
    HeeCard? card,
  }) async {
    calls += 1;
    submittedDate = date;
    submittedQuestion = question;
    submittedCard = card;
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw const SaveException('simulated failure');
    }
    return DailyAnswerResult(
      saveData: SaveData(
        lastDailyQuestionDate: date,
        lastDailyQuestionId: question.id,
        lastDailyCardId: card?.id ?? question.relatedCardId,
      ),
      cardWasOwnedBeforeAnswer: false,
      alreadyCompleted: false,
    );
  }
}

Widget _buildScreen({
  required Question question,
  required HeeCard card,
  required FakeSaveRepository repository,
  required RewardService rewardService,
  required DailyProgressService dailyProgressService,
  String questionDate = '2026-07-17',
  DateTime Function()? dateProvider,
}) => MaterialApp(
  home: DailyQuestionScreen(
    question: question,
    questionDate: questionDate,
    relatedCard: card,
    saveRepository: repository,
    rewardService: rewardService,
    dailyProgressService: dailyProgressService,
    dateProvider: dateProvider ?? () => DateTime(2026, 7, 17),
  ),
);

void main() {
  testWidgets('answer delegates persistence to DailyProgressService', (
    tester,
  ) async {
    final pair = releaseContentPair(id: 'delegation');
    final repository = FakeSaveRepository();
    final rewardService = RewardService();
    final service = _RecordingDailyProgressService(
      saveRepository: repository,
      rewardService: rewardService,
    );

    await tester.pumpWidget(
      _buildScreen(
        question: pair.question,
        card: pair.card,
        repository: repository,
        rewardService: rewardService,
        dailyProgressService: service,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('answer-choice-0')));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(service.submittedDate, '2026-07-17');
    expect(service.submittedQuestion, same(pair.question));
    expect(service.submittedCard, same(pair.card));
    expect(repository.saveCallCount, 0);
    expect(find.text('新しい知識カードを発見'), findsOneWidget);
  });

  testWidgets('retry delegates to the same service without re-answering', (
    tester,
  ) async {
    final pair = releaseContentPair(id: 'retry');
    final repository = FakeSaveRepository();
    final rewardService = RewardService();
    final service = _RecordingDailyProgressService(
      saveRepository: repository,
      rewardService: rewardService,
      failuresRemaining: 1,
    );

    await tester.pumpWidget(
      _buildScreen(
        question: pair.question,
        card: pair.card,
        repository: repository,
        rewardService: rewardService,
        dailyProgressService: service,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('answer-choice-0')));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(find.text('保存エラー'), findsOneWidget);

    await tester.ensureVisible(find.text('再試行'));
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('新しい知識カードを発見'), findsOneWidget);
  });

  testWidgets('date change rejects answer before calling service', (
    tester,
  ) async {
    final pair = releaseContentPair(id: 'date-change');
    final repository = FakeSaveRepository();
    final rewardService = RewardService();
    final service = _RecordingDailyProgressService(
      saveRepository: repository,
      rewardService: rewardService,
    );

    await tester.pumpWidget(
      _buildScreen(
        question: pair.question,
        card: pair.card,
        repository: repository,
        rewardService: rewardService,
        dailyProgressService: service,
        questionDate: '2026-07-16',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('answer-choice-0')));
    await tester.pumpAndSettle();

    expect(service.calls, 0);
    expect(find.textContaining('日付が変わりました'), findsOneWidget);
  });
}
