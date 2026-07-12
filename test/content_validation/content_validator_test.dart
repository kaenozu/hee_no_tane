import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/content_validator.dart';

void main() {
  const validator = ContentValidator();

  group('ContentValidator', () {
    test('valid content passes', () {
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([_question()]),
        cardsJson: jsonEncode([_card()]),
        assetExists: (path) => path == 'assets/images/cards/card_001.png',
      );

      expect(result.isValid, isTrue);
      expect(result.questionCount, 1);
      expect(result.cardCount, 1);
      expect(result.issues, isEmpty);
    });

    test('invalid JSON and non-array roots are reported together', () {
      final result = validator.validateJsonStrings(
        questionsJson: '{invalid',
        cardsJson: jsonEncode({'id': 'not-an-array'}),
        assetExists: (_) => true,
      );

      expect(result.isValid, isFalse);
      expect(_messages(result), contains(startsWith('questions: invalid JSON')));
      expect(
        _messages(result),
        contains('cards: root must be a JSON array'),
      );
    });

    test('required fields, object types, and duplicate ids are reported', () {
      final duplicateQuestion = _question();
      final duplicateCard = _card();
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([
          duplicateQuestion,
          duplicateQuestion,
          'not-an-object',
          {'id': ''},
        ]),
        cardsJson: jsonEncode([
          duplicateCard,
          duplicateCard,
          42,
          {'id': ''},
        ]),
        assetExists: (_) => true,
      );

      final messages = _messages(result);
      expect(messages, contains('questions[1].id: duplicate id "q_001"'));
      expect(messages, contains('cards[1].id: duplicate id "card_001"'));
      expect(messages, contains('questions[2]: must be a JSON object'));
      expect(messages, contains('cards[2]: must be a JSON object'));
      expect(messages, contains('questions[3].category: is required'));
      expect(messages, contains('cards[3].title: is required'));
    });

    test('question value constraints are validated', () {
      final invalidQuestion = _question(
        overrides: {
          'category': 'unknown',
          'difficulty': 'impossible',
          'question': '',
          'choices': ['same', 'same', '', 3],
          'answerIndex': 4,
          'explanation': '',
          'sourceNote': '',
          'verified': false,
        },
      );
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([invalidQuestion]),
        cardsJson: jsonEncode([_card()]),
        assetExists: (_) => true,
      );

      final messages = _messages(result);
      expect(
        messages,
        contains(
          'questions[0].category: must be one of '
          'nature_geography, living_things, history, science, food, '
          'language, daily_life, got "unknown"',
        ),
      );
      expect(
        messages,
        contains(
          'questions[0].difficulty: must be one of easy, normal, hard, '
          'got "impossible"',
        ),
      );
      expect(messages, contains('questions[0].question: must not be empty'));
      expect(messages, contains('questions[0].choices[2]: must not be empty'));
      expect(messages, contains('questions[0].choices[3]: must be a string'));
      expect(messages, contains('questions[0].choices: must not contain duplicates'));
      expect(messages, contains('questions[0].answerIndex: expected 0..3, got 4'));
      expect(
        messages,
        contains(
          'questions[0].verified: must be true for bundled production content',
        ),
      );
    });

    test('choice count and answer type are validated', () {
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([
          _question(overrides: {'choices': ['A', 'B'], 'answerIndex': '0'}),
        ]),
        cardsJson: jsonEncode([_card()]),
        assetExists: (_) => true,
      );

      expect(
        _messages(result),
        contains('questions[0].choices: must contain exactly 4 choices, got 2'),
      );
      expect(
        _messages(result),
        contains('questions[0].answerIndex: must be an int'),
      );
    });

    test('card constraints and missing image assets are validated', () {
      final invalidCard = _card(
        overrides: {
          'category': 'unknown',
          'title': '',
          'shortText': '',
          'detailText': '',
          'rarity': 'legendary',
          'sourceNote': '',
          'imageAsset': 'assets/images/cards/missing.png',
        },
      );
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([_question()]),
        cardsJson: jsonEncode([invalidCard]),
        assetExists: (_) => false,
      );

      final messages = _messages(result);
      expect(messages, contains('cards[0].title: must not be empty'));
      expect(messages, contains('cards[0].shortText: must not be empty'));
      expect(messages, contains('cards[0].detailText: must not be empty'));
      expect(messages, contains('cards[0].sourceNote: must not be empty'));
      expect(
        messages,
        contains(
          'cards[0].rarity: must be one of normal, rare, got "legendary"',
        ),
      );
      expect(
        messages,
        contains(
          'cards[0].imageAsset: file does not exist: '
          '"assets/images/cards/missing.png"',
        ),
      );
    });

    test('missing references, category mismatches, and unused cards fail', () {
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([
          _question(overrides: {'relatedCardId': 'missing'}),
          _question(
            overrides: {
              'id': 'q_002',
              'category': 'history',
              'relatedCardId': 'card_001',
            },
          ),
        ]),
        cardsJson: jsonEncode([
          _card(),
          _card(overrides: {'id': 'card_unused'}),
        ]),
        assetExists: (_) => true,
      );

      final messages = _messages(result);
      expect(
        messages,
        contains(
          'questions[0].relatedCardId: card "missing" does not exist',
        ),
      );
      expect(
        messages,
        contains(
          'questions[1].category: must match cards[0].category "science"',
        ),
      );
      expect(
        messages,
        contains(
          'cards[1].id: card "card_unused" is not referenced by any question',
        ),
      );
    });

    test('length limits and several errors are collected in one result', () {
      final result = validator.validateJsonStrings(
        questionsJson: jsonEncode([
          _question(
            overrides: {
              'question': 'q' * 101,
              'explanation': 'e' * 241,
              'sourceNote': 's' * 121,
            },
          ),
        ]),
        cardsJson: jsonEncode([
          _card(
            overrides: {
              'title': 't' * 61,
              'shortText': 's' * 141,
              'detailText': 'd' * 501,
            },
          ),
        ]),
        assetExists: (_) => true,
      );

      expect(result.issues.length, greaterThanOrEqualTo(6));
      expect(
        _messages(result),
        contains('questions[0].question: must be at most 100 characters, got 101'),
      );
      expect(
        _messages(result),
        contains('cards[0].detailText: must be at most 500 characters, got 501'),
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

      final questionsFile = File('${dataDirectory.path}/questions.json');
      final cardsFile = File('${dataDirectory.path}/cards.json');
      await questionsFile.writeAsString(jsonEncode([_question()]));
      await cardsFile.writeAsString(jsonEncode([_card()]));

      final success = await _runCli(root.path);
      expect(success.exitCode, 0, reason: '${success.stdout}\n${success.stderr}');
      expect(success.stdout, contains('Content validation passed: 1 questions, 1 cards'));

      await questionsFile.writeAsString(
        jsonEncode([_question(overrides: {'answerIndex': 9})]),
      );
      final failure = await _runCli(root.path);
      expect(failure.exitCode, 1);
      expect(failure.stderr, contains('Content validation failed'));
      expect(
        failure.stderr,
        contains('questions[0].answerIndex: expected 0..3, got 9'),
      );
    });
  });
}

