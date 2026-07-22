import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/semantic_review_gate.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

const _bundlePath = 'assets/data/content_bundle.json';
const _reviewPath = 'review/approved_semantic_reviews.json';

void main() {
  try {
    final bundleValue = jsonDecode(File(_bundlePath).readAsStringSync());
    final reviewValue = jsonDecode(File(_reviewPath).readAsStringSync());
    if (bundleValue is! Map) {
      throw const FormatException('Content bundle root must be an object.');
    }
    if (reviewValue is! Map) {
      throw const FormatException('Semantic review root must be an object.');
    }

    final bundle = ContentBundle.fromJson(
      Map<String, dynamic>.from(bundleValue),
    );
    SemanticReviewGate.validateOrThrow(
      bundle: bundle,
      reviewDocument: Map<String, dynamic>.from(reviewValue),
    );

    stdout.writeln(
      'Semantic reviews are current for ${bundle.entries.length} approved pairs '
      '(${bundle.bundleHash}).',
    );
  } on Object catch (error, stackTrace) {
    stderr.writeln(error);
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
