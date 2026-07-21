import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/content_validator.dart';

import '../helpers/release_content.dart';

void main() {
  const validator = ContentValidator();

  group('ContentValidator', () {
    test('release-approved content and matching manifest pass', () {
      final content = _releaseJson();
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode(content.questions),
        cardsJson: jsonEncode(content.cards),
        manifestJson: jsonEncode(_manifest()),
        assetExists: (path) => path == 'assets/images/cards/card_001.png',
      );

      expect(result.isValid, isTrue, reason: _messages(result).join('\n'));
      expect(result.questionCount, 1);
      expect(result.cardCount, 1);
      expect(result.playableQuestionCount, 1);
    });

    test('invalid JSON and non-array roots are reported together', () {
      final result = validator.validateJsonStrings(
        questionsJson: '{invalid',
        cardsJson: jsonEncode({'id': 'not-an-array'}),
        assetExists: (_) => true,
      );

      expect(result.isValid, isFalse);
      expect(
        _messages(result),
        contains(startsWith('questions: invalid JSON')),
      );
      expect(_messages(result), contains('cards: root must be a JSON array'));
    });

    test('empty arrays are rejected even without a release gate', () {
      final result = validator.validateJsonStrings(
        questionsJson: '[]',
        cardsJson: '[]',
        assetExists: (_) => true,
        requirePlayable: false,
      );

      expect(
        _messages(result),
        contains('questions: must contain at least one question'),
      );
      expect(
        _messages(result),
        contains('cards: must contain at least one card'),
      );
    });

    test('pending content may be reviewed but is not release playable', () {
      final content = _releaseJson();
      final question = Map<String, dynamic>.from(content.questions.single)
        ..['verified'] = false
        ..remove('source');
      final card = Map<String, dynamic>.from(content.cards.single)
        ..remove('source');

      final reviewResult = validator.validateJsonStrings(
        questionsJson: jsonEncode([question]),
        cardsJson: jsonEncode([card]),
        assetExists: (_) => true,
        requirePlayable: false,
      );
      final releaseResult = validator.validateJsonStrings(
        questionsJson: jsonEncode([question]),
        cardsJson: jsonEncode([card]),
        assetExists: (_) => true,
      );

      expect(
        reviewResult.isValid,
        isTrue,
        reason: _messages(reviewResult).join('\n'),
      );
      expect(
        _messages(releaseResult),
        contains(
          'questions: must contain at least one release-approved playable question',
        ),
      );
    });

    test('pending source review stubs are accepted for editable content', () {
      final content = _releaseJson();
      final question = Map<String, dynamic>.from(content.questions.single)
        ..['verified'] = false
        ..['source'] = {
          'reviewStatus': 'pending',
          'reviewNote': '出典を再確認する',
        };
      final card = Map<String, dynamic>.from(content.cards.single)
        ..['source'] = {
          'reviewStatus': 'correction_required',
          'reviewNote': '説明文を修正する',
        };

      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([question]),
        cardsJson: jsonEncode([card]),
        assetExists: (_) => true,
        requirePlayable: false,
      );

      expect(result.isValid, isTrue, reason: _messages(result).join('\n'));
      expect(result.playableQuestionCount, 0);
    });

    test('changed reviewed text invalidates its content hash', () {
      final content = _releaseJson();
      final question = Map<String, dynamic>.from(content.questions.single)
        ..['question'] = '承認後に書き換えた問題';
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([question]),
        cardsJson: jsonEncode(content.cards),
        assetExists: (_) => true,
      );

      expect(
        _messages(result),
        contains(
          'questions[0].source.contentHash: does not match the current reviewed question/card content',
        ),
      );
    });

    test('missing image review and invalid relationships are rejected', () {
      final content = _releaseJson();
      final question = Map<String, dynamic>.from(content.questions.single)
        ..['relatedCardId'] = 'missing';
      final card = Map<String, dynamic>.from(content.cards.single)
        ..remove('imageReview');
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([question]),
        cardsJson: jsonEncode([card]),
        assetExists: (_) => true,
      );

      expect(
        _messages(result),
        contains('cards[0].imageReview: must be persisted'),
      );
      expect(
        _messages(result),
        contains(
          'questions[0].relatedCardId: references missing card "missing"',
        ),
      );
    });

    test('manifest counts must match validated content', () {
      final content = _releaseJson();
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode(content.questions),
        cardsJson: jsonEncode(content.cards),
        manifestJson: jsonEncode({
          'schemaVersion': 1,
          'questionCount': 2,
          'cardCount': 1,
          'playableQuestionCount': 0,
        }),
        assetExists: (_) => true,
      );

      expect(
        _messages(result),
        contains('manifest.questionCount: expected 2 but found 1'),
      );
      expect(
        _messages(result),
        contains('manifest.playableQuestionCount: expected 0 but found 1'),
      );
    });
  });

  group('validate_content CLI', () {
    test('returns zero for valid data and one for invalid data', () async {
      final root = await Directory.systemTemp.createTemp('hee-content-test-');
      addTearDown(() => root.delete(recursive: true));

      final dataDirectory = Directory('${root.path}/assets/data');
      final imageDirectory = Directory('${root.path}/assets/images/cards');
      await dataDirectory.create(recursive: true);
      await imageDirectory.create(recursive: true);
      await File('${imageDirectory.path}/card_001.png').writeAsBytes([1, 2, 3]);

      final content = _releaseJson();
      final questionsFile = File('${dataDirectory.path}/questions.json');
      await questionsFile.writeAsString(jsonEncode(content.questions));
      await File(
        '${dataDirectory.path}/cards.json',
      ).writeAsString(jsonEncode(content.cards));
      await File(
        '${dataDirectory.path}/content_manifest.json',
      ).writeAsString(jsonEncode(_manifest()));

      final success = await _runCli(root.path);
      expect(
        success.exitCode,
        0,
        reason: '${success.stdout}\n${success.stderr}',
      );
      expect(success.stdout, contains('1 questions, 1 cards, 1 playable'));

      final invalid = Map<String, dynamic>.from(content.questions.single)
        ..['answerIndex'] = 9;
      await questionsFile.writeAsString(jsonEncode([invalid]));
      final failure = await _runCli(root.path);
      expect(failure.exitCode, 1);
      expect(failure.stderr, contains('Content validation failed'));
      expect(
        failure.stderr,
        contains('questions[0].answerIndex: must point to an existing choice'),
      );
    });
  });
}

