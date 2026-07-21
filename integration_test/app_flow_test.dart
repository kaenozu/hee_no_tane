/// integration_test/app_flow_test.dart
///
/// 統合テスト: オンボーディング→回答→カード獲得→再起動→リセットの一連のフロー。
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/release_content.dart';

final class InMemoryPreferenceStore implements PreferenceStore {
  final Map<String, String> _values;

  InMemoryPreferenceStore({Map<String, String>? initialValues})
    : _values = Map<String, String>.from(
        initialValues ?? const <String, String>{},
      );

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

final class MutableDateProvider {
  DateTime _current;

  MutableDateProvider(this._current);

  DateTime call() => _current;

  void set(DateTime value) {
    _current = value;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('新規利用者: オンボーディングから回答しカードを獲得できる', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);
    final clock = MutableDateProvider(DateTime(2026, 7, 16, 12));
    final dailyQuestionService = DailyQuestionService(dateProvider: clock.call);
    final content = _createReleaseContent();
    final questions = content
        .map((pair) => pair.question)
        .toList(growable: false);
    final cards = content.map((pair) => pair.card).toList(growable: false);

    await _pumpApp(
      tester,
      instanceId: 'new-user',
      repository: repository,
      dailyQuestionService: dailyQuestionService,
      questions: questions,
      cards: cards,
    );

    expect(
      find.byKey(const ValueKey<String>('onboarding-screen')),
      findsOneWidget,
    );

    await _completeOnboarding(tester);

    expect(find.text('今日の1問を始める'), findsOneWidget);

    final answeredQuestion = await _answerToday(tester, questions: questions);

    expect(find.text('新しい知識カードを発見'), findsOneWidget);

    final saved = await repository.loadOrThrow();

    expect(saved.onboardingCompleted, isTrue);
    expect(saved.totalPlayCount, 1);
    expect(saved.streakDays, 1);
    expect(saved.lastPlayedDate, '2026-07-16');
    expect(saved.lastDailyQuestionDate, '2026-07-16');
    expect(saved.lastDailyQuestionId, answeredQuestion.id);
    expect(saved.lastDailyCardId, answeredQuestion.relatedCardId);
    expect(saved.ownedCardIds, contains(answeredQuestion.relatedCardId));
  });

  testWidgets('既存利用者: 再起動後に翌日の問題へ回答できる', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);
    final clock = MutableDateProvider(DateTime(2026, 7, 16, 12));
    final dailyQuestionService = DailyQuestionService(dateProvider: clock.call);
    final content = _createReleaseContent();
    final questions = content
        .map((pair) => pair.question)
        .toList(growable: false);
    final cards = content.map((pair) => pair.card).toList(growable: false);

    await repository.save(SaveData(onboardingCompleted: true));

    await _pumpApp(
      tester,
      instanceId: 'existing-user-day-1',
      repository: repository,
      dailyQuestionService: dailyQuestionService,
      questions: questions,
      cards: cards,
    );

    expect(
      find.byKey(const ValueKey<String>('onboarding-screen')),
      findsNothing,
    );

    final firstQuestion = await _answerToday(tester, questions: questions);

    final firstDaySave = await repository.loadOrThrow();

    expect(firstDaySave.totalPlayCount, 1);
    expect(firstDaySave.streakDays, 1);
    expect(firstDaySave.lastDailyQuestionDate, '2026-07-16');

    clock.set(DateTime(2026, 7, 17, 9));

    await _pumpApp(
      tester,
      instanceId: 'existing-user-day-2',
      repository: repository,
      dailyQuestionService: dailyQuestionService,
      questions: questions,
      cards: cards,
    );

    expect(
      find.byKey(const ValueKey<String>('onboarding-screen')),
      findsNothing,
    );
    expect(find.text('今日の1問を始める'), findsOneWidget);

    final secondQuestion = await _answerToday(tester, questions: questions);

    expect(secondQuestion.id, isNot(firstQuestion.id));

    final secondDaySave = await repository.loadOrThrow();

