import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

const _bundlePath = 'assets/data/content_bundle.json';

void main() {
  try {
    final decoded = jsonDecode(File(_bundlePath).readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Content bundle root must be an object.');
    }

    final editorialBundle = ContentBundle.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    final releaseBundle = Rc1ContentPolicy.apply(editorialBundle);

    if (Rc1ContentPolicy.excludedQuestionIds.length != 23) {
      throw FormatException(
        'v1.0 must keep exactly 23 v1.1 re-audit pairs outside runtime, got '
        '${Rc1ContentPolicy.excludedQuestionIds.length}.',
      );
    }
    if (releaseBundle.entries.length != Rc1ContentPolicy.expectedReleasePairCount) {
      throw FormatException(
        'v1.0 runtime pair count mismatch: expected '
        '${Rc1ContentPolicy.expectedReleasePairCount}, got '
        '${releaseBundle.entries.length}.',
      );
    }

    stdout.writeln(
      'RC1 content boundary passed: '
      '${editorialBundle.entries.length} editorial pairs, '
      '${releaseBundle.entries.length} audited v1.0 runtime pairs, '
      '${Rc1ContentPolicy.excludedQuestionIds.length} deferred to v1.1 re-audit.',
    );
  } on Object catch (error, stackTrace) {
    stderr.writeln('RC1 content boundary failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
