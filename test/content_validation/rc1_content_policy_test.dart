import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

void main() {
  group('Rc1ContentPolicy', () {
    late ContentBundle approvedBundle;

    setUpAll(() {
      final decoded = jsonDecode(
        File('assets/data/content_bundle.json').readAsStringSync(),
      );
      approvedBundle = ContentBundle.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
    });

    test('keeps approved source data but exposes exactly 47 RC1 pairs', () {
      expect(approvedBundle.entries.length, 70);

      final releaseBundle = Rc1ContentPolicy.apply(approvedBundle);

      expect(
        releaseBundle.entries.length,
        Rc1ContentPolicy.expectedReleasePairCount,
      );
      expect(Rc1ContentPolicy.excludedQuestionIds.length, 23);
    });

    test('removes every temporarily excluded question', () {
      final releaseBundle = Rc1ContentPolicy.apply(approvedBundle);
      final releaseQuestionIds = <String>{
        for (final entry in releaseBundle.entries) entry.question.id,
      };

      expect(
        releaseQuestionIds.intersection(
          Rc1ContentPolicy.excludedQuestionIds,
        ),
        isEmpty,
      );
    });
  });
}