Map<String, dynamic> _question({Map<String, dynamic> overrides = const {}}) {
  return {
    'id': 'q_001',
    'category': 'science',
    'difficulty': 'easy',
    'question': '空気の中で一番多い成分は？',
    'choices': ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
    'answerIndex': 1,
    'explanation': '空気の約78%は窒素です。',
    'relatedCardId': 'card_001',
    'sourceNote': '気象庁',
    'verified': true,
    ...overrides,
  };
}

Map<String, dynamic> _card({Map<String, dynamic> overrides = const {}}) {
  return {
    'id': 'card_001',
    'title': '大気の成分',
    'category': 'science',
    'shortText': '空気の約78%は窒素。',
    'detailText': '地球の大気は窒素、酸素などで構成されています。',
    'imageAsset': 'assets/images/cards/card_001.png',
    'rarity': 'normal',
    'sourceNote': '気象庁',
    ...overrides,
  };
}

List<String> _messages(ContentValidationResult result) {
  return result.issues.map((issue) => issue.toString()).toList();
}

Future<ProcessResult> _runCli(String rootPath) {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final executable = flutterRoot == null
      ? 'dart'
      : Platform.isWindows
      ? '$flutterRoot\\bin\\dart.bat'
      : '$flutterRoot/bin/dart';

  return Process.run(
    executable,
    ['run', 'tool/validate_content.dart', '--root', rootPath],
    workingDirectory: Directory.current.path,
  );
}
