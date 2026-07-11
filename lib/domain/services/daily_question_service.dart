/// lib/domain/services/daily_question_service.dart
///
/// 日替わり問題を生成するサービス。
library;
/// 日付 + 回転数 をシードにした安定シャッフルで、毎日異なる問題セットを提供する。
///
/// 関連:
///   - ../models/question.dart
///   - ../../features/home/home_screen.dart

import 'dart:math';
import 'package:hee_no_tane_app/domain/models/question.dart';

class DailyQuestionService {
  List<Question> generateQuestions(
    String dateSeed,
    List<Question> allQuestions, {
    int rotation = 0,
    int count = 3,
  }) {
    final playable = allQuestions.where((q) => q.verified).toList();
    if (playable.length <= count) return playable;

    final shuffled = List<Question>.from(playable)
      ..shuffle(Random(_stableSeed('hee-question-pool-v1')));
    final date = DateTime.parse(dateSeed);
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    final dayIndex =
        utcDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final start = ((dayIndex + rotation) * count) % shuffled.length;

    return List.generate(
      count,
      (index) => shuffled[(start + index) % shuffled.length],
    );
  }

  int _stableSeed(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