    expect(secondDaySave.onboardingCompleted, isTrue);
    expect(secondDaySave.totalPlayCount, 2);
    expect(secondDaySave.streakDays, 2);
    expect(secondDaySave.lastPlayedDate, '2026-07-17');
    expect(secondDaySave.lastDailyQuestionDate, '2026-07-17');
    expect(secondDaySave.lastDailyQuestionId, secondQuestion.id);
    expect(
      secondDaySave.ownedCardIds,
      containsAll(<String>[
        firstQuestion.relatedCardId,
        secondQuestion.relatedCardId,
      ]),
    );
  });

  testWidgets('リセットと復旧: 全データ削除後に再度開始して回答できる', (tester) async {
    final store = InMemoryPreferenceStore();
    final repository = SaveRepository(store: store);
    final clock = MutableDateProvider(DateTime(2026, 7, 16, 12));
    final dailyQuestionService = DailyQuestionService(dateProvider: clock.call);
    final content = _createReleaseContent();
    final questions = content
        .map((pair) => pair.question)
        .toList(growable: false);
    final cards = content.map((pair) => pair.card).toList(growable: false);

    await repository.save(SaveData(onboardingCompleted: true));

    await _pumpApp(
      tester,
      instanceId: 'reset-user-before-reset',
      repository: repository,
      dailyQuestionService: dailyQuestionService,
      questions: questions,
      cards: cards,
    );

    await _answerToday(tester, questions: questions);

    await tester.tap(find.text('ホームへ戻る'));
    await tester.pumpAndSettle();

    expect(find.text('今日の1問は完了しました'), findsOneWidget);

    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('settings-reset-data')));
    await tester.pumpAndSettle();

    expect(find.text('すべてのデータを削除します。この操作は取り消せません。'), findsOneWidget);

    await tester.tap(find.text('リセット'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('onboarding-screen')),
      findsOneWidget,
    );

    final resetData = await repository.loadOrThrow();

    expect(resetData.onboardingCompleted, isFalse);
    expect(resetData.totalPlayCount, 0);
    expect(resetData.streakDays, 0);
    expect(resetData.ownedCardIds, isEmpty);
    expect(resetData.lastDailyQuestionDate, isEmpty);
    expect(resetData.lastDailyQuestionId, isEmpty);
    expect(resetData.lastDailyCardId, isEmpty);

    await _completeOnboarding(tester);

    final recoveredQuestion = await _answerToday(
      tester,
      questions: questions,
    );

    expect(find.text('新しい知識カードを発見'), findsOneWidget);

    final recoveredData = await repository.loadOrThrow();

    expect(recoveredData.onboardingCompleted, isTrue);
    expect(recoveredData.totalPlayCount, 1);
    expect(recoveredData.streakDays, 1);
    expect(recoveredData.lastDailyQuestionDate, '2026-07-16');
    expect(recoveredData.lastDailyQuestionId, recoveredQuestion.id);
    expect(
      recoveredData.ownedCardIds,
      contains(recoveredQuestion.relatedCardId),
    );
  });
}

List<TestContentPair> _createReleaseContent() {
  return List<TestContentPair>.generate(
    6,
    (index) => releaseContentPair(
      id: 'integration_$index',
      category: 'nature_geography',
      questionText: 'integration test 問題 $index',
      choices: <String>[
        '正解 $index',
        '選択肢B $index',
        '選択肢C $index',
        '選択肢D $index',
      ],
      answerIndex: 0,
      explanation: 'integration test 解説 $index',
      title: 'integration test カード $index',
      shortText: 'integration test 短文 $index',
      detailText: 'integration test 詳細 $index',
    ),
    growable: false,
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String instanceId,
  required SaveRepository repository,
  required DailyQuestionService dailyQuestionService,
  required List<Question> questions,
  required List<HeeCard> cards,
}) async {
  final saveData = await repository.loadOrThrow();

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.pumpWidget(
    HeeNoTaneApp(
      key: ValueKey<String>(instanceId),
      allQuestions: questions,
      allCards: cards,
      saveData: saveData,
      saveRepository: repository,
      rewardService: RewardService(),
      dailyQuestionService: dailyQuestionService,
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _completeOnboarding(WidgetTester tester) async {
  for (var index = 0; index < 2; index++) {
    await tester.tap(find.byKey(const ValueKey<String>('onboarding-next')));
    await tester.pumpAndSettle();
  }

  await tester.tap(find.byKey(const ValueKey<String>('onboarding-start')));
  await tester.pumpAndSettle();

  expect(find.text('今日の1問を始める'), findsOneWidget);
}

Future<Question> _answerToday(
  WidgetTester tester, {
  required List<Question> questions,
}) async {
  await tester.tap(find.text('今日の1問を始める'));
  await tester.pumpAndSettle();

  final displayedQuestions = questions
      .where((question) => find.text(question.question).evaluate().isNotEmpty)
      .toList(growable: false);
  expect(displayedQuestions, hasLength(1));

  final question = displayedQuestions.single;
  final answerChoice = find.byKey(
    ValueKey<String>('answer-choice-${question.answerIndex}'),
  );

  expect(answerChoice, findsOneWidget);

  await tester.ensureVisible(answerChoice);
  await tester.tap(answerChoice);
  await tester.pumpAndSettle();

  expect(find.text('解説'), findsOneWidget);
  expect(find.text(question.explanation), findsOneWidget);
  expect(find.text('新しい知識カードを発見'), findsOneWidget);

  return question;
}
