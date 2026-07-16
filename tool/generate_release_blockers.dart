// ペア単位の公開ブロッカーマニフェストを生成する。
// JSON と Markdown を build/ 配下へ出力する。

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _reviewStatuses = <String>['approved', 'pending', 'correction_required'];

Future<void> main(List<String> arguments) async {
  exitCode = await runGenerateReleaseBlockers(arguments);
}

Future<int> runGenerateReleaseBlockers(
  List<String> arguments, {
  void Function(String value)? writeOutput,
}) async {
  final emit = writeOutput ?? (value) => stdout.writeln(value);

  ReleaseBlockerOptions options;
  try {
    options = ReleaseBlockerOptions.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(ReleaseBlockerOptions.usage);
    return 1;
  }

  final root = Directory(options.root).absolute;
  final questionsFile = _resolveFile(root, options.questionsPath);
  final cardsFile = _resolveFile(root, options.cardsPath);

  try {
    final questions = await _readObjectList(questionsFile, label: 'questions');
    final cards = await _readObjectList(cardsFile, label: 'cards');
    final manifest = await generateReleaseBlockerManifest(
      root: root,
      questions: questions,
      cards: cards,
      expectedPairs: options.expectedPairs,
      configuration: options.toJson(root: root),
    );

    final jsonOutput = _resolveFile(root, options.jsonOutputPath);
    final markdownOutput = _resolveFile(root, options.markdownOutputPath);
    await _writeText(
      jsonOutput,
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    );
    await _writeText(markdownOutput, _buildMarkdown(manifest));

    final summary = Map<String, dynamic>.from(manifest['summary']! as Map);
    emit(
      'Generated ${summary['pairCount']} pairs '
      '(${summary['blockedPairCount']} blocked): '
      '${jsonOutput.path}, ${markdownOutput.path}',
    );
    return 0;
  } on FileSystemException catch (error) {
    stderr.writeln('File operation failed: ${error.message} (${error.path})');
    return 1;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    return 1;
  }
}

