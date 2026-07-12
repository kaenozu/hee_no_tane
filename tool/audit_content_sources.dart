import 'dart:io';

import 'package:hee_no_tane_app/content_validation/source_auditor.dart';

Future<void> main(List<String> arguments) async {
  final options = _CliOptions.tryParse(arguments);
  if (options == null) {
    stderr.writeln(
      'Usage: dart run tool/audit_content_sources.dart '
      '[--root PATH] [--questions PATH] [--cards PATH] '
      '[--output PATH] [--require-approved]',
    );
    exitCode = 64;
    return;
  }

  final root = Directory(options.root).absolute;
  final questionsFile = _resolveFile(root, options.questionsPath);
  final cardsFile = _resolveFile(root, options.cardsPath);

  if (!questionsFile.existsSync() || !cardsFile.existsSync()) {
    if (!questionsFile.existsSync()) {
      stderr.writeln('questions file does not exist: ${questionsFile.path}');
    }
    if (!cardsFile.existsSync()) {
      stderr.writeln('cards file does not exist: ${cardsFile.path}');
    }
    exitCode = 1;
    return;
  }

  final result = const ContentSourceAuditor().auditJsonStrings(
    questionsJson: await questionsFile.readAsString(),
    cardsJson: await cardsFile.readAsString(),
  );

  final outputFile = _resolveFile(root, options.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(result.toMarkdown());

  stdout.writeln(
    'Source audit completed: ${result.totalCount} items, '
    '${result.approvedCount} approved, ${result.pendingCount} pending, '
    '${result.invalidCount} invalid',
  );
  stdout.writeln('Report: ${outputFile.path}');

  if (result.hasInvalidMetadata) {
    stderr.writeln('Source audit failed because invalid metadata was found.');
    exitCode = 1;
    return;
  }

  if (options.requireApproved && !result.allApproved) {
    stderr.writeln(
      'Source audit failed because --require-approved was specified and '
      '${result.pendingCount} items still need review.',
    );
    exitCode = 1;
  }
}

File _resolveFile(Directory root, String path) {
  if (_isAbsolutePath(path)) return File(path);
  final normalized = path.replaceAll('/', Platform.pathSeparator);
  return File('${root.path}${Platform.pathSeparator}$normalized');
}

bool _isAbsolutePath(String path) {
  if (path.startsWith('/') || path.startsWith('\\')) return true;
  return Platform.isWindows && RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
}

class _CliOptions {
  final String root;
  final String questionsPath;
  final String cardsPath;
  final String outputPath;
  final bool requireApproved;

  const _CliOptions({
    required this.root,
    required this.questionsPath,
    required this.cardsPath,
    required this.outputPath,
    required this.requireApproved,
  });

  static _CliOptions? tryParse(List<String> arguments) {
    var root = '.';
    var questionsPath = 'assets/data/questions.json';
    var cardsPath = 'assets/data/cards.json';
    var outputPath = 'build/reports/content_source_audit.md';
    var requireApproved = false;

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') return null;
      if (argument == '--require-approved') {
        requireApproved = true;
        continue;
      }
      if (argument != '--root' &&
          argument != '--questions' &&
          argument != '--cards' &&
          argument != '--output') {
        return null;
      }
      if (index + 1 >= arguments.length) return null;
      final value = arguments[++index].trim();
      if (value.isEmpty) return null;

      switch (argument) {
        case '--root':
          root = value;
          break;
        case '--questions':
          questionsPath = value;
          break;
        case '--cards':
          cardsPath = value;
          break;
        case '--output':
          outputPath = value;
          break;
      }
    }

    return _CliOptions(
      root: root,
      questionsPath: questionsPath,
      cardsPath: cardsPath,
      outputPath: outputPath,
      requireApproved: requireApproved,
    );
  }
}
