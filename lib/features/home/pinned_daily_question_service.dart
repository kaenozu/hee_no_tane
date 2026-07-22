/// lib/features/home/pinned_daily_question_service.dart
///
/// 確定済みの本日問題を返し、それ以外は既存DailyQuestionServiceへ委譲する。
/// 日次問題の固定ロジックを画面状態管理から分離するために存在する。
///
/// 関連:
///   - daily_assignment_gate.dart
///   - ../../domain/services/daily_question_service.dart
library;

import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';

final class PinnedDailyQuestionService extends DailyQuestionService {
  final DailyQuestionService delegate;
  final String assignedDate;
  final Question assignedQuestion;

  const PinnedDailyQuestionService({
    required this.delegate,
    required this.assignedDate,
    required this.assignedQuestion,
  });

  @override
  DateTime currentDateTime() => delegate.currentDateTime();

  @override
  String currentDateSeed([DateTime? dateTime]) =>
      delegate.currentDateSeed(dateTime);

  @override
  List<Question> generateTodayQuestions(
    List<Question> allQuestions, {
    required List<HeeCard> allCards,
    int rotation = 0,
    int count = 3,
    DateTime? dateTime,
  }) {
    final date = delegate.currentDateSeed(
      dateTime ?? delegate.currentDateTime(),
    );
    if (date == assignedDate && count > 0) {
      return <Question>[assignedQuestion];
    }
    return delegate.generateTodayQuestions(
      allQuestions,
      allCards: allCards,
      rotation: rotation,
      count: count,
      dateTime: dateTime,
    );
  }

  @override
  List<Question> generateQuestions(
    String dateSeed,
    List<Question> allQuestions, {
    required List<HeeCard> allCards,
    int rotation = 0,
    int count = 3,
  }) {
    if (dateSeed == assignedDate && count > 0) {
      return <Question>[assignedQuestion];
    }
    return delegate.generateQuestions(
      dateSeed,
      allQuestions,
      allCards: allCards,
      rotation: rotation,
      count: count,
    );
  }
}
