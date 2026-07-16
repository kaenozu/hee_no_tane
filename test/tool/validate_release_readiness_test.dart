import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/validate_release_readiness.dart';
import '../helpers/release_content.dart';

void main() {
  test(
    'passes when every pair is verified, approved, and has a final image',
    () async {
      final first = _pair('1');
      final second = _pair('2');
      final fixture = await _ReleaseFixture.create(
        questions: [first.question, second.question],
        cards: [first.card, second.card],
        existingImagePaths: {
          first.card['imageAsset'] as String,
          second.card['imageAsset'] as String,
        },
      );
      addTearDown(fixture.dispose);

      final invocation = await fixture.run([
        '--expected-pairs',
        '2',
        '--require-final-images',
      ]);

      expect(invocation.exitCode, 0);
      expect(invocation.report['success'], isTrue);
      expect(invocation.summary['matchedPairCount'], 2);
      expect(invocation.summary['verifiedCount'], 2);
      expect(invocation.summary['approvedPairCount'], 2);
      expect(invocation.summary['genericPlaceholderCount'], 0);
      expect(invocation.summary['missingImageCount'], 0);
    },
  );

  test('returns exit code 1 and reports every release blocker', () async {
    final pair = _pair(
      'blocked',
      verified: false,
      questionReviewStatus: 'pending',
      cardReviewStatus: 'pending',
      imageReviewStatus: 'generic_placeholder',
    );
    final fixture = await _ReleaseFixture.create(
      questions: [pair.question],
      cards: [pair.card],
    );
    addTearDown(fixture.dispose);

    final invocation = await fixture.run([
      '--expected-pairs',
      '1',
      '--require-final-images',
    ]);

    expect(invocation.exitCode, 1);
    expect(invocation.report['success'], isFalse);
    expect(invocation.check('allVerified')['passed'], isFalse);
    expect(invocation.check('allApproved')['passed'], isFalse);
    expect(invocation.check('finalImages')['passed'], isFalse);
    expect(invocation.check('imageFilesPresent')['passed'], isFalse);
    expect(invocation.summary['genericPlaceholderCount'], 1);
    expect(invocation.summary['missingImageCount'], 1);
  });

  test(
    '--require-final-images changes placeholders from audit data to failure',
    () async {
      final pair = _pair(
        'placeholder',
        imageReviewStatus: 'generic_placeholder',
      );
      final fixture = await _ReleaseFixture.create(
        questions: [pair.question],
        cards: [pair.card],
        existingImagePaths: {pair.card['imageAsset'] as String},
      );
      addTearDown(fixture.dispose);

      final auditOnly = await fixture.run(['--expected-pairs', '1']);
      final releaseGate = await fixture.run([
        '--expected-pairs',
        '1',
        '--require-final-images',
      ]);

      expect(auditOnly.exitCode, 0);
      expect(auditOnly.check('finalImages')['required'], isFalse);
      expect(auditOnly.summary['genericPlaceholderCount'], 1);

      expect(releaseGate.exitCode, 1);
      expect(releaseGate.check('finalImages')['required'], isTrue);
      expect(releaseGate.check('finalImages')['passed'], isFalse);
    },
  );

  test(
    'fails when approved metadata has a stale content fingerprint',
    () async {
      final pair = _pair('stale');
      pair.question['question'] = '承認後に変更された問題';
      final fixture = await _ReleaseFixture.create(
        questions: [pair.question],
        cards: [pair.card],
        existingImagePaths: {pair.card['imageAsset'] as String},
      );
      addTearDown(fixture.dispose);

      final invocation = await fixture.run(['--expected-pairs', '1']);

      expect(invocation.exitCode, 1);
      expect(invocation.check('allApproved')['passed'], isFalse);
      expect(invocation.summary['approvedPairCount'], 0);
    },
  );

  test('fails when the content is not an exact one-to-one pair set', () async {
    final first = _pair('duplicate_1');
    final second = _pair('duplicate_2');
    second.question['relatedCardId'] = first.card['id'];
    final fixture = await _ReleaseFixture.create(
      questions: [first.question, second.question],
      cards: [first.card, second.card],
      existingImagePaths: {
        first.card['imageAsset'] as String,
        second.card['imageAsset'] as String,
      },
    );
    addTearDown(fixture.dispose);

    final invocation = await fixture.run([
      '--expected-pairs',
      '2',
      '--require-final-images',
    ]);

    expect(invocation.exitCode, 1);
    final pairCheck = invocation.check('expectedPairs');
    expect(pairCheck['passed'], isFalse);
    expect(pairCheck['matchedPairs'], 1);
    expect(pairCheck['duplicateRelatedCardIds'], [first.card['id']]);
    expect(pairCheck['unreferencedCardIds'], [second.card['id']]);
  });

  test('invalid expected pair count returns JSON and exit code 1', () async {
    final output = StringBuffer();

    final result = await runReleaseReadiness([
      '--expected-pairs',
      '0',
    ], writeOutput: (value) => output.writeln(value));
    final report = jsonDecode(output.toString()) as Map<String, dynamic>;

    expect(result, 1);
    expect(report['success'], isFalse);
    expect(
      (report['error'] as Map<String, dynamic>)['code'],
      'invalid_arguments',
    );
  });
}

