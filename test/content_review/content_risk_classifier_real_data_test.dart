import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_risk_classifier.dart';

void main() {
  const classifier = ContentRiskClassifier();
  late Map<String, ContentRiskRecord> risksByQuestionId;

  setUpAll(() {
    final risks = classifier.risks(
      questionsJson: _projectFile(
        'assets/data/questions.json',
      ).readAsStringSync(),
      cardsJson: _projectFile('assets/data/cards.json').readAsStringSync(),
    );
    risksByQuestionId = {for (final risk in risks) risk.questionId: risk};
  });

  List<String> duplicateIds(String questionId) =>
      risksByQuestionId[questionId]?.duplicateQuestionIds ?? const <String>[];

  Set<String> duplicateEdges() {
    final edges = <String>{};
    for (final entry in risksByQuestionId.entries) {
      for (final duplicateId in entry.value.duplicateQuestionIds) {
        final ids = <String>[entry.key, duplicateId]..sort();
        edges.add('${ids.first}|${ids.last}');
      }
    }
    return edges;
  }

  test('known duplicate groups are resolved in project data', () {
    const cleanedIds = <String>[
      'q_bio_003',
      'q_living_things_006',
      'q_living_things_008',
      'q_food_005',
      'q_food_011',
      'q_food_006',
      'q_lang_003',
    ];

    for (final id in cleanedIds) {
      expect(
        duplicateIds(id),
        isEmpty,
        reason: '$id must not remain connected to a duplicate fact',
      );
    }
  });

  test('real project data has no duplicate fact edges after cleanup', () {
    expect(duplicateEdges(), isEmpty);
  });
}

File _projectFile(String relativePath) {
  final startDirectories = <Directory>{
    Directory.current.absolute,
    if (Platform.script.scheme == 'file')
      File.fromUri(Platform.script).parent.absolute,
  };
  final searchedPaths = <String>[];

  for (final startDirectory in startDirectories) {
    var directory = startDirectory;
    while (true) {
      final candidate = File('${directory.path}/$relativePath');
      searchedPaths.add(candidate.path);
      if (candidate.existsSync()) return candidate;

      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
  }

  throw StateError(
    'Unable to locate $relativePath. Searched: ${searchedPaths.join(', ')}',
  );
}
