import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/atomic_generated_files_writer.dart';
import 'package:hee_no_tane_app/content_validation/content_bundle_builder.dart';
import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

const _questionsPath = 'assets/data/questions.json';
const _cardsPath = 'assets/data/cards.json';
const _appVersionPath = 'assets/data/app_version.json';
const _bundlePath = 'assets/data/content_bundle.json';
const _manifestPath = 'assets/data/content_manifest.json';

void main(List<String> arguments) {
  final checkOnly = arguments.contains('--check');
  final unknown = arguments.where((argument) => argument != '--check').toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown arguments: ${unknown.join(' ')}');
    exitCode = 64;
    return;
  }

  try {
    final questions = _readQuestions();
    final cards = _readCards();
    final contentVersion = _readContentVersion();
    final sourceBundle = ContentBundleBuilder.build(
      questions: questions,
      cards: cards,
      contentVersion: contentVersion,
    );
    final runtimeBundle = Rc1ContentPolicy.apply(sourceBundle);

    const encoder = JsonEncoder.withIndent('  ');
    // Keep the complete editorial/source bundle in the generated asset. The
    // runtime repository applies the same RC1 policy when loading it, while the
    // manifest reports the actual v1.0 playable boundary and runtime hash.
    final bundleText = '${encoder.convert(sourceBundle.toJson())}\n';
    final manifestText =
        '${encoder.convert(<String, dynamic>{'schemaVersion': 1, 'questionCount': questions.length, 'cardCount': cards.length, 'playableQuestionCount': runtimeBundle.entries.length, 'contentVersion': runtimeBundle.contentVersion, 'bundleHash': runtimeBundle.bundleHash})}\n';

    if (checkOnly) {
      final mismatches = <String>[];
      _checkGeneratedFile(_bundlePath, bundleText, mismatches);
      _checkGeneratedFile(_manifestPath, manifestText, mismatches);
      if (mismatches.isNotEmpty) {
        stderr.writeln('Generated content files are stale:');
        for (final mismatch in mismatches) {
          stderr.writeln('- $mismatch');
        }
        stderr.writeln('Run: dart run tool/generate_content_bundle.dart');
        exitCode = 1;
        return;
      }
      stdout.writeln(
        'Content bundle is current: ${sourceBundle.entries.length} editorial pairs, '
        '${runtimeBundle.entries.length} RC1 runtime pairs, '
        '${runtimeBundle.bundleHash}.',
      );
      return;
    }

    AtomicGeneratedFilesWriter.write(<String, String>{
      _bundlePath: bundleText,
      _manifestPath: manifestText,
    });
    stdout.writeln(
      'Generated $_bundlePath with ${sourceBundle.entries.length} editorial pairs; '
      'manifest exposes ${runtimeBundle.entries.length} RC1 runtime pairs.',
    );
  } on Object catch (error, stackTrace) {
    stderr.writeln('Content bundle generation failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

List<Question> _readQuestions() {
  final values = _readList(_questionsPath);
  return <Question>[
    for (final value in values)
      Question.fromJson(Map<String, dynamic>.from(value as Map)),
  ];
}

List<HeeCard> _readCards() {
  final values = _readList(_cardsPath);
  return <HeeCard>[
    for (final value in values)
      HeeCard.fromJson(Map<String, dynamic>.from(value as Map)),
  ];
}

String _readContentVersion() {
  final value = _readObject(_appVersionPath);
  final version = value['version'];
  final buildNumber = value['buildNumber'];
  if (version is! String || version.trim().isEmpty) {
    throw const FormatException('app_version.json version is invalid.');
  }
  if (buildNumber is! String || buildNumber.trim().isEmpty) {
    throw const FormatException('app_version.json buildNumber is invalid.');
  }
  return '${version.trim()}+${buildNumber.trim()}';
}

List<dynamic> _readList(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! List) {
    throw FormatException('$path root must be an array.');
  }
  return decoded;
}

Map<String, dynamic> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('$path root must be an object.');
  }
  return Map<String, dynamic>.from(decoded);
}

void _checkGeneratedFile(
  String path,
  String expected,
  List<String> mismatches,
) {
  final file = File(path);
  if (!file.existsSync()) {
    mismatches.add('$path is missing');
    return;
  }
  if (file.readAsStringSync() != expected) {
    mismatches.add('$path does not match its source data');
  }
}
