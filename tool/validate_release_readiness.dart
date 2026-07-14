// リリースゲートの検証ツール
// 公開ブロッカーを機械的に検出する

import 'dart:convert';
import 'dart:io';

typedef ReleaseReadinessEvaluation =
    ({bool success, Map<String, Object?> report});

Future<void> main(List<String> arguments) async {
  exitCode = await runReleaseReadiness(arguments);
}

Future<int> runReleaseReadiness(
  List<String> arguments, {
  void Function(String value)? writeOutput,
}) async {
  final emit = writeOutput ?? (value) => stdout.writeln(value);

  ReleaseReadinessOptions options;
  try {
    options = ReleaseReadinessOptions.parse(arguments);
  } on FormatException catch (error) {
    emit(
      _encodeReport({
        'tool': 'validate_release_readiness',
        'success': false,
        'error': {
          'code': 'invalid_arguments',
          'message': error.message,
          'usage': ReleaseReadinessOptions.usage,
        },
      }),
    );
    return 1;
  }

  final root = Directory(options.root).absolute;
  final questionsFile = _resolveFile(root, options.questionsPath);
  final cardsFile = _resolveFile(root, options.cardsPath);
  final inputErrors = <Map<String, Object?>>[];

  if (!questionsFile.existsSync()) {
    inputErrors.add({
      'code': 'questions_file_missing',
      'path': questionsFile.path,
    });
  }
  if (!cardsFile.existsSync()) {
    inputErrors.add({
      'code': 'cards_file_missing',
      'path': cardsFile.path,
    });
  }
  if (inputErrors.isNotEmpty) {
    emit(
      _encodeReport({
        'tool': 'validate_release_readiness',
        'success': false,
        'configuration': options.toJson(root: root),
        'errors': inputErrors,
      }),
    );
    return 1;
  }

  String questionsJson;
  String cardsJson;
  try {
    questionsJson = await questionsFile.readAsString();
    cardsJson = await cardsFile.readAsString();
  } on FileSystemException catch (error) {
    emit(
      _encodeReport({
        'tool': 'validate_release_readiness',
        'success': false,
        'configuration': options.toJson(root: root),
        'errors': [
          {
            'code': 'file_read_failed',
            'message': error.message,
            'path': error.path,
          },
        ],
      }),
    );
    return 1;
  }

  final decodeErrors = <Map<String, Object?>>[];
  final questions = _decodeObjectList(
    questionsJson,
    label: 'questions',
    errors: decodeErrors,
  );
  final cards = _decodeObjectList(
    cardsJson,
    label: 'cards',
    errors: decodeErrors,
  );
  if (decodeErrors.isNotEmpty) {
    emit(
      _encodeReport({
        'tool': 'validate_release_readiness',
        'success': false,
        'configuration': options.toJson(root: root),
        'errors': decodeErrors,
      }),
    );
    return 1;
  }

  final evaluation = validateReleaseReadiness(
    questions: questions,
    cards: cards,
    expectedPairs: options.expectedPairs,
    requireFinalImages: options.requireFinalImages,
    assetExists: (path) => _resolveFile(root, path).existsSync(),
  );
  emit(
    _encodeReport({
      'tool': 'validate_release_readiness',
      'success': evaluation.success,
      'configuration': options.toJson(root: root),
      ...evaluation.report,
    }),
  );
  return evaluation.success ? 0 : 1;
}