Future<Map<String, Object?>> generateReleaseBlockerManifest({
  required Directory root,
  required List<Map<String, dynamic>> questions,
  required List<Map<String, dynamic>> cards,
  required int expectedPairs,
  required Map<String, Object?> configuration,
}) async {
  final cardById = <String, Map<String, dynamic>>{};
  final duplicateCardIds = <String>{};

  for (var index = 0; index < cards.length; index++) {
    final card = cards[index];
    final cardId = _nonEmptyString(card['id']);
    if (cardId == null) continue;
    if (cardById.containsKey(cardId)) {
      duplicateCardIds.add(cardId);
    } else {
      cardById[cardId] = card;
    }
  }

  final questionIdCounts = <String, int>{};
  final cardReferenceCounts = <String, int>{};
  for (final question in questions) {
    final questionId = _nonEmptyString(question['id']);
    if (questionId != null) {
      questionIdCounts[questionId] = (questionIdCounts[questionId] ?? 0) + 1;
    }
    final relatedCardId = _nonEmptyString(question['relatedCardId']);
    if (relatedCardId != null) {
      cardReferenceCounts[relatedCardId] =
          (cardReferenceCounts[relatedCardId] ?? 0) + 1;
    }
  }

  final duplicateQuestionIds = questionIdCounts.entries
      .where((entry) => entry.value > 1)
      .map((entry) => entry.key)
      .toSet();
  final duplicateReferencedCardIds = cardReferenceCounts.entries
      .where((entry) => entry.value > 1)
      .map((entry) => entry.key)
      .toSet();
  final referencedCardIds = cardReferenceCounts.keys.toSet();
  final unreferencedCardIds =
      cardById.keys
          .where((cardId) => !referencedCardIds.contains(cardId))
          .toList()
        ..sort();

  final imageAggregation = await _aggregateImages(root: root, cards: cards);
  final imageByPath = <String, Map<String, Object?>>{};
  for (final entry in imageAggregation.paths) {
    imageByPath[entry['imagePath']! as String] = entry;
  }

  final pairs = <Map<String, Object?>>[];
  var matchedPairCount = 0;

  for (var index = 0; index < questions.length; index++) {
    final question = questions[index];
    final rawQuestionId = _nonEmptyString(question['id']);
    final questionId = rawQuestionId ?? 'question[$index]';
    final rawCardId = _nonEmptyString(question['relatedCardId']);
    final cardId = rawCardId ?? '<missing>';
    final card = rawCardId == null ? null : cardById[rawCardId];
    if (card != null) matchedPairCount++;

    final verified = question['verified'] == true;
    final questionReviewStatus = _reviewStatus(question);
    final cardReviewStatus = card == null ? null : _reviewStatus(card);
    final reviewStatus = _pairReviewStatus(
      questionReviewStatus,
      cardReviewStatus,
    );
    final imagePath = card == null ? null : _nonEmptyString(card['imageAsset']);
    final imageClassification = card == null
        ? 'missing'
        : (_imageClassification(card) ?? 'unknown');
    final imageInfo = imagePath == null ? null : imageByPath[imagePath];
    final blockers = <String>[];

    if (rawQuestionId == null) blockers.add('question_id_missing');
    if (rawQuestionId != null && duplicateQuestionIds.contains(rawQuestionId)) {
      blockers.add('duplicate_question_id');
    }
    if (rawCardId == null) blockers.add('card_id_missing');
    if (rawCardId != null && card == null) blockers.add('related_card_missing');
    if (rawCardId != null && duplicateCardIds.contains(rawCardId)) {
      blockers.add('duplicate_card_id');
    }
    if (rawCardId != null && duplicateReferencedCardIds.contains(rawCardId)) {
      blockers.add('duplicate_card_reference');
    }
    if (!verified) blockers.add('not_verified');
    _appendReviewBlocker(
      blockers,
      scope: 'question',
      reviewStatus: questionReviewStatus,
    );
    _appendReviewBlocker(
      blockers,
      scope: 'card',
      reviewStatus: cardReviewStatus,
    );
    if (card != null) {
      if (imagePath == null) {
        blockers.add('image_path_missing');
      } else if (imageInfo?['exists'] != true) {
        blockers.add('image_file_missing');
      }
      if (imageClassification == 'unknown') {
        blockers.add('image_classification_missing');
      } else if (imageClassification == 'generic_placeholder') {
        blockers.add('image_generic_placeholder');
      } else if (imageClassification != 'approved') {
        blockers.add('image_not_approved:$imageClassification');
      }
    }

    blockers.sort();
    pairs.add({
      'pairId': '$questionId::$cardId',
      'questionId': questionId,
      'cardId': cardId,
      'verified': verified,
      'reviewStatus': reviewStatus,
      'imagePath': imagePath,
      'imageClassification': imageClassification,
      'blockers': blockers,
    });
  }

  pairs.sort(
    (left, right) =>
        (left['pairId']! as String).compareTo(right['pairId']! as String),
  );

  final structuralBlockers = <String>[];
  if (questions.length != expectedPairs) {
    structuralBlockers.add('question_count_mismatch');
  }
  if (cards.length != expectedPairs) {
    structuralBlockers.add('card_count_mismatch');
  }
  if (matchedPairCount != expectedPairs) {
    structuralBlockers.add('matched_pair_count_mismatch');
  }
  if (duplicateQuestionIds.isNotEmpty) {
    structuralBlockers.add('duplicate_question_ids');
  }
  if (duplicateCardIds.isNotEmpty) {
    structuralBlockers.add('duplicate_card_ids');
  }
  if (duplicateReferencedCardIds.isNotEmpty) {
    structuralBlockers.add('duplicate_card_references');
  }
  if (unreferencedCardIds.isNotEmpty) {
    structuralBlockers.add('unreferenced_cards');
  }
  structuralBlockers.sort();

  final blockedPairCount = pairs
      .where((pair) => (pair['blockers']! as List).isNotEmpty)
      .length;
  final crossTabulation = _buildCrossTabulation(pairs);

  return {
    'tool': 'generate_release_blockers',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'configuration': configuration,
    'summary': {
      'expectedPairCount': expectedPairs,
      'questionCount': questions.length,
      'cardCount': cards.length,
      'pairCount': pairs.length,
      'matchedPairCount': matchedPairCount,
      'blockedPairCount': blockedPairCount,
      'unblockedPairCount': pairs.length - blockedPairCount,
      'releaseReady': blockedPairCount == 0 && structuralBlockers.isEmpty,
      'structuralBlockers': structuralBlockers,
      'duplicateQuestionIds': _sorted(duplicateQuestionIds),
      'duplicateCardIds': _sorted(duplicateCardIds),
      'duplicateReferencedCardIds': _sorted(duplicateReferencedCardIds),
      'unreferencedCardIds': unreferencedCardIds,
    },
    'crossTabulation': {
      'dimensions': ['verified', 'reviewStatus'],
      'rows': crossTabulation,
    },
    'images': {
      'referenceCount': imageAggregation.referenceCount,
      'existingReferenceCount': imageAggregation.existingReferenceCount,
      'missingReferenceCount': imageAggregation.missingReferenceCount,
      'missingPathCount': imageAggregation.missingPathCount,
      'uniquePathCount': imageAggregation.paths.length,
      'uniqueHashCount': imageAggregation.hashes.length,
      'paths': imageAggregation.paths,
      'hashes': imageAggregation.hashes,
    },
    'pairs': pairs,
  };
}