_ReleaseJson _releaseJson() {
  final pair = releaseContentPair(
    id: '001',
    questionText: '空気の中で一番多い成分は？',
    choices: const ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
    answerIndex: 1,
    explanation: '空気の約78%は窒素です。',
    title: '大気の成分',
    shortText: '空気の約78%は窒素。',
    detailText: '地球の大気は窒素、酸素などで構成されています。',
    imageAsset: 'assets/images/cards/card_001.png',
  );
  return _ReleaseJson(
    questions: [pair.question.toJson()],
    cards: [pair.card.toJson()],
  );
}

Map<String, dynamic> _manifest() => <String, dynamic>{
  'schemaVersion': 1,
  'questionCount': 1,
  'cardCount': 1,
  'playableQuestionCount': 1,
};

class _ReleaseJson {
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> cards;

  const _ReleaseJson({required this.questions, required this.cards});
}

List<String> _messages(ContentValidationResult result) =>
    result.issues.map((issue) => issue.toString()).toList();

Future<ProcessResult> _runCli(String rootPath) {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final executable = flutterRoot == null
      ? 'dart'
      : Platform.isWindows
      ? '$flutterRoot\\bin\\dart.bat'
      : '$flutterRoot/bin/dart';

  return Process.run(executable, [
    'run',
    'tool/validate_content.dart',
    '--root',
    rootPath,
  ], workingDirectory: Directory.current.path);
}
