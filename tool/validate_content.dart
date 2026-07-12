import 'dart:io';

import 'package:hee_no_tane_app/content_validation/content_validator.dart';

Future<void> main(List<String> arguments) async {
  final options = _CliOptions.tryParse(arguments);
  if (options == null) {
    stderr.writeln(
      'Usage: dart run tool/validate_content.dart '
      '[--root PATH] [--questions PATH] [--cards PATH]',
    );
    exitCode = 64;
    return;
  }

  final root = Directory(options.root).absolute;
  final questionsFile = _resolveFile(root, options.questionsPath);
  final cardsFile = _resolveFile(root, options.cardsPath);

  final inputErrors = <String>[];
  if (!questionsFile.existsSync()) {
    inputErrors.add('questions: file does not exist: ${questionsFile.path}');
  }
  if (!cardsFile.existsSync()) {
    inputErrors.add('cards: file does not exist: ${cardsFile.path}');
  }
  if (inputErrors.isNotEmpty) {
    _printFailure(inputErrors);
    exitCode = 1;
    return;
  }

  String questionsJson;
  String cardsJson;
  try {
    questionsJson = await questionsFile.readAsString();
    cardsJson = await cardsFile.readAsString();
  } on FileSystemException catch (error) {
    _printFailure(['input: ${error.message} (${error.path ?? 'unknown path'})']);
    exitCode = 1;
    return;
  }

  final result = const ContentValidator().validateJsonStrings(
    questionsJson: questionsJson,
    cardsJson: cardsJson,
    assetExists: (path) => _resolveFile(root, path).existsSync(),
  );

  if (result.isValid) {
    stdout.writeln(
      'Content validation passed: '
      '${result.questionCount} questions, ${result.cardCount} cards',
    );
    return;
  }

  _printFailure(result.issues.map((issue) => issue.toString()).toList());
  exitCode = 1;
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

void _printFailure(List<String> errors) {
  stderr.writeln('Content validation failed: ${errors.length} errors');
  stderr.writeln();
  for (final error in errors) {
    stderr.writeln(error);
  }
}

class _CliOptions {
  final String root;
  final String questionsPath;
  final String cardsPath;

  const _CliOptions({
    required this.root,
    required this.questionsPath,
    required this.cardsPath,
  });

  static _CliOptions? tryParse(List<String> arguments) {
    var root = '.';
    var questionsPath = 'assets/data/questions.json';
    var cardsPath = 'assets/data/cards.json';

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') return null;
      if (argument != '--root' &&
          argument != '--questions' &&
          argument != '--cards') {
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
      }
    }

    return _CliOptions(
      root: root,
      questionsPath: questionsPath,
      cardsPath: cardsPath,
    );
  }
}
