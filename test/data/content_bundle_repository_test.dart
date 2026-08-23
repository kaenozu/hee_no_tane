import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
import 'package:hee_no_tane_app/data/repositories/content_bundle_repository.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentBundle sourceBundle;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/data/content_bundle.json');
    sourceBundle = ContentBundle.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  });

  test(
    'excludes a non-playable pair before validating the release bundle',
    () async {
      final excludedId = Rc1TestData.excludedQuestionId(sourceBundle);
      final bundle = Rc1TestData.withNonPlayableQuestion(
        sourceBundle,
        excludedId,
      );

      final loaded = await _loadBundle(bundle);

      expect(loaded.entries, hasLength(47));
      expect(
        loaded.entries.any((entry) => entry.question.id == excludedId),
        isFalse,
      );
    },
  );

  test('rejects a non-playable pair that is not excluded', () async {
    final nonExcludedId = Rc1TestData.nonExcludedQuestionId(sourceBundle);
    final bundle = Rc1TestData.withNonPlayableQuestion(
      sourceBundle,
      nonExcludedId,
    );

    await expectLater(
      _loadBundle(bundle),
      throwsA(isA<ContentBundleLoadException>()),
    );
  });
}

Future<ContentBundle> _loadBundle(ContentBundle bundle) {
  return ContentBundleRepository(
    assetBundle: _StringAssetBundle(jsonEncode(bundle.toJson())),
  ).load();
}

class _StringAssetBundle extends AssetBundle {
  _StringAssetBundle(this.value);

  final String value;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }
}

class Rc1TestData {
  static String excludedQuestionId(ContentBundle bundle) => bundle.entries
      .map((entry) => entry.question.id)
      .firstWhere((id) => Rc1ContentPolicy.excludedQuestionIds.contains(id));

  static String nonExcludedQuestionId(ContentBundle bundle) => bundle.entries
      .map((entry) => entry.question.id)
      .firstWhere((id) => !Rc1ContentPolicy.excludedQuestionIds.contains(id));

  static ContentBundle withNonPlayableQuestion(
    ContentBundle bundle,
    String questionId,
  ) {
    final entries = bundle.entries
        .map((entry) {
          if (entry.question.id != questionId) return entry;

          final question = entry.question;
          return ContentBundleEntry(
            question: Question(
              id: question.id,
              category: question.category,
              difficulty: question.difficulty,
              question: question.question,
              choices: question.choices,
              answerIndex: question.answerIndex,
              explanation: question.explanation,
              relatedCardId: question.relatedCardId,
              sourceNote: question.legacySourceNote,
              verified: false,
              sourceMetadata: question.sourceMetadata,
            ),
            card: entry.card,
          );
        })
        .toList(growable: false);

    return ContentBundle.create(
      contentVersion: bundle.contentVersion,
      entries: entries,
    );
  }
}
