import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_review_workflow.dart';
import 'package:hee_no_tane_app/content_review/content_risk_classifier.dart';

void main() {
  const classifier = ContentRiskClassifier();
  const workflow = ContentReviewWorkflow();

  test('enhanced review CSV adds immutable image asset and imageFit', () {
    final questions = _json([
      _question(
        id: 'q_1',
        cardId: 'card_1',
        category: 'science',
        question: '空気の主成分は？',
        answer: '窒素',
        explanation: '空気の約78%は窒素。',
      ),
    ]);
    final cards = _json([
      _card(
        id: 'card_1',
        category: 'science',
        title: '大気',
        detail: '空気の主成分を説明する。',
        imageAsset: 'assets/images/cards/card_1.png',
      ),
    ]);
    final enhanced = classifier.enhanceReviewCsv(
      baseCsv: workflow.exportCsv(questionsJson: questions, cardsJson: cards),
      cardsJson: cards,
    );

    expect(
      enhanced.split('\r\n').first,
      enhancedContentReviewColumns.join(','),
    );
    expect(enhanced, contains('assets/images/cards/card_1.png,unchecked'));
    final stripped = classifier.stripReviewCsv(
      reviewCsv: enhanced,
      cardsJson: cards,
    );
    expect(stripped.split('\r\n').first, contentReviewColumns.join(','));
    expect(
      workflow
          .planImport(csv: stripped, questionsJson: questions, cardsJson: cards)
          .hasChanges,
      isFalse,
    );
  });

  test('invalid image fit and changed image asset are rejected', () {
    final cards = _json([
      _card(
        id: 'card_1',
        category: 'science',
        title: '大気',
        detail: '空気の主成分を説明する。',
        imageAsset: 'assets/images/cards/card_1.png',
      ),
    ]);
    final header = enhancedContentReviewColumns.join(',');
    final row = [
      'q_1',
      'card_1',
      'science',
      '問題',
      '答え',
      '解説',
      'assets/images/cards/card_1.png',
      'unsupported',
      '',
      '',
      '',
      '',
      'unverified',
      'pending',
      '',
    ].join(',');
    expect(
      () => classifier.stripReviewCsv(
        reviewCsv: '$header\r\n$row\r\n',
        cardsJson: cards,
      ),
      throwsA(isA<ContentReviewException>()),
    );
  });

  test('current facts are not current roles without office language', () {
    final risks = classifier.risks(
      questionsJson: _json([
        _question(
          id: 'q_1',
          cardId: 'card_1',
          category: 'nature_geography',
          question: 'エッフェル塔は現在どこにある？',
          answer: 'パリ',
          explanation: '現在もパリにある。',
        ),
      ]),
      cardsJson: _json([
        _card(
          id: 'card_1',
          category: 'nature_geography',
          title: 'エッフェル塔',
          detail: '現在の所在地を説明する。',
        ),
      ]),
    );
    expect(risks.single.reasons, contains('current_fact'));
    expect(risks.single.reasons, isNot(contains('current_role')));
  });

  test('current roles require time and office language', () {
    final risks = classifier.risks(
      questionsJson: _json([
        _question(
          id: 'q_1',
          cardId: 'card_1',
          category: 'history',
          question: '現在の首相は誰？',
          answer: '人物名',
          explanation: '現職の首相を答える。',
        ),
      ]),
      cardsJson: _json([
        _card(
          id: 'card_1',
          category: 'history',
          title: '首相',
          detail: '現在の首相を説明する。',
        ),
      ]),
    );
    expect(risks.single.reasons, contains('current_role'));
    expect(risks.single.reasons, isNot(contains('current_fact')));
  });

  test('animal anatomy is separate from human health', () {
    final risks = classifier.risks(
      questionsJson: _json([
        _question(
          id: 'q_1',
          cardId: 'card_1',
          category: 'living_things',
          question: 'タコの心臓はいくつある？',
          answer: '3つ',
          explanation: 'タコには心臓が3つある。',
        ),
      ]),
      cardsJson: _json([
        _card(
          id: 'card_1',
          category: 'living_things',
          title: 'タコの心臓',
          detail: 'えら用と全身用の心臓がある。',
        ),
      ]),
    );
    expect(risks.single.reasons, contains('biological_anatomy'));
    expect(risks.single.reasons, isNot(contains('human_health')));
  });

  test('currency history is separate from financial advice', () {
    final risks = classifier.risks(
      questionsJson: _json([
        _question(
          id: 'q_1',
          cardId: 'card_1',
          category: 'history',
          question: '最初に肖像が使われた紙幣は？',
          answer: '旧紙幣',
          explanation: '1885年に発行された紙幣を扱う。',
        ),
      ]),
      cardsJson: _json([
        _card(
          id: 'card_1',
          category: 'history',
          title: '紙幣の歴史',
          detail: '紙幣の発行年と肖像を説明する。',
        ),
      ]),
    );
    expect(risks.single.reasons, contains('currency_history'));
    expect(risks.single.reasons, isNot(contains('financial_advice')));
  });

  test('duplicate facts link the other question IDs', () {
    final risks = classifier.risks(
      questionsJson: _json([
        _question(
          id: 'q_octopus_1',
          cardId: 'card_octopus_1',
          category: 'living_things',
          question: 'タコの心臓はいくつある？',
          answer: '3つ',
          explanation: 'タコには心臓が3つある。',
        ),
        _question(
          id: 'q_octopus_2',
          cardId: 'card_octopus_2',
          category: 'living_things',
          question: '海のタコの心臓は一般にいくつある？',
          answer: '3つ',
          explanation: '二つはえらへ、一つは全身へ血液を送る。',
        ),
        _question(
          id: 'q_sandwich_1',
          cardId: 'card_sandwich_1',
          category: 'language',
          question: 'サンドイッチの名前の由来は？',
          answer: '伯爵の名前',
          explanation: 'サンドイッチ伯爵の名に由来する。',
        ),
        _question(
          id: 'q_sandwich_2',
          cardId: 'card_sandwich_2',
          category: 'food',
          question: '軽食の定番「サンドイッチ」の名前の由来となった、18世紀のイギリスの人物が持つ爵位は何？',
          answer: '伯爵',
          explanation: '第4代サンドイッチ伯爵の名に由来する。',
        ),
      ]),
      cardsJson: _json([
        _card(
          id: 'card_octopus_1',
          category: 'living_things',
          title: 'タコの心臓',
          detail: 'タコには三つの心臓がある。',
        ),
        _card(
          id: 'card_octopus_2',
          category: 'living_things',
          title: 'タコは三つの心臓',
          detail: 'えら用二つと全身用一つがある。',
        ),
        _card(
          id: 'card_sandwich_1',
          category: 'language',
          title: 'サンドイッチ伯爵',
          detail: '伯爵の名が料理名になった。',
        ),
        _card(
          id: 'card_sandwich_2',
          category: 'food',
          title: '伯爵のサンドイッチ',
          detail: '第4代伯爵の名に由来する。',
        ),
      ]),
    );
    final byId = {for (final item in risks) item.questionId: item};
    expect(byId['q_octopus_1']!.reasons, contains('duplicate_fact'));
    expect(byId['q_octopus_1']!.duplicateQuestionIds, contains('q_octopus_2'));
    expect(byId['q_sandwich_1']!.reasons, contains('duplicate_fact'));
    expect(
      byId['q_sandwich_1']!.duplicateQuestionIds,
      contains('q_sandwich_2'),
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
  String imageAsset = '',
}) => {
  'id': id,
  'title': title,
  'category': category,
  'shortText': detail,
  'detailText': detail,
  'imageAsset': imageAsset,
  'rarity': 'normal',
  'sourceNote': '未確認',
  'imageReview': <String, dynamic>{'status': 'unchecked', 'reviewedAt': ''},
};