ReleaseReadinessEvaluation validateReleaseReadiness({
  required List<Map<String, dynamic>> questions,
  required List<Map<String, dynamic>> cards,
  required int expectedPairs,
  required bool requireFinalImages,
  required bool Function(String path) assetExists,
}) {
  final duplicateQuestionIds = <String>{};
  final duplicateCardIds = <String>{};
  final questionIds = <String>{};
  final cardById = <String, Map<String, dynamic>>{};

  for (final card in cards) {
    final id = _nonEmptyString(card['id']);
    if (id == null) continue;
    if (cardById.containsKey(id)) {
      duplicateCardIds.add(id);
    } else {
      cardById[id] = card;
    }
  }

  final unverifiedQuestionIds = <String>[];
  final unapprovedQuestionIds = <String>[];
  final unapprovedCardIds = <String>[];
  final unapprovedPairIds = <String>[];
  final missingRelatedCardIds = <String>[];
  final duplicateRelatedCardIds = <String>[];
  final referencedCardIds = <String>{};
  var matchedPairCount = 0;
  var approvedPairCount = 0;

  for (var index = 0; index < questions.length; index++) {
    final question = questions[index];
    final questionId = _recordLabel(question, index, prefix: 'question');
    final rawQuestionId = _nonEmptyString(question['id']);
    if (rawQuestionId != null && !questionIds.add(rawQuestionId)) {
      duplicateQuestionIds.add(rawQuestionId);
    }
    if (question['verified'] != true) {
      unverifiedQuestionIds.add(questionId);
    }

    final questionApproved = _reviewStatus(question) == 'approved';
    if (!questionApproved) {
      unapprovedQuestionIds.add(questionId);
    }

    final relatedCardId = _nonEmptyString(question['relatedCardId']);
    final card = relatedCardId == null ? null : cardById[relatedCardId];
    if (card == null) {
      missingRelatedCardIds.add(relatedCardId ?? '$questionId:<missing>');
      unapprovedPairIds.add(questionId);
      continue;
    }
    if (!referencedCardIds.add(relatedCardId!)) {
      duplicateRelatedCardIds.add(relatedCardId);
      unapprovedPairIds.add(questionId);
      continue;
    }

    matchedPairCount++;
    final cardApproved = _reviewStatus(card) == 'approved';
    if (!cardApproved) {
      unapprovedCardIds.add(relatedCardId);
    }
    if (questionApproved && cardApproved) {
      approvedPairCount++;
    } else {
      unapprovedPairIds.add(questionId);
    }
  }

  for (final entry in cardById.entries) {
    if (_reviewStatus(entry.value) != 'approved' &&
        !unapprovedCardIds.contains(entry.key)) {
      unapprovedCardIds.add(entry.key);
    }
  }

  final unreferencedCardIds = cardById.keys
      .where((id) => !referencedCardIds.contains(id))
      .toList();
  final genericPlaceholderCardIds = <String>[];
  final nonApprovedImageReviewCardIds = <String>[];
  final missingImageCardIds = <String>[];

  for (var index = 0; index < cards.length; index++) {
    final card = cards[index];
    final cardId = _recordLabel(card, index, prefix: 'card');
    final imageReview = card['imageReview'];
    final imageStatus = imageReview is Map
        ? _nonEmptyString(imageReview['status'])
        : null;
    if (imageStatus == 'generic_placeholder') {
      genericPlaceholderCardIds.add(cardId);
    }
    if (imageStatus != 'approved') {
      nonApprovedImageReviewCardIds.add(cardId);
    }

    final imageAsset = _nonEmptyString(card['imageAsset']);
    if (imageAsset == null || !assetExists(imageAsset)) {
      missingImageCardIds.add(cardId);
    }
  }

  final duplicateQuestionIdList = _sorted(duplicateQuestionIds);
  final duplicateCardIdList = _sorted(duplicateCardIds);
  final unverifiedQuestionIdList = _sorted(unverifiedQuestionIds);
  final unapprovedQuestionIdList = _sorted(unapprovedQuestionIds);
  final unapprovedCardIdList = _sorted(unapprovedCardIds);
  final unapprovedPairIdList = _sorted(unapprovedPairIds);
  final missingRelatedCardIdList = _sorted(missingRelatedCardIds);
  final duplicateRelatedCardIdList = _sorted(duplicateRelatedCardIds);
  final unreferencedCardIdList = _sorted(unreferencedCardIds);
  final genericPlaceholderCardIdList = _sorted(genericPlaceholderCardIds);
  final nonApprovedImageReviewCardIdList = _sorted(
    nonApprovedImageReviewCardIds,
  );
  final missingImageCardIdList = _sorted(missingImageCardIds);

  final pairStructurePassed =
      questions.length == expectedPairs &&
      cards.length == expectedPairs &&
      matchedPairCount == expectedPairs &&
      duplicateQuestionIdList.isEmpty &&
      duplicateCardIdList.isEmpty &&
      missingRelatedCardIdList.isEmpty &&
      duplicateRelatedCardIdList.isEmpty &&
      unreferencedCardIdList.isEmpty;
  final allVerifiedPassed = unverifiedQuestionIdList.isEmpty;
  final allApprovedPassed =
      unapprovedQuestionIdList.isEmpty &&
      unapprovedCardIdList.isEmpty &&
      unapprovedPairIdList.isEmpty &&
      approvedPairCount == expectedPairs;
  final finalImagesPassed =
      !requireFinalImages || nonApprovedImageReviewCardIdList.isEmpty;
  final imageFilesPassed = missingImageCardIdList.isEmpty;
  final success =
      pairStructurePassed &&
      allVerifiedPassed &&
      allApprovedPassed &&
      finalImagesPassed &&
      imageFilesPassed;

  return (
    success: success,
    report: {
      'summary': {
        'expectedPairCount': expectedPairs,
        'questionCount': questions.length,
        'cardCount': cards.length,
        'matchedPairCount': matchedPairCount,
        'verifiedCount': questions.length - unverifiedQuestionIdList.length,
        'approvedQuestionCount':
            questions.length - unapprovedQuestionIdList.length,
        'approvedCardCount': cards.length - unapprovedCardIdList.length,
        'approvedPairCount': approvedPairCount,
        'genericPlaceholderCount': genericPlaceholderCardIdList.length,
        'missingImageCount': missingImageCardIdList.length,
      },
      'checks': {
        'expectedPairs': {
          'passed': pairStructurePassed,
          'expected': expectedPairs,
          'questions': questions.length,
          'cards': cards.length,
          'matchedPairs': matchedPairCount,
          'duplicateQuestionIds': duplicateQuestionIdList,
          'duplicateCardIds': duplicateCardIdList,
          'missingRelatedCardIds': missingRelatedCardIdList,
          'duplicateRelatedCardIds': duplicateRelatedCardIdList,
          'unreferencedCardIds': unreferencedCardIdList,
        },
        'allVerified': {
          'passed': allVerifiedPassed,
          'verifiedCount': questions.length - unverifiedQuestionIdList.length,
          'failedCount': unverifiedQuestionIdList.length,
          'failedQuestionIds': unverifiedQuestionIdList,
        },
        'allApproved': {
          'passed': allApprovedPassed,
          'approvedPairCount': approvedPairCount,
          'failedPairCount': unapprovedPairIdList.length,
          'failedPairQuestionIds': unapprovedPairIdList,
          'unapprovedQuestionIds': unapprovedQuestionIdList,
          'unapprovedCardIds': unapprovedCardIdList,
        },
        'finalImages': {
          'required': requireFinalImages,
          'passed': finalImagesPassed,
          'genericPlaceholderCount': genericPlaceholderCardIdList.length,
          'genericPlaceholderCardIds': genericPlaceholderCardIdList,
          'nonApprovedImageReviewCount':
              nonApprovedImageReviewCardIdList.length,
          'nonApprovedImageReviewCardIds': nonApprovedImageReviewCardIdList,
        },
        'imageFilesPresent': {
          'passed': imageFilesPassed,
          'missingCount': missingImageCardIdList.length,
          'missingCardIds': missingImageCardIdList,
        },
      },
    },
  );
}

