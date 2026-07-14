import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_review_workflow.dart';

import '../helpers/release_content.dart';

void main() {
  const workflow = ContentReviewWorkflow();

  test('export covers all reviewable claims and quotes CSV safely', () {
    final csv = workflow.exportCsv(
      questionsJson: _questionsJson(
        question: '空気で,最も多い成分は？',
        explanation: '答えは窒素。\n約78%です。',
      ),
      cardsJson: _cardsJson(),
    );

    expect(csv.split('\r\n').first, contentReviewColumns.join(','));
    expect(csv, contains('choice0,choice1,choice2,choice3,answerIndex'));
    expect(csv, contains('cardTitle,cardShortText,cardDetailText,cardRarity'));
    expect(csv, contains('imageReviewStatus,imageReviewedAt,imageReviewNote'));
    expect(csv, contains('reviewNote,contentHash'));
    expect(csv, contains('"空気で,最も多い成分は？"'));
    expect(csv, contains('"答えは窒素。\n約78%です。"'));
  });

  test('an unchanged exported pending CSV produces no JSON diff', () {
    final questions = _questionsJson();
    final cards = _cardsJson();
    final csv = workflow.exportCsv(questionsJson: questions, cardsJson: cards);

    final plan = workflow.planImport(
      csv: csv,
      questionsJson: questions,
      cardsJson: cards,
    );

    expect(plan.hasChanges, isFalse);
  });

  test('approved source and visual review are applied to the pair', () {
    final questions = _questionsJson();
    final cards = _cardsJson();
    final csv = _reviewCsv(
      workflow: workflow,
      questionsJson: questions,
      cardsJson: cards,
      updates: const {
        'sourceTitle': '大気の組成',
        'sourcePublisher': '気象庁',
        'sourceUrl': 'https://www.jma.go.jp/example',
        'verifiedAt': '2026-07-12',
        'verificationLevel': 'primary',
        'reviewStatus': 'approved',
        'reviewNote': '一次資料で確認',
        'imageReviewStatus': 'generic_placeholder',
        'imageReviewedAt': '2026-07-14',
        'imageReviewNote': '汎用画像として確認',
      },
    );
    final plan = workflow.planImport(
      csv: csv,
      questionsJson: questions,
      cardsJson: cards,
    );

    expect(plan.changes, hasLength(1));
    final question = (jsonDecode(plan.questionsJson) as List).single as Map;
    final card = (jsonDecode(plan.cardsJson) as List).single as Map;
    expect(question['source'], card['source']);
    expect(question['verified'], isTrue);
    expect((question['source'] as Map)['reviewStatus'], 'approved');
    expect((question['source'] as Map)['reviewNote'], '一次資料で確認');
    expect((question['source'] as Map)['contentHash'], hasLength(64));
    expect((card['imageReview'] as Map)['status'], 'generic_placeholder');
  });

  test('approved source without required evidence is rejected', () {
    final questions = _questionsJson();
    final cards = _cardsJson();
    final csv = _reviewCsv(
      workflow: workflow,
      questionsJson: questions,
      cardsJson: cards,
      updates: const {
        'sourceTitle': '資料',
        'sourcePublisher': '発行元',
        'verifiedAt': '2026-07-12',
        'verificationLevel': 'primary',
        'reviewStatus': 'approved',
        'imageReviewStatus': 'generic_placeholder',
        'imageReviewedAt': '2026-07-14',
      },
    );

    expect(
      () => workflow.planImport(
        csv: csv,
        questionsJson: questions,
        cardsJson: cards,
      ),
      throwsA(isA<ContentReviewException>()),
    );
  });

  test('changed immutable content and stale content hashes are rejected', () {
    final questions = _questionsJson();
    final cards = _cardsJson();
    expect(
      () => workflow.planImport(
        csv: _reviewCsv(
          workflow: workflow,
          questionsJson: questions,
          cardsJson: cards,
          updates: const {'question': '書き換えた問題'},
        ),
        questionsJson: questions,
        cardsJson: cards,
      ),
      throwsA(isA<ContentReviewException>()),
    );
    expect(
      () => workflow.planImport(
        csv: _reviewCsv(
          workflow: workflow,
          questionsJson: questions,
          cardsJson: cards,
          updates: {'contentHash': List<String>.filled(64, '0').join()},
        ),
        questionsJson: questions,
        cardsJson: cards,
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
        csv: _reviewCsv(
          workflow: workflow,
          questionsJson: originalQuestions,
          cardsJson: originalCards,
          updates: const {'questionId': 'q_changed'},
        ),
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
        workflow: workflow,
        questionsJson: originalQuestions,
        cardsJson: originalCards,
        updates: const {
          'sourceTitle': '大気の組成',
          'sourcePublisher': '気象庁',
          'sourceUrl': 'https://www.jma.go.jp/example',
          'verifiedAt': '2026-07-12',
          'verificationLevel': 'primary',
          'reviewStatus': 'approved',
          'imageReviewStatus': 'generic_placeholder',
          'imageReviewedAt': '2026-07-14',
        },
      ),
      questionsPath: questionsFile.path,
      cardsPath: cardsFile.path,
      write: false,
    );

    expect(plan.hasChanges, isTrue);
    expect(await questionsFile.readAsString(), originalQuestions);
    expect(await cardsFile.readAsString(), originalCards);
  });

  test('category progress counts only release-approved pairs', () {
    final pair = releaseContentPair(
      id: '001',
      questionText: '空気の中で一番多い成分は？',
      choices: const ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
      answerIndex: 1,
      explanation: '空気の約78%は窒素です。',
      title: '大気の成分',
      shortText: '空気の約78%は窒素。',
      detailText: '心臓や血液にも必要な空気は窒素を最も多く含む。',
    );
    final progress = workflow.progress(
      questionsJson: jsonEncode([pair.question.toJson()]),
      cardsJson: jsonEncode([pair.card.toJson()]),
    );

    expect(progress.single.approved, 1);
    expect(progress.single.total, 1);
  });

  test('risk extraction scans distractors as well as the correct answer', () {
    final risks = workflow.risks(
      questionsJson: _questionsJson(),
      cardsJson: _cardsJson(),
    );

    expect(risks, hasLength(1));
    expect(risks.single.reasons, containsAll(['numeric', 'medical']));
  });
}

