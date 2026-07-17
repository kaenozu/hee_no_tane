import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/semantic_review_gate.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

void main() {
  late ContentBundle bundle;
  late Map<String, dynamic> reviewDocument;

  setUp(() {
    bundle = ContentBundle.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File('assets/data/content_bundle.json').readAsStringSync(),
            )
            as Map,
      ),
    );
    reviewDocument = Map<String, dynamic>.from(
      jsonDecode(
            File('review/approved_semantic_reviews.json').readAsStringSync(),
          )
          as Map,
    );
  });

  test('all release pairs have current approved semantic reviews', () {
    expect(
      SemanticReviewGate.validate(
        bundle: bundle,
        reviewDocument: reviewDocument,
      ),
      isEmpty,
    );
  });

  test('stale content hash is rejected', () {
    final changed = _deepCopy(reviewDocument);
    final entries = changed['entries']! as List<dynamic>;
    final first = entries.first as Map<String, dynamic>;
    first['contentHash'] = '0' * 64;

    expect(
      SemanticReviewGate.validate(
        bundle: bundle,
        reviewDocument: changed,
      ),
      contains(contains('contentHash is stale')),
    );
  });

  test('an unchecked semantic dimension is rejected', () {
    final changed = _deepCopy(reviewDocument);
    final entries = changed['entries']! as List<dynamic>;
    final first = entries.first as Map<String, dynamic>;
    final checks = first['checks']! as Map<String, dynamic>;
    checks['cardAligned'] = false;

    expect(
      SemanticReviewGate.validate(
        bundle: bundle,
        reviewDocument: changed,
      ),
      contains(contains('required check cardAligned is not true')),
    );
  });
}

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
