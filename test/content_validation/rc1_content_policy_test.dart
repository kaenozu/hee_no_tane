import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

void main() {
  group('Rc1ContentPolicy', () {
    late ContentBundle approvedBundle;

    setUpAll(() {
      final raw = File('assets/data/content_bundle.json').readAsStringSync();
      final decoded = jsonDecode(raw);
      final bundleJson = Map<String, dynamic>.from(decoded as Map);
      approvedBundle = ContentBundle.fromJson(bundleJson);
    });

    test('exposes all 70 directly audited RC1 pairs', () {
      final releaseBundle = Rc1ContentPolicy.apply(approvedBundle);

      expect(approvedBundle.entries.length, 70);
      expect(
        releaseBundle.entries.length,
        Rc1ContentPolicy.expectedReleasePairCount,
      );
      expect(Rc1ContentPolicy.excludedQuestionIds, isEmpty);
      expect(identical(releaseBundle, approvedBundle), isTrue);
    });

    test('fails closed when an approved pair is missing', () {
      final incompleteBundle = ContentBundle.create(
        contentVersion: approvedBundle.contentVersion,
        entries: approvedBundle.entries.take(69).toList(growable: false),
      );

      expect(
        () => Rc1ContentPolicy.apply(incompleteBundle),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
