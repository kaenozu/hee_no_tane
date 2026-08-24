import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

const _bundlePath = 'assets/data/content_bundle.json';
const _manifestPath = 'assets/data/content_manifest.json';
const _appVersionPath = 'assets/data/app_version.json';

void main() {
  final issues = <String>[];
  final pubspec = _readFile('pubspec.yaml', issues);

  _requireContains(
    pubspec,
    '- assets/data/content_bundle.json',
    'pubspec must bundle the approved runtime content bundle',
    issues,
  );
  for (final sourceAsset in <String>[
    '- assets/data/questions.json',
    '- assets/data/cards.json',
    '- assets/data/content_manifest.json',
  ]) {
    if (pubspec.contains(sourceAsset)) {
      issues.add('pubspec must not ship editing source asset: $sourceAsset');
    }
  }

  ContentBundle? bundle;
  final bundleRaw = _readFile(_bundlePath, issues);
  if (bundleRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(bundleRaw);
      if (decoded is! Map) {
        issues.add('$_bundlePath root must be an object');
      } else {
        bundle = ContentBundle.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on Object catch (error) {
      issues.add('$_bundlePath is invalid: $error');
    }
  }

  final manifest = _readJsonObject(_manifestPath, issues);
  final appVersion = _readJsonObject(_appVersionPath, issues);
  if (bundle != null) {
    final expectedContentVersion =
        '${appVersion['version']}+${appVersion['buildNumber']}';
    if (bundle.contentVersion != expectedContentVersion) {
      issues.add(
        'bundle contentVersion must match app version $expectedContentVersion',
      );
    }
    if (manifest['playableQuestionCount'] != bundle.entries.length) {
      issues.add('manifest playableQuestionCount must match bundle entryCount');
    }
    if (manifest['contentVersion'] != bundle.contentVersion) {
      issues.add('manifest contentVersion must match bundle contentVersion');
    }
    if (manifest['bundleHash'] != bundle.bundleHash) {
      issues.add('manifest bundleHash must match bundle bundleHash');
    }

    for (final entry in bundle.entries) {
      final imageAsset = entry.card.imageAsset;
      if (imageAsset.isEmpty || !File(imageAsset).existsSync()) {
        issues.add(
          'runtime bundle image is missing for ${entry.card.id}: $imageAsset',
        );
      }
    }
  }

  if (issues.isNotEmpty) {
    stderr.writeln('Runtime content validation failed:');
    for (final issue in issues) {
      stderr.writeln('- $issue');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Runtime content validation passed: '
    '${bundle!.entries.length} stored/edited pairs, ${bundle.bundleHash}.',
  );
}

Map<String, dynamic> _readJsonObject(String path, List<String> issues) {
  final raw = _readFile(path, issues);
  if (raw.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    issues.add('$path root must be an object');
  } on FormatException catch (error) {
    issues.add('$path is invalid JSON: ${error.message}');
  }
  return <String, dynamic>{};
}

String _readFile(String path, List<String> issues) {
  final file = File(path);
  if (!file.existsSync()) {
    issues.add('required file is missing: $path');
    return '';
  }
  return file.readAsStringSync();
}

void _requireContains(
  String source,
  String expected,
  String message,
  List<String> issues,
) {
  if (!source.contains(expected)) issues.add(message);
}
