import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_review_workflow.dart';

void main() {
  const workflow = ContentReviewWorkflow();

  test('export pairs questions with cards and quotes CSV safely', () {
    final questions = _questionsJson(
      question: '空気で、最も多い成分は？',
      explanation: '答えは窒素。\n約78%です。',
    );

    final csv = workflow.exportCsv(
      questionsJson: questions,
      cardsJson: _cardsJson(),
    );

    expect(csv.split('\r\n').first, contentReviewColumns.join(','));
    expect(csv, contains('q_001,card_001,science'));
    expect(csv, contains('"空気で、最も多い成分は？"'));
    expect(csv, contains('窒素'));
    expect(csv, contains('"答えは窒素。\n約78%です。"'));
  });

  test('an unchanged exported legacy CSV produces no JSON diff', () {
    final questions = _questionsJson();
    final cards = _cardsJson();
    final csv = workflow.exportCsv(
      questionsJson: questions,
      cardsJson: cards,
    );

    final plan = workflow.planImport(
      csv: csv,
      questionsJson: questions,
      cardsJson: cards,
    );

    expect(plan.hasChanges, isFalse);
  });

  test('approved source is applied identically to question and card', () {
    final plan = workflow.planImport(
      csv: _reviewCsv(
        sourceTitle: '大気の組成',
        sourcePublisher: '気象庁',
        sourceUrl: 'https://www.jma.go.jp/example',
        verifiedAt: '2026-07-12',
        verificationLevel: 'primary',
        reviewStatus: 'approved',
      ),
      questionsJson: _questionsJson(),
      cardsJson: _cardsJson(),
    );

    expect(plan.changes, hasLength(1));
    final question = (jsonDecode(plan.questionsJson) as List).single as Map;
    final card = (jsonDecode(plan.cardsJson) as List).single as Map;
    expect(question['id'], 'q_001');
    expect(card['id'], 'card_001');
    expect(question['source'], card['source']);
    expect((question['source'] as Map)['reviewStatus'], 'approved');
  });

  test('approved source without required evidence is rejected', () {
    expect(
      () => workflow.planImport(
        csv: _reviewCsv(
          sourceTitle: '資料',
          sourcePublisher: '発行元',
          verifiedAt: '2026-07-12',
          verificationLevel: 'primary',
          reviewStatus: 'approved',
        ),
        questionsJson: _questionsJson(),
        cardsJson: _cardsJson(),
      ),
      throwsA(isA<ContentReviewException>()),
    );
  });

  test('changed IDs and immutable content are rejected', () {
    expect(
      () => workflow.planImport(
        csv: _reviewCsv(questionId: 'q_changed'),
        questionsJson: _questionsJson(),
        cardsJson: _cardsJson(),
      ),
      throwsA(isA<ContentReviewException>()),
    );
    expect(
      () => workflow.planImport(
        csv: _reviewCsv(question: '書き換えた問題'),
        questionsJson: _questionsJson(),
        cardsJson: _cardsJson(),
      ),
      throwsA(isA<ContentReviewException>()),
    );
  });

  test('invalid CSV never changes either JSON file', () async {
    final directory = await Directory.systemTemp.createTemp('content-review-');
    addTearDown(() => directory.delete(recursive: true));
    final questionsFile = File('${directory.path}/questions.json');
    final cardsFile = File('${directory.path}/cards.json');
    final originalQuestions = _questionsJson();
    final originalCards = _cardsJson();
    await questionsFile.writeAsString(originalQuestions);
    await cardsFile.writeAsString(originalCards);

    await expectLater(
      workflow.applyCsvToFiles(
        csv: _reviewCsv(questionId: 'q_changed'),
        questionsPath: questionsFile.path,
        cardsPath: cardsFile.path,
        write: true,
      ),
      throwsA(isA<ContentReviewException>()),
    );

    expect(await questionsFile.readAsString(), originalQuestions);
    expect(await cardsFile.readAsString(), originalCards);
  });

  test('dry-run reports changes without writing files', () async {
    final directory = await Directory.systemTemp.createTemp('content-review-');
    addTearDown(() => directory.delete(recursive: true));
    final questionsFile = File('${directory.path}/questions.json');
    final cardsFile = File('${directory.path}/cards.json');
    final originalQuestions = _questionsJson();
    final originalCards = _cardsJson();
    await questionsFile.writeAsString(originalQuestions);
    await cardsFile.writeAsString(originalCards);

    final plan = await workflow.applyCsvToFiles(
      csv: _reviewCsv(
        sourceTitle: '大気の組成',
        sourcePublisher: '気象庁',
        sourceUrl: 'https://www.jma.go.jp/example',
        verifiedAt: '2026-07-12',
        verificationLevel: 'primary',
        reviewStatus: 'approved',
      ),
      questionsPath: questionsFile.path,
      cardsPath: cardsFile.path,
      write: false,
    );

    expect(plan.hasChanges, isTrue);
    expect(await questionsFile.readAsString(), originalQuestions);
    expect(await cardsFile.readAsString(), originalCards);
  });

  test('category progress counts only matching approved pairs', () {
    final source = {
      'title': '大気の組成',
      'publisher': '気象庁',
      'url': 'https://www.jma.go.jp/example',
      'verifiedAt': '2026-07-12',
      'verificationLevel': 'primary',
      'reviewStatus': 'approved',
    };
    final progress = workflow.progress(
      questionsJson: _questionsJson(source: source),
      cardsJson: _cardsJson(source: source),
    );

    expect(progress, hasLength(1));
    expect(progress.single.category, 'science');
    expect(progress.single.approved, 1);
    expect(progress.single.total, 1);
  });

  test('risk extraction identifies numeric, ranking, and medical claims', () {
    final risks = workflow.risks(
      questionsJson: _questionsJson(),
      cardsJson: _cardsJson(),
    );

    expect(risks, hasLength(1));
    expect(risks.single.reasons, containsAll(['numeric', 'medical']));
    expect(workflow.riskCsv(
      questionsJson: _questionsJson(),
      cardsJson: _cardsJson(),
    ), contains('q_001,card_001,science'));
  });
}

