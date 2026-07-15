import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_risk_classifier.dart';

void main() {
  const classifier = ContentRiskClassifier();
  late Map<String, ContentRiskRecord> risksByQuestionId;

  setUpAll(() {
    final risks = classifier.risks(
      questionsJson: File('assets/data/questions.json').readAsStringSync(),
      cardsJson: File('assets/data/cards.json').readAsStringSync(),
    );
    risksByQuestionId = {
      for (final risk in risks) risk.questionId: risk,
    };
  });

  List<String> duplicateIds(String questionId) =>
      risksByQuestionId[questionId]?.duplicateQuestionIds ?? const <String>[];

  test('same answer alone does not make unrelated facts duplicates', () {
    expect(duplicateIds('q_his_003'), isNot(contains('q_food_004')));
    expect(duplicateIds('q_food_004'), isNot(contains('q_his_003')));
  });

  test('all three octopus-heart questions remain duplicate candidates', () {
    const ids = <String>[
      'q_bio_003',
      'q_living_things_006',
      'q_living_things_008',
    ];

    for (final id in ids) {
      expect(
        duplicateIds(id),
        containsAll(ids.where((otherId) => otherId != id)),
        reason: '$id should link to the other octopus-heart questions',
      );
    }
  });

  test('strawberry fruit-structure questions remain duplicate candidates', () {
    expect(duplicateIds('q_food_005'), contains('q_food_011'));
    expect(duplicateIds('q_food_011'), contains('q_food_005'));
  });

  test('sandwich-origin questions remain duplicate candidates', () {
    expect(duplicateIds('q_lang_003'), contains('q_food_006'));
    expect(duplicateIds('q_food_006'), contains('q_lang_003'));
  });
}
