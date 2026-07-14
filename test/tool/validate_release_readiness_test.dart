import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/validate_release_readiness.dart';

void main() {
  test('passes when every pair is verified, approved, and has a final image', () async {
    final fixture = await _ReleaseFixture.create(
      questions: [
        _question(id: 'q1', cardId: 'c1'),
        _question(id: 'q2', cardId: 'c2'),
      ],
      cards: [
        _card(id: 'c1'),
        _card(id: 'c2'),
      ],
      existingImageIds: {'c1', 'c2'},
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
  });

  test('returns exit code 1 and reports every release blocker', () async {
    final fixture = await _ReleaseFixture.create(
      questions: [
        _question(
          id: 'q1',
          cardId: 'c1',
          verified: false,
          reviewStatus: 'pending',
        ),
      ],
      cards: [
        _card(
          id: 'c1',
          reviewStatus: 'pending',
          imageReviewStatus: 'generic_placeholder',
        ),
      ],
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

  test('--require-final-images changes placeholders from audit data to failure', () async {
    final fixture = await _ReleaseFixture.create(
      questions: [_question(id: 'q1', cardId: 'c1')],
      cards: [
        _card(id: 'c1', imageReviewStatus: 'generic_placeholder'),
      ],
      existingImageIds: {'c1'},
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
  });

  test('fails when the content is not an exact one-to-one pair set', () async {
    final fixture = await _ReleaseFixture.create(
      questions: [
        _question(id: 'q1', cardId: 'c1'),
        _question(id: 'q2', cardId: 'c1'),
      ],
      cards: [
        _card(id: 'c1'),
        _card(id: 'c2'),
      ],
      existingImageIds: {'c1', 'c2'},
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
    expect(pairCheck['duplicateRelatedCardIds'], ['c1']);
    expect(pairCheck['unreferencedCardIds'], ['c2']);
  });

  test('invalid expected pair count returns JSON and exit code 1', () async {
    final output = StringBuffer();

    final result = await runReleaseReadiness(
      ['--expected-pairs', '0'],
      writeOutput: (value) => output.writeln(value),
    );
    final report = jsonDecode(output.toString()) as Map<String, dynamic>;

    expect(result, 1);
    expect(report['success'], isFalse);
    expect((report['error'] as Map<String, dynamic>)['code'], 'invalid_arguments');
  });
}

Map<String, Object?> _question({
  required String id,
  required String cardId,
  bool verified = true,
  String reviewStatus = 'approved',
}) {
  return {
    'id': id,
    'relatedCardId': cardId,
    'verified': verified,
    'source': {'reviewStatus': reviewStatus},
  };
}

Map<String, Object?> _card({
  required String id,
  String reviewStatus = 'approved',
  String imageReviewStatus = 'approved',
}) {
  return {
    'id': id,
    'imageAsset': 'assets/images/cards/$id.png',
    'source': {'reviewStatus': reviewStatus},
    'imageReview': {'status': imageReviewStatus},
  };
}

class _ReleaseFixture {
  final Directory root;

  const _ReleaseFixture(this.root);

  static Future<_ReleaseFixture> create({
    required List<Map<String, Object?>> questions,
    required List<Map<String, Object?>> cards,
    Set<String> existingImageIds = const {},
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'validate_release_readiness_',
    );
    final dataDirectory = Directory('${root.path}/assets/data');
    final imageDirectory = Directory('${root.path}/assets/images/cards');
    await dataDirectory.create(recursive: true);
    await imageDirectory.create(recursive: true);
    await File('${dataDirectory.path}/questions.json').writeAsString(
      jsonEncode(questions),
    );
    await File('${dataDirectory.path}/cards.json').writeAsString(
      jsonEncode(cards),
    );
    for (final id in existingImageIds) {
      await File('${imageDirectory.path}/$id.png').writeAsBytes([0, 1, 2]);
    }
    return _ReleaseFixture(root);
  }

  Future<_InvocationResult> run(List<String> arguments) async {
    final output = StringBuffer();
    final exitCode = await runReleaseReadiness(
      ['--root', root.path, ...arguments],
      writeOutput: (value) => output.writeln(value),
    );
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

  Map<String, dynamic> get summary =>
      report['summary'] as Map<String, dynamic>;

  Map<String, dynamic> check(String name) {
    final checks = report['checks'] as Map<String, dynamic>;
    return checks[name] as Map<String, dynamic>;
  }
}
