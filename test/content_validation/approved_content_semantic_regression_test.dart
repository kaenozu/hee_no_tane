import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, Map<String, dynamic>> pairsByQuestionId;

  setUpAll(() {
    final bundle = Map<String, dynamic>.from(
      jsonDecode(File('assets/data/content_bundle.json').readAsStringSync())
          as Map,
    );
    final entries = bundle['entries']! as List<dynamic>;
    pairsByQuestionId = <String, Map<String, dynamic>>{
      for (final value in entries)
        Map<String, dynamic>.from(
              (value as Map)['question'] as Map,
            )['id']
            as String: Map<String, dynamic>.from(value),
    };
  });

  test('honey question, answers, explanation, and card share one fact', () {
    final pair = pairsByQuestionId['q_food_008']!;
    final question = _question(pair);
    final card = _card(pair);

    expect(question['choices'], <String>[
      '一般に上昇する',
      '必ず低下する',
      'まったく変化しない',
      '糖質を含まないため影響しない',
    ]);
    expect(question['answerIndex'], 0);
    expect(card['title'], '蜂蜜と血糖値');
  });

  test('Statue of Liberty pair consistently identifies France', () {
    final pair = pairsByQuestionId['q_history_011']!;
    final question = _question(pair);
    final card = _card(pair);

    expect(question['choices'], <String>['フランス', 'イギリス', 'スペイン', 'カナダ']);
    expect(question['answerIndex'], 0);
    expect(card['title'], contains('自由の女神'));
  });

  test('如し pair consistently explains comparison', () {
    final pair = pairsByQuestionId['q_language_007']!;
    final question = _question(pair);
    final card = _card(pair);

    expect(question['choices'][0], contains('～のようだ'));
    expect(question['answerIndex'], 0);
    expect(card['title'], contains('如し'));
  });

  test('Awaji population question uses numeric answer choices', () {
    final pair = pairsByQuestionId['q_nature_geography_013']!;
    final question = _question(pair);
    final card = _card(pair);

    expect(question['choices'], <String>['約3.2万人', '約7.5万人', '約12.7万人', '約25.4万人']);
    expect(question['answerIndex'], 2);
    expect(card['shortText'], contains('約12.7万人'));
  });

  test('tsunami question and card both explain shallow-water amplification', () {
    final pair = pairsByQuestionId['q_nature_geography_015']!;
    final question = _question(pair);
    final card = _card(pair);

    expect(question['choices'][0], contains('水深が浅くなる'));
    expect(question['answerIndex'], 0);
    expect(card['title'], contains('高くなる'));
  });

  test('quicklime pair consistently describes the exothermic reaction', () {
    final pair = pairsByQuestionId['q_science_011']!;
    final question = _question(pair);
    final card = _card(pair);

    expect(question['choices'][0], contains('消石灰'));
    expect(question['choices'][0], contains('熱'));
    expect(question['answerIndex'], 0);
    expect(card['title'], contains('生石灰'));
  });
}

Map<String, dynamic> _question(Map<String, dynamic> pair) =>
    Map<String, dynamic>.from(pair['question']! as Map);

Map<String, dynamic> _card(Map<String, dynamic> pair) =>
    Map<String, dynamic>.from(pair['card']! as Map);
