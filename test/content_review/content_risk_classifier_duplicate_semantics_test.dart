import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_risk_classifier.dart';

void main() {
  const classifier = ContentRiskClassifier();

  test('similar question wording does not merge different facts', () {
    final risks = classifier.risks(
      questionsJson: _json([
        _question(
          id: 'q_mountain',
          cardId: 'card_mountain',
          category: 'nature_geography',
          question: '日本で最も高い山は何？',
          answer: '富士山',
          explanation:
              '富士山は山梨県と静岡県にまたがる成層火山で、標高3776メートル。'
              '頂上には火口があり、古くから信仰と芸術の対象になった。',
        ),
        _question(
          id: 'q_river',
          cardId: 'card_river',
          category: 'nature_geography',
          question: '日本で最も長い川は何？',
          answer: '信濃川',
          explanation:
              '信濃川は長野県では千曲川と呼ばれ、新潟県を経て日本海へ注ぐ。'
              '流域には盆地や平野が広がり、農業用水にも利用される。',
        ),
      ]),
      cardsJson: _json([
        _card(
          id: 'card_mountain',
          category: 'nature_geography',
          title: '富士山',
          detail: '日本を代表する独立峰で、山梨県と静岡県にまたがる。',
        ),
        _card(
          id: 'card_river',
          category: 'nature_geography',
          title: '信濃川',
          detail: '長野県から新潟県を通り、日本海へ流れる河川。',
        ),
      ]),
    );
    final byId = {for (final risk in risks) risk.questionId: risk};

    expect(
      byId['q_mountain']?.duplicateQuestionIds ?? const <String>[],
      isNot(contains('q_river')),
    );
    expect(
      byId['q_river']?.duplicateQuestionIds ?? const <String>[],
      isNot(contains('q_mountain')),
    );
  });

  test('different question phrasing still links the same fact', () {
    final risks = classifier.risks(
      questionsJson: _json([
        _question(
          id: 'q_sandwich_short',
          cardId: 'card_sandwich_short',
          category: 'language',
          question: 'サンドイッチの名前の由来は？',
          answer: '伯爵の名前',
          explanation: 'サンドイッチ伯爵の名に由来する。',
        ),
        _question(
          id: 'q_sandwich_long',
          cardId: 'card_sandwich_long',
          category: 'food',
          question:
              '軽食の定番「サンドイッチ」の名前の由来となった、'
              '18世紀のイギリスの人物が持つ爵位は何？',
          answer: '伯爵',
          explanation: '第4代サンドイッチ伯爵の名に由来する。',
        ),
      ]),
      cardsJson: _json([
        _card(
          id: 'card_sandwich_short',
          category: 'language',
          title: 'サンドイッチ伯爵',
          detail: '伯爵の名前が料理名になった。',
        ),
        _card(
          id: 'card_sandwich_long',
          category: 'food',
          title: '伯爵のサンドイッチ',
          detail: '第4代伯爵の名前が料理名になった。',
        ),
      ]),
    );
    final byId = {for (final risk in risks) risk.questionId: risk};

    expect(
      byId['q_sandwich_short']!.duplicateQuestionIds,
      contains('q_sandwich_long'),
    );
    expect(
      byId['q_sandwich_long']!.duplicateQuestionIds,
      contains('q_sandwich_short'),
    );
  });
}

String _json(List<Map<String, dynamic>> items) =>
    '${const JsonEncoder.withIndent('  ').convert(items)}\n';

Map<String, dynamic> _question({
  required String id,
  required String cardId,
  required String category,
  required String question,
  required String answer,
  required String explanation,
}) => {
  'id': id,
  'category': category,
  'difficulty': 'normal',
  'question': question,
  'choices': ['別の答え1', answer, '別の答え2', '別の答え3'],
  'answerIndex': 1,
  'explanation': explanation,
  'relatedCardId': cardId,
  'sourceNote': '未確認',
  'verified': false,
};

Map<String, dynamic> _card({
  required String id,
  required String category,
  required String title,
  required String detail,
}) => {
  'id': id,
  'title': title,
  'category': category,
  'shortText': detail,
  'detailText': detail,
  'imageAsset': '',
  'rarity': 'normal',
  'sourceNote': '未確認',
  'imageReview': <String, dynamic>{'status': 'unchecked', 'reviewedAt': ''},
};
