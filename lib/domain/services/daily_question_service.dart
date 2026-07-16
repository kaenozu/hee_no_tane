/// Stable daily question selection.
library;

import 'dart:math';

import 'package:hee_no_tane_app/content_validation/content_release_policy.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

typedef DateProvider = DateTime Function();

DateTime _systemDateProvider() => DateTime.now();

class DailyQuestionService {
  final DateProvider _dateProvider;

  const DailyQuestionService({
    DateProvider? dateProvider,
  }) : _dateProvider = dateProvider ?? _systemDateProvider;

  /// Returns the current date and time supplied by the configured provider.
  DateTime currentDateTime() => _dateProvider();

  /// Returns a local calendar date formatted as YYYY-MM-DD.
  String currentDateSeed([DateTime? dateTime]) {
    final current = dateTime ?? currentDateTime();

    final year = current.year.toString().padLeft(4, '0');
    final month = current.month.toString().padLeft(2, '0');
    final day = current.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  List<Question> generateTodayQuestions(
    List<Question> allQuestions, {
    required List<HeeCard> allCards,
    int rotation = 0,
    int count = 3,
    DateTime? dateTime,
  }) {
    final current = dateTime ?? currentDateTime();

    return generateQuestions(
      currentDateSeed(current),
      allQuestions,
      allCards: allCards,
      rotation: rotation,
      count: count,
    );
  }

  List<Question> generateQuestions(
    String dateSeed,
    List<Question> allQuestions, {
    required List<HeeCard> allCards,
    int rotation = 0,
    int count = 3,
  }) {
    final playable = _releaseApprovedPairs(allQuestions, allCards);
    if (playable.length <= count) return playable;

    final shuffled = List<Question>.from(playable)
      ..shuffle(Random(_stableSeed('hee-question-pool-v2')));
    final date = DateTime.parse(dateSeed);
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    final dayIndex =
        utcDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final start = ((dayIndex + rotation) * count) % shuffled.length;
    return List<Question>.generate(
      count,
      (index) => shuffled[(start + index) % shuffled.length],
    );
  }

  List<Question> _releaseApprovedPairs(
    List<Question> questions,
    List<HeeCard> cards,
  ) {
    final cardsById = {for (final card in cards) card.id: card};

    return questions.where((question) {
      final card = cardsById[question.relatedCardId];

      return card != null &&
          ContentReleasePolicy.isPlayablePair(question, card);
    }).toList();
  }

  int _stableSeed(String value) {
    var hash = 0;

    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    return hash;
  }
}
