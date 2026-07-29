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

    final excludedInRelease = releaseBundle.entries
        .where(
          (entry) => Rc1ContentPolicy.excludedQuestionIds.contains(
            entry.question.id,
          ),
        )
        .map((entry) => entry.question.id)
        .toList(growable: false);
    if (excludedInRelease.isNotEmpty) {
      throw FormatException(
        'RC1 release still contains excluded questions: '
        '${excludedInRelease.join(', ')}.',
      );
    }

    stdout.writeln(
      'RC1 content boundary passed: '
      '${approvedBundle.entries.length} approved pairs, '
      '${releaseBundle.entries.length} release pairs, '
      '${Rc1ContentPolicy.excludedQuestionIds.length} temporarily excluded.',
    );
  } on Object catch (error, stackTrace) {
    stderr.writeln('RC1 content boundary failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
