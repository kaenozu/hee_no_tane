import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_review_workflow.dart';

final class _FailingFileStore implements ContentReviewFileStore {
  final Map<String, String> files;
  bool failCardInstall = true;

  _FailingFileStore(this.files);

  @override
  Future<void> delete(String path) async {
    if (!files.containsKey(path)) throw StateError('missing file: $path');
    files.remove(path);
  }

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<String> readAsString(String path) async {
    final value = files[path];
    if (value == null) throw StateError('missing file: $path');
    return value;
  }

  @override
  Future<void> rename(String sourcePath, String targetPath) async {
    if (failCardInstall &&
        sourcePath == 'cards.json.tmp' &&
        targetPath == 'cards.json') {
      failCardInstall = false;
      throw StateError('injected card install failure');
    }
    final value = files.remove(sourcePath);
    if (value == null) throw StateError('missing file: $sourcePath');
    files[targetPath] = value;
  }

  @override
  Future<void> writeAsString(
    String path,
    String content, {
    bool flush = false,
  }) async {
    files[path] = content;
  }
}

void main() {
  const workflow = ContentReviewWorkflow();

  test('two-file write restores both originals when the second install fails', () async {
    final questions = '${jsonEncode([
      <String, dynamic>{
        'id': 'q_1',
        'category': 'science',
        'difficulty': 'easy',
        'question': '空気の主成分は？',
        'choices': ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
        'answerIndex': 1,
        'explanation': '窒素です。',
        'relatedCardId': 'card_1',
        'sourceNote': '確認中',
        'verified': false,
      },
    ])}\n';
    final cards = '${jsonEncode([
      <String, dynamic>{
        'id': 'card_1',
        'title': '大気',
        'category': 'science',
        'shortText': '空気の主成分。',
        'detailText': '空気には窒素が多く含まれます。',
        'imageAsset': 'assets/images/cards/card_1.png',
        'rarity': 'normal',
        'sourceNote': '確認中',
        'imageReview': <String, dynamic>{
          'status': 'unchecked',
          'reviewedAt': '',
        },
      },
    ])}\n';

    final table = _parseCsv(
      workflow.exportCsv(questionsJson: questions, cardsJson: cards),
    );
    final header = table.first;
    final row = table[1];
    row[header.indexOf('imageReviewStatus')] = 'generic_placeholder';
    row[header.indexOf('imageReviewedAt')] = '2026-07-16';
    row[header.indexOf('imageReviewNote')] = '汎用画像として確認';
    final csv = _encodeCsv(table);

    final store = _FailingFileStore(<String, String>{
      'questions.json': questions,
      'cards.json': cards,
    });

    await expectLater(
      workflow.applyCsvToFiles(
        csv: csv,
        questionsPath: 'questions.json',
        cardsPath: 'cards.json',
        write: true,
        fileStore: store,
      ),
      throwsA(isA<StateError>()),
    );

    expect(store.files['questions.json'], questions);
    expect(store.files['cards.json'], cards);
    expect(store.files.keys.where((path) => path.endsWith('.bak')), isEmpty);
    expect(store.files.keys.where((path) => path.endsWith('.tmp')), isEmpty);
  });
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