String _questionsJson({
  String question = '空気の中で一番多い成分は？',
  String explanation = '空気の約78%は窒素です。',
  Map<String, dynamic>? source,
}) {
  return '${const JsonEncoder.withIndent('  ').convert([
    {
      'id': 'q_001',
      'category': 'science',
      'difficulty': 'easy',
      'question': question,
      'choices': ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
      'answerIndex': 1,
      'explanation': explanation,
      'relatedCardId': 'card_001',
      'sourceNote': '気象庁',
      'verified': true,
      if (source != null) 'source': source,
    },
  ])}\n';
}

String _cardsJson({Map<String, dynamic>? source}) {
  return '${const JsonEncoder.withIndent('  ').convert([
    {
      'id': 'card_001',
      'title': '大気の成分',
      'category': 'science',
      'shortText': '空気の約78%は窒素。',
      'detailText': '心臓や血液にも必要な空気は窒素を最も多く含む。',
      'imageAsset': '',
      'rarity': 'normal',
      'sourceNote': '気象庁',
      if (source != null) 'source': source,
    },
  ])}\n';
}

String _reviewCsv({
  String questionId = 'q_001',
  String cardId = 'card_001',
  String category = 'science',
  String question = '空気の中で一番多い成分は？',
  String answer = '窒素',
  String explanation = '空気の約78%は窒素です。',
  String sourceTitle = '',
  String sourcePublisher = '',
  String sourceUrl = '',
  String verifiedAt = '',
  String verificationLevel = 'unverified',
  String reviewStatus = 'pending',
  String reviewNote = '',
}) {
  final values = [
    questionId,
    cardId,
    category,
    question,
    answer,
    explanation,
    sourceTitle,
    sourcePublisher,
    sourceUrl,
    verifiedAt,
    verificationLevel,
    reviewStatus,
    reviewNote,
  ];
  return '${contentReviewColumns.join(',')}\r\n${values.map(_csvValue).join(',')}\r\n';
}

String _csvValue(String value) {
  if (!value.contains(RegExp(r'[,"\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