class ReleaseReadinessOptions {
  static const usage =
      'dart run tool/validate_release_readiness.dart '
      '[--root PATH] [--questions PATH] [--cards PATH] '
      '[--expected-pairs COUNT] [--require-final-images]';

  final String root;
  final String questionsPath;
  final String cardsPath;
  final int expectedPairs;
  final bool requireFinalImages;

  const ReleaseReadinessOptions({
    required this.root,
    required this.questionsPath,
    required this.cardsPath,
    required this.expectedPairs,
    required this.requireFinalImages,
  });

  static ReleaseReadinessOptions parse(List<String> arguments) {
    var root = '.';
    var questionsPath = 'assets/data/questions.json';
    var cardsPath = 'assets/data/cards.json';
    var expectedPairs = 103;
    var requireFinalImages = false;

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--require-final-images') {
        requireFinalImages = true;
        continue;
      }
      if (argument == '--help' || argument == '-h') {
        throw const FormatException(usage);
      }
      if (argument != '--root' &&
          argument != '--questions' &&
          argument != '--cards' &&
          argument != '--expected-pairs') {
        throw FormatException('Unknown option: $argument');
      }
      if (index + 1 >= arguments.length) {
        throw FormatException('Missing value for $argument');
      }
      final value = arguments[++index].trim();
      if (value.isEmpty) {
        throw FormatException('Empty value for $argument');
      }

