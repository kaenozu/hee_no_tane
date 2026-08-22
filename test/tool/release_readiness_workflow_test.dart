import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release candidate workflow cannot skip blocking readiness gate', () {
    final workflow = File(
      '.github/workflows/release-readiness.yml',
    ).readAsStringSync();

    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains("tags:\n      - 'v*'"));
    expect(workflow, contains('release-readiness:\n    name: Blocking release readiness'));
    expect(
      workflow,
      contains('dart run tool/validate_release_readiness.dart --require-final-images'),
    );
    expect(workflow, contains('set -o pipefail'));

    final jobBlock = workflow.split('release-readiness:', 2)[1];
    final firstStep = jobBlock.indexOf('steps:');
    expect(firstStep, greaterThan(0));
    expect(jobBlock.substring(0, firstStep), isNot(contains('\n    if:')));
  });

  test('release evidence is uploaded even when blocking gate fails', () {
    final workflow = File(
      '.github/workflows/release-readiness.yml',
    ).readAsStringSync();

    expect(workflow, contains('- name: Upload release evidence'));
    expect(workflow, contains('if: always()'));
    expect(workflow, contains('build/release-blockers.json'));
    expect(workflow, contains('build/release-readiness.json'));
  });
}
