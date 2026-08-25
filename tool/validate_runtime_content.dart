import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
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

  ContentBundle? sourceBundle;
  ContentBundle? runtimeBundle;
  final bundleRaw = _readFile(_bundlePath, issues);
  if (bundleRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(bundleRaw);
      if (decoded is! Map) {
        issues.add('$_bundlePath root must be an object');
      } else {
        sourceBundle = ContentBundle.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        runtimeBundle = Rc1ContentPolicy.apply(sourceBundle);
      }
    } on Object catch (error) {
      issues.add('$_bundlePath is invalid: $error');
    }
  }

  final manifest = _readJsonObject(_manifestPath, issues);
  final appVersion = _readJsonObject(_appVersionPath, issues);
  if (sourceBundle != null && runtimeBundle != null) {
    final expectedContentVersion =
        '${appVersion['version']}+${appVersion['buildNumber']}';
    if (sourceBundle.contentVersion != expectedContentVersion) {
      issues.add(
        'bundle contentVersion must match app version $expectedContentVersion',
      );
    }
    if (manifest['playableQuestionCount'] != runtimeBundle.entries.length) {
      issues.add(
        'manifest playableQuestionCount must match RC1 runtime entryCount',
      );
    }
    if (manifest['contentVersion'] != runtimeBundle.contentVersion) {
      issues.add('manifest contentVersion must match runtime contentVersion');
    }
    if (manifest['bundleHash'] != runtimeBundle.bundleHash) {
      issues.add('manifest bundleHash must match RC1 runtime bundleHash');
    }

    // The source bundle is the asset actually shipped in the APK before the
    // fail-closed RC1 policy is applied, so every referenced image still needs
    // to exist even for entries deferred from v1.0 playability.
    for (final entry in sourceBundle.entries) {
      final imageAsset = entry.card.imageAsset;
      if (imageAsset.isEmpty || !File(imageAsset).existsSync()) {
        issues.add(
          'source bundle image is missing for ${entry.card.id}: $imageAsset',
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
    '${sourceBundle!.entries.length} editorial pairs, '
    '${runtimeBundle!.entries.length} RC1 runtime pairs, '
    '${runtimeBundle.bundleHash}.',
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
