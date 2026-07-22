import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/atomic_generated_files_writer.dart';

void main() {
  test('installs all generated files and removes transaction artifacts', () {
    final directory = Directory.systemTemp.createTempSync('atomic-writer-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final bundle = File('${directory.path}/content_bundle.json')
      ..writeAsStringSync('old bundle');
    final manifest = File('${directory.path}/content_manifest.json')
      ..writeAsStringSync('old manifest');

    AtomicGeneratedFilesWriter.write(<String, String>{
      bundle.path: 'new bundle',
      manifest.path: 'new manifest',
    });

    expect(bundle.readAsStringSync(), 'new bundle');
    expect(manifest.readAsStringSync(), 'new manifest');
    expect(
      directory.listSync().where((entry) {
        return entry.path.contains('.tmp.') || entry.path.contains('.bak.');
      }),
      isEmpty,
    );
  });

  test('restores every original file when a later install fails', () {
    final directory = Directory.systemTemp.createTempSync('atomic-rollback-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final bundle = File('${directory.path}/content_bundle.json')
      ..writeAsStringSync('old bundle');
    final manifest = File('${directory.path}/content_manifest.json')
      ..writeAsStringSync('old manifest');

    expect(
      () => AtomicGeneratedFilesWriter.write(
        <String, String>{
          bundle.path: 'new bundle',
          manifest.path: 'new manifest',
        },
        beforeInstall: (index, _) {
          if (index == 1) throw StateError('simulated install failure');
        },
      ),
      throwsStateError,
    );

    expect(bundle.readAsStringSync(), 'old bundle');
    expect(manifest.readAsStringSync(), 'old manifest');
    expect(
      directory.listSync().where((entry) {
        return entry.path.contains('.tmp.') || entry.path.contains('.bak.');
      }),
      isEmpty,
    );
  });
}