List<Map<String, Object>> _buildCrossTabulation(
  List<Map<String, Object?>> pairs,
) {
  final rows = <Map<String, Object>>[];
  for (final verified in [false, true]) {
    final row = <String, Object>{'verified': verified};
    var total = 0;
    for (final status in _reviewStatuses) {
      final count = pairs
          .where(
            (pair) =>
                pair['verified'] == verified && pair['reviewStatus'] == status,
          )
          .length;
      row[status] = count;
      total += count;
    }
    row['total'] = total;
    rows.add(row);
  }
  return rows;
}

Future<ImageAggregation> _aggregateImages({
  required Directory root,
  required List<Map<String, dynamic>> cards,
}) async {
  final referencesByPath = <String, List<Map<String, String>>>{};
  var missingPathCount = 0;

  for (var index = 0; index < cards.length; index++) {
    final card = cards[index];
    final cardId = _nonEmptyString(card['id']) ?? 'card[$index]';
    final imagePath = _nonEmptyString(card['imageAsset']);
    if (imagePath == null) {
      missingPathCount++;
      continue;
    }
    referencesByPath.putIfAbsent(imagePath, () => []).add({
      'cardId': cardId,
      'imageClassification': _imageClassification(card) ?? 'unknown',
    });
  }

  final paths = <Map<String, Object?>>[];
  final sortedPaths = referencesByPath.keys.toList()..sort();
  for (final imagePath in sortedPaths) {
    final file = _resolveFile(root, imagePath);
    final exists = file.existsSync();
    String? hash;
    int? sizeBytes;
    if (exists) {
      final bytes = await file.readAsBytes();
      hash = sha256.convert(bytes).toString();
      sizeBytes = bytes.length;
    }
    final references = referencesByPath[imagePath]!;
    final cardIds = references.map((reference) => reference['cardId']!).toList()
      ..sort();
    final classifications =
        references
            .map((reference) => reference['imageClassification']!)
            .toSet()
            .toList()
          ..sort();
    paths.add({
      'imagePath': imagePath,
      'exists': exists,
      'sha256': hash,
      'sizeBytes': sizeBytes,
      'referenceCount': references.length,
      'cardIds': cardIds,
      'imageClassifications': classifications,
    });
  }

  final pathsByHash = <String, List<Map<String, Object?>>>{};
  for (final path in paths) {
    final hash = path['sha256'];
    if (hash is String) {
      pathsByHash.putIfAbsent(hash, () => []).add(path);
    }
  }

  final hashes = <Map<String, Object?>>[];
  final sortedHashes = pathsByHash.keys.toList()..sort();
  for (final hash in sortedHashes) {
    final matchingPaths = pathsByHash[hash]!;
    final imagePaths =
        matchingPaths.map((path) => path['imagePath']! as String).toList()
          ..sort();
    final cardIds =
        matchingPaths
            .expand((path) => (path['cardIds']! as List).cast<String>())
            .toSet()
            .toList()
          ..sort();
    final classifications =
        matchingPaths
            .expand(
              (path) => (path['imageClassifications']! as List).cast<String>(),
            )
            .toSet()
            .toList()
          ..sort();
    final referenceCount = matchingPaths.fold<int>(
      0,
      (sum, path) => sum + (path['referenceCount']! as int),
    );
    hashes.add({
      'sha256': hash,
      'uniquePathCount': imagePaths.length,
      'referenceCount': referenceCount,
      'imagePaths': imagePaths,
      'cardIds': cardIds,
      'imageClassifications': classifications,
    });
  }

  final referenceCount = referencesByPath.values.fold<int>(
    0,
    (sum, references) => sum + references.length,
  );
  final existingReferenceCount = paths
      .where((path) => path['exists'] == true)
      .fold<int>(0, (sum, path) => sum + (path['referenceCount']! as int));

  return ImageAggregation(
    referenceCount: referenceCount,
    existingReferenceCount: existingReferenceCount,
    missingReferenceCount: referenceCount - existingReferenceCount,
    missingPathCount: missingPathCount,
    paths: paths,
    hashes: hashes,
  );
}