      switch (argument) {
        case '--root':
          root = value;
          break;
        case '--questions':
          questionsPath = value;
          break;
        case '--cards':
          cardsPath = value;
          break;
        case '--expected-pairs':
          final parsed = int.tryParse(value);
          if (parsed == null || parsed <= 0) {
            throw FormatException(
              '--expected-pairs must be a positive integer: $value',
            );
          }
          expectedPairs = parsed;
          break;
      }
    }

    return ReleaseReadinessOptions(
      root: root,
      questionsPath: questionsPath,
      cardsPath: cardsPath,
      expectedPairs: expectedPairs,
      requireFinalImages: requireFinalImages,
    );
  }

  Map<String, Object?> toJson({required Directory root}) => {
    'root': root.path,
    'questionsPath': questionsPath,
    'cardsPath': cardsPath,
    'expectedPairs': expectedPairs,
    'requireFinalImages': requireFinalImages,
  };
}

List<Map<String, dynamic>> _decodeObjectList(
  String source, {
  required String label,
  required List<Map<String, Object?>> errors,
}) {
  dynamic decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    errors.add({
      'code': 'invalid_json',
      'path': label,
      'message': error.message,
    });
    return const [];
  }

  if (decoded is! List) {
    errors.add({
      'code': 'invalid_root_type',
      'path': label,
      'message': 'JSON root must be an array.',
    });
    return const [];
  }

  final result = <Map<String, dynamic>>[];
  for (var index = 0; index < decoded.length; index++) {
    final value = decoded[index];
    if (value is! Map) {
      errors.add({
        'code': 'invalid_record_type',
        'path': '$label[$index]',
        'message': 'Record must be an object.',
      });
      continue;
    }
    result.add(Map<String, dynamic>.from(value));
  }
  return result;
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String _recordLabel(
  Map<String, dynamic> record,
  int index, {
  required String prefix,
}) {
  return _nonEmptyString(record['id']) ?? '$prefix[$index]';
}

String? _reviewStatus(Map<String, dynamic> record) {
  final source = record['source'];
  if (source is! Map) return null;
  return _nonEmptyString(source['reviewStatus']);
}

File _resolveFile(Directory root, String path) {
  if (_isAbsolutePath(path)) return File(path);
  final normalized = path.replaceAll('/', Platform.pathSeparator);
  return File('${root.path}${Platform.pathSeparator}$normalized');
}

bool _isAbsolutePath(String path) {
  if (path.startsWith('/') || path.startsWith('\\')) return true;
  return Platform.isWindows && RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
}

List<String> _sorted(Iterable<String> values) {
  final result = values.toList();
  result.sort();
  return result;
}

String _encodeReport(Map<String, Object?> report) {
  return const JsonEncoder.withIndent('  ').convert(report);
}
