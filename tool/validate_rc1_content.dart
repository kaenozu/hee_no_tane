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

    final approvedBundle = ContentBundle.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    final releaseBundle = Rc1ContentPolicy.apply(approvedBundle);

    if (Rc1ContentPolicy.excludedQuestionIds.isNotEmpty) {
      throw const FormatException(
        'RC1 must not keep temporary source-audit exclusions.',
      );
    }

    stdout.writeln(
      'RC1 content boundary passed: '
      '${approvedBundle.entries.length} approved pairs, '
      '${releaseBundle.entries.length} directly audited release pairs.',
    );
  } on Object catch (error, stackTrace) {
    stderr.writeln('RC1 content boundary failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