_ReleasePair _pair(
  String id, {
  bool verified = true,
  String questionReviewStatus = 'approved',
  String cardReviewStatus = 'approved',
  String imageReviewStatus = 'approved',
}) {
  final content = releaseContentPair(
    id: id,
    imageAsset: 'assets/images/cards/card_$id.png',
  );
  final question = Map<String, dynamic>.from(content.question.toJson());
  final card = Map<String, dynamic>.from(content.card.toJson());

  question['verified'] = verified;
  final questionSource = Map<String, dynamic>.from(question['source'] as Map);
  questionSource['reviewStatus'] = questionReviewStatus;
  if (questionReviewStatus != 'approved') questionSource.remove('contentHash');
  question['source'] = questionSource;

  final cardSource = Map<String, dynamic>.from(card['source'] as Map);
  cardSource['reviewStatus'] = cardReviewStatus;
  if (cardReviewStatus != 'approved') cardSource.remove('contentHash');
  card['source'] = cardSource;

  card['imageReview'] = <String, dynamic>{
    'status': imageReviewStatus,
    'reviewedAt': '2026-07-16',
    'note': 'テスト確認',
  };
  return _ReleasePair(question: question, card: card);
}

class _ReleasePair {
  final Map<String, dynamic> question;
  final Map<String, dynamic> card;

  const _ReleasePair({required this.question, required this.card});
}

class _ReleaseFixture {
  final Directory root;

  const _ReleaseFixture(this.root);

  static Future<_ReleaseFixture> create({
    required List<Map<String, dynamic>> questions,
    required List<Map<String, dynamic>> cards,
    Set<String> existingImagePaths = const {},
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'validate_release_readiness_',
    );
    final dataDirectory = Directory('${root.path}/assets/data');
    await dataDirectory.create(recursive: true);
    await File(
      '${dataDirectory.path}/questions.json',
    ).writeAsString(jsonEncode(questions));
    await File(
      '${dataDirectory.path}/cards.json',
    ).writeAsString(jsonEncode(cards));
    for (final relativePath in existingImagePaths) {
      final file = File('${root.path}/$relativePath');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([0, 1, 2]);
    }
    return _ReleaseFixture(root);
  }

  Future<_InvocationResult> run(List<String> arguments) async {
    final output = StringBuffer();
    final exitCode = await runReleaseReadiness([
      '--root',
      root.path,
      ...arguments,
    ], writeOutput: (value) => output.writeln(value));
    return _InvocationResult(
      exitCode: exitCode,
      report: jsonDecode(output.toString()) as Map<String, dynamic>,
    );
  }

  Future<void> dispose() => root.delete(recursive: true);
}

class _InvocationResult {
  final int exitCode;
  final Map<String, dynamic> report;

  const _InvocationResult({required this.exitCode, required this.report});

  Map<String, dynamic> get summary => report['summary'] as Map<String, dynamic>;

  Map<String, dynamic> check(String name) {
    final checks = report['checks'] as Map<String, dynamic>;
    return checks[name] as Map<String, dynamic>;
  }
}