String _questionsJson({
  String question = '空気の中で一番多い成分は？',
  String explanation = '空気の約78%は窒素です。',
}) =>
    '${const JsonEncoder.withIndent('  ').convert([
      <String, dynamic>{
        'id': 'q_001',
        'category': 'science',
        'difficulty': 'easy',
        'question': question,
        'choices': ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
        'answerIndex': 1,
        'explanation': explanation,
        'relatedCardId': 'card_001',
        'sourceNote': '気象庁',
        'verified': false,
      },
    ])}\n';

String _cardsJson() =>
    '${const JsonEncoder.withIndent('  ').convert([
      <String, dynamic>{
        'id': 'card_001',
        'title': '大気の成分',
        'category': 'science',
        'shortText': '空気の約78%は窒素。',
        'detailText': '心臓や血液にも必要な空気は窒素を最も多く含む。',
        'imageAsset': 'assets/images/cards/card_001.png',
        'rarity': 'normal',
        'sourceNote': '気象庁',
        'imageReview': <String, dynamic>{'status': 'unchecked', 'reviewedAt': ''},
      },
    ])}\n';

String _reviewCsv({
  required ContentReviewWorkflow workflow,
  required String questionsJson,
  required String cardsJson,
  required Map<String, String> updates,
}) {
  final table = _parseCsv(
    workflow.exportCsv(questionsJson: questionsJson, cardsJson: cardsJson),
  );
  final header = table.first;
  final row = table[1];
  for (final entry in updates.entries) {
    final index = header.indexOf(entry.key);
    if (index < 0) throw StateError('Unknown column ${entry.key}');
    row[index] = entry.value;
  }
  return _encodeCsv(table);
}

List<List<String>> _parseCsv(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (quoted) {
      if (character == '"') {
        if (index + 1 < source.length && source[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = false;
        }
      } else {
        field.write(character);
      }
    } else if (character == '"') {
      quoted = true;
    } else if (character == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (character == '\n') {
      row.add(field.toString().replaceAll(RegExp(r'\r$'), ''));
      if (row.any((value) => value.isNotEmpty)) rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(character);
    }
  }
  return rows;
}

String _encodeCsv(List<List<String>> rows) =>
    '${rows.map((row) => row.map(_csvValue).join(',')).join('\r\n')}\r\n';

String _csvValue(String value) {
  if (!value.contains(RegExp(r'[,"\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
