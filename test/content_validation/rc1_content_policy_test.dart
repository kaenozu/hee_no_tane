import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

void main() {
  group('Rc1ContentPolicy', () {
    late ContentBundle editorialBundle;

    setUpAll(() {
      final raw = File('assets/data/content_bundle.json').readAsStringSync();
      final decoded = jsonDecode(raw);
      final bundleJson = Map<String, dynamic>.from(decoded as Map);
      editorialBundle = ContentBundle.fromJson(bundleJson);
    });

    test('keeps 70 editorial pairs but exposes only the canonical 47 v1 pairs', () {
      final releaseBundle = Rc1ContentPolicy.apply(editorialBundle);

      expect(editorialBundle.entries.length, Rc1ContentPolicy.expectedSourcePairCount);
      expect(Rc1ContentPolicy.excludedQuestionIds, hasLength(23));
      expect(releaseBundle.entries.length, Rc1ContentPolicy.expectedReleasePairCount);
      expect(
        releaseBundle.entries.map((entry) => entry.question.id).toSet(),
        isNot(containsAll(Rc1ContentPolicy.excludedQuestionIds)),
      );
      expect(
        releaseBundle.entries.any(
          (entry) => Rc1ContentPolicy.excludedQuestionIds.contains(entry.question.id),
        ),
        isFalse,
      );
      expect(identical(releaseBundle, editorialBundle), isFalse);
    });

    test('fails closed when the editorial bundle is not exactly 70 pairs', () {
      final incompleteBundle = ContentBundle.create(
        contentVersion: editorialBundle.contentVersion,
        entries: editorialBundle.entries.take(69).toList(growable: false),
      );

      expect(
        () => Rc1ContentPolicy.apply(incompleteBundle),
        throwsA(isA<FormatException>()),
      );
    });

    test('the exclusion contract matches the v1.1 re-audit scope', () {
      expect(Rc1ContentPolicy.excludedQuestionIds, <String>{
        'q_daily_life_010',
        'q_food_005',
        'q_food_006',
        'q_food_009',
        'q_history_007',
        'q_language_002',
        'q_language_005',
        'q_language_009',
        'q_language_010',
        'q_living_things_008',
        'q_living_things_009',
        'q_living_things_012',
        'q_living_things_013',
        'q_living_things_015',
        'q_living_things_016',
        'q_nature_geography_009',
        'q_sci_001',
        'q_sci_002',
        'q_sci_004',
        'q_science_001',
        'q_science_002',
        'q_science_009',
        'q_science_010',
      });
    });
  });
}
