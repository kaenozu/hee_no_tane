import 'dart:io';

/// Replaces a related set of generated text files as one rollback-safe unit.
///
/// Each replacement is first written to a sibling temporary file. Existing
/// targets are moved to sibling backups before any replacement is installed.
/// If an installation fails, every target is restored to its original state.
class AtomicGeneratedFilesWriter {
  const AtomicGeneratedFilesWriter._();

  static void write(
    Map<String, String> files, {
    void Function(int index, File target)? beforeInstall,
  }) {
    if (files.isEmpty) return;

    final token = '${pid}_${DateTime.now().microsecondsSinceEpoch}';
    final staged = <File, File>{};
    final backups = <File, File>{};
    final installed = <File>[];
    var committed = false;

    try {
      for (final entry in files.entries) {
        final target = File(entry.key);
        target.parent.createSync(recursive: true);
        final temporary = File('${target.path}.tmp.$token');
        temporary.writeAsStringSync(entry.value, flush: true);
        staged[target] = temporary;
      }

      for (final target in staged.keys) {
        if (!target.existsSync()) continue;
        final backup = File('${target.path}.bak.$token');
        target.renameSync(backup.path);
        backups[target] = backup;
      }

      var index = 0;
      for (final entry in staged.entries) {
        beforeInstall?.call(index, entry.key);
        entry.value.renameSync(entry.key.path);
        installed.add(entry.key);
        index += 1;
      }

      committed = true;
    } catch (_) {
      for (final target in installed.reversed) {
        if (target.existsSync()) target.deleteSync();
      }
      for (final entry in backups.entries) {
        if (entry.key.existsSync()) entry.key.deleteSync();
        if (entry.value.existsSync()) {
          entry.value.renameSync(entry.key.path);
        }
      }
      rethrow;
    } finally {
      for (final temporary in staged.values) {
        if (temporary.existsSync()) temporary.deleteSync();
      }
      if (committed) {
        for (final backup in backups.values) {
          if (backup.existsSync()) backup.deleteSync();
        }
      }
    }
  }
}