String _buildMarkdown(Map<String, Object?> manifest) {
  final summary = Map<String, dynamic>.from(manifest['summary']! as Map);
  final crossTabulation = Map<String, dynamic>.from(
    manifest['crossTabulation']! as Map,
  );
  final images = Map<String, dynamic>.from(manifest['images']! as Map);
  final pairs = (manifest['pairs']! as List).cast<Map<String, Object?>>();
  final buffer = StringBuffer()
    ..writeln('# Release Blocker Manifest')
    ..writeln()
    ..writeln('- Generated at: `${manifest['generatedAt']}`')
    ..writeln('- Release ready: `${summary['releaseReady']}`')
    ..writeln()
    ..writeln('## Summary')
    ..writeln()
    ..writeln('| Metric | Count |')
    ..writeln('|---|---:|')
    ..writeln('| Expected pairs | ${summary['expectedPairCount']} |')
    ..writeln('| Questions | ${summary['questionCount']} |')
    ..writeln('| Cards | ${summary['cardCount']} |')
    ..writeln('| Matched pairs | ${summary['matchedPairCount']} |')
    ..writeln('| Blocked pairs | ${summary['blockedPairCount']} |')
    ..writeln('| Unblocked pairs | ${summary['unblockedPairCount']} |')
    ..writeln()
    ..writeln(
      '**Structural blockers:** '
      '${_inlineList((summary['structuralBlockers']! as List).cast<Object?>())}',
    )
    ..writeln()
    ..writeln('## verified × reviewStatus')
    ..writeln()
    ..writeln('| verified | approved | pending | correction_required | total |')
    ..writeln('|---|---:|---:|---:|---:|');

  for (final rawRow in crossTabulation['rows']! as List) {
    final row = Map<String, dynamic>.from(rawRow as Map);
    buffer.writeln(
      '| ${row['verified']} | ${row['approved']} | ${row['pending']} | '
      '${row['correction_required']} | ${row['total']} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Image summary')
    ..writeln()
    ..writeln('| Metric | Count |')
    ..writeln('|---|---:|')
    ..writeln('| Image references | ${images['referenceCount']} |')
    ..writeln('| Existing references | ${images['existingReferenceCount']} |')
    ..writeln('| Missing references | ${images['missingReferenceCount']} |')
    ..writeln('| Missing image paths | ${images['missingPathCount']} |')
    ..writeln('| Unique paths | ${images['uniquePathCount']} |')
    ..writeln('| Unique SHA-256 hashes | ${images['uniqueHashCount']} |')
    ..writeln()
    ..writeln('### Hash aggregation')
    ..writeln()
    ..writeln(
      '| SHA-256 | Unique paths | References | Classifications | Paths |',
    )
    ..writeln('|---|---:|---:|---|---|');

  for (final rawHash in images['hashes']! as List) {
    final hash = Map<String, dynamic>.from(rawHash as Map);
    buffer.writeln(
      '| `${hash['sha256']}` | ${hash['uniquePathCount']} | '
      '${hash['referenceCount']} | '
      '${_markdownList(hash['imageClassifications']! as List)} | '
      '${_markdownList(hash['imagePaths']! as List)} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('### Path aggregation')
    ..writeln()
    ..writeln(
      '| Image path | Exists | SHA-256 | Bytes | References | Classification |',
    )
    ..writeln('|---|---|---|---:|---:|---|');

  for (final rawPath in images['paths']! as List) {
    final path = Map<String, dynamic>.from(rawPath as Map);
    final hash = path['sha256'] == null ? '—' : '`${path['sha256']}`';
    buffer.writeln(
      '| `${_escapeMarkdown(path['imagePath'])}` | ${path['exists']} | $hash | '
      '${path['sizeBytes'] ?? '—'} | ${path['referenceCount']} | '
      '${_markdownList(path['imageClassifications']! as List)} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Pair blockers')
    ..writeln()
    ..writeln(
      '| pairId | questionId | cardId | verified | reviewStatus | imagePath | '
      'imageClassification | blockers |',
    )
    ..writeln('|---|---|---|---|---|---|---|---|');

  for (final pair in pairs) {
    buffer.writeln(
      '| `${_escapeMarkdown(pair['pairId'])}` | '
      '`${_escapeMarkdown(pair['questionId'])}` | '
      '`${_escapeMarkdown(pair['cardId'])}` | '
      '${pair['verified']} | ${pair['reviewStatus']} | '
      '${pair['imagePath'] == null ? '—' : '`${_escapeMarkdown(pair['imagePath'])}`'} | '
      '${pair['imageClassification']} | '
      '${_markdownList(pair['blockers']! as List)} |',
    );
  }

  return buffer.toString();
}

void _appendReviewBlocker(
  List<String> blockers, {
  required String scope,
  required String? reviewStatus,
}) {
  if (reviewStatus == 'approved') return;
  if (reviewStatus == null) {
    blockers.add('${scope}_review_status_missing');
  } else if (_reviewStatuses.contains(reviewStatus)) {
    blockers.add('${scope}_review_$reviewStatus');
  } else {
    blockers.add('${scope}_review_unknown:$reviewStatus');
  }
}

String _pairReviewStatus(String? questionStatus, String? cardStatus) {
  if (questionStatus == 'approved' && cardStatus == 'approved') {
    return 'approved';
  }
  if (questionStatus == 'correction_required' ||
      cardStatus == 'correction_required') {
    return 'correction_required';
  }
  return 'pending';
}

String? _reviewStatus(Map<String, dynamic> record) {
  final source = record['source'];
  if (source is! Map) return null;
  return _nonEmptyString(source['reviewStatus']);
}

String? _imageClassification(Map<String, dynamic> card) {
  final imageReview = card['imageReview'];
  if (imageReview is! Map) return null;
  return _nonEmptyString(imageReview['status']);
}

Future<List<Map<String, dynamic>>> _readObjectList(
  File file, {
  required String label,
}) async {
  if (!file.existsSync()) {
    throw FileSystemException('$label file is missing', file.path);
  }
  final source = await file.readAsString();
  dynamic decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    throw FormatException('$label contains invalid JSON: ${error.message}');
  }
  if (decoded is! List) {
    throw FormatException('$label JSON root must be an array.');
  }
  final result = <Map<String, dynamic>>[];
  for (var index = 0; index < decoded.length; index++) {
    final value = decoded[index];
    if (value is! Map) {
      throw FormatException('$label[$index] must be an object.');
    }
    result.add(Map<String, dynamic>.from(value));
  }
  return result;
}

Future<void> _writeText(File file, String content) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
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

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

List<String> _sorted(Iterable<String> values) {
  final result = values.toList()..sort();
  return result;
}

String _inlineList(List<Object?> values) {
  if (values.isEmpty) return 'none';
  return values.map((value) => '`$value`').join(', ');
}

String _markdownList(List<dynamic> values) {
  if (values.isEmpty) return '—';
  return values.map((value) => '`${_escapeMarkdown(value)}`').join('<br>');
}

String _escapeMarkdown(Object? value) {
  return '$value'.replaceAll('|', r'\|').replaceAll('\n', ' ');
}

class ReleaseBlockerOptions {
  static const usage =
      'dart run tool/generate_release_blockers.dart '
      '[--root PATH] [--questions PATH] [--cards PATH] '
      '[--expected-pairs COUNT] [--json-output PATH] '
      '[--markdown-output PATH]';

  final String root;
  final String questionsPath;
  final String cardsPath;
  final int expectedPairs;
  final String jsonOutputPath;
  final String markdownOutputPath;

  const ReleaseBlockerOptions({
    required this.root,
    required this.questionsPath,
    required this.cardsPath,
    required this.expectedPairs,
    required this.jsonOutputPath,
    required this.markdownOutputPath,
  });

  static ReleaseBlockerOptions parse(List<String> arguments) {
    var root = '.';
    var questionsPath = 'assets/data/questions.json';
    var cardsPath = 'assets/data/cards.json';
    var expectedPairs = 103;
    var jsonOutputPath = 'build/release-blockers.json';
    var markdownOutputPath = 'build/release-blockers.md';

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') {
        throw const FormatException(usage);
      }
      const optionsWithValues = {
        '--root',
        '--questions',
        '--cards',
        '--expected-pairs',
        '--json-output',
        '--markdown-output',
      };
      if (!optionsWithValues.contains(argument)) {
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
        case '--json-output':
          jsonOutputPath = value;
          break;
        case '--markdown-output':
          markdownOutputPath = value;
          break;
      }
    }

    return ReleaseBlockerOptions(
      root: root,
      questionsPath: questionsPath,
      cardsPath: cardsPath,
      expectedPairs: expectedPairs,
      jsonOutputPath: jsonOutputPath,
      markdownOutputPath: markdownOutputPath,
    );
  }

  Map<String, Object?> toJson({required Directory root}) => {
    'root': root.path,
    'questionsPath': questionsPath,
    'cardsPath': cardsPath,
    'expectedPairs': expectedPairs,
    'jsonOutputPath': jsonOutputPath,
    'markdownOutputPath': markdownOutputPath,
  };
}

class ImageAggregation {
  final int referenceCount;
  final int existingReferenceCount;
  final int missingReferenceCount;
  final int missingPathCount;
  final List<Map<String, Object?>> paths;
  final List<Map<String, Object?>> hashes;

  const ImageAggregation({
    required this.referenceCount,
    required this.existingReferenceCount,
    required this.missingReferenceCount,
    required this.missingPathCount,
    required this.paths,
    required this.hashes,
  });
}
