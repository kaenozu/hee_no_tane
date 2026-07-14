import 'dart:io';

import 'package:hee_no_tane_app/content_review/content_review_workflow.dart';
import 'package:hee_no_tane_app/content_review/content_risk_classifier.dart';

const _defaultQuestionsPath = 'assets/data/questions.json';
const _defaultCardsPath = 'assets/data/cards.json';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.contains('--help')) {
    _printUsage();
    return;
  }

  final command = arguments.first;
  final options = _parseOptions(arguments.skip(1).toList());
  final questionsPath = options['questions'] ?? _defaultQuestionsPath;
  final cardsPath = options['cards'] ?? _defaultCardsPath;
  final workflow = const ContentReviewWorkflow();
  final classifier = const ContentRiskClassifier();

  try {
    switch (command) {
      case 'export':
        final output = options['output'] ?? 'build/content_review.csv';
        final questionsJson = await File(questionsPath).readAsString();
        final cardsJson = await File(cardsPath).readAsString();
        final baseCsv = workflow.exportCsv(
          questionsJson: questionsJson,
          cardsJson: cardsJson,
        );
        final csv = classifier.enhanceReviewCsv(
          baseCsv: baseCsv,
          cardsJson: cardsJson,
        );
        await _writeOutput(output, csv);
        stdout.writeln('承認レビューCSVを出力しました: $output');
        break;
      case 'import':
        final input = options['input'];
        if (input == null || input.isEmpty) {
          throw const ContentReviewException(
            'import requires --input <csv-path>',
          );
        }
        final cardsJson = await File(cardsPath).readAsString();
        final baseCsv = classifier.stripReviewCsv(
          reviewCsv: await File(input).readAsString(),
          cardsJson: cardsJson,
        );
        final write = options.containsKey('write');
        final plan = await workflow.applyCsvToFiles(
          csv: baseCsv,
          questionsPath: questionsPath,
          cardsPath: cardsPath,
          write: write,
        );
        stdout.writeln(plan.summary);
        for (final change in plan.changes) {
          stdout.writeln(
            '- ${change.questionId} / ${change.cardId}: '
            '${change.previousStatus} -> ${change.nextStatus}',
          );
        }
        if (!write && plan.hasChanges) {
          stdout.writeln('検証のみ完了しました。反映するには --write を付けて再実行してください。');
        } else if (write && plan.hasChanges) {
          stdout.writeln('検証済み差分をJSONへ安全に反映しました。');
        }
        break;
      case 'progress':
        final progress = workflow.progress(
          questionsJson: await File(questionsPath).readAsString(),
          cardsJson: await File(cardsPath).readAsString(),
        );
        var approved = 0;
        var total = 0;
        for (final item in progress) {
          approved += item.approved;
          total += item.total;
          final percent = (item.ratio * 100).toStringAsFixed(1);
          stdout.writeln(
            '${item.category}: ${item.approved}/${item.total} ($percent%)',
          );
        }
        final overall = total == 0 ? 0 : approved / total * 100;
        stdout.writeln('合計: $approved/$total (${overall.toStringAsFixed(1)}%)');
        break;
      case 'risk':
        final output =
            options['output'] ?? 'build/reports/content_review_risks.csv';
        final questionsJson = await File(questionsPath).readAsString();
        final cardsJson = await File(cardsPath).readAsString();
        final risks = classifier.risks(
          questionsJson: questionsJson,
          cardsJson: cardsJson,
        );
        await _writeOutput(
          output,
          classifier.riskCsv(
            questionsJson: questionsJson,
            cardsJson: cardsJson,
          ),
        );
        final counts = <String, int>{};
        for (final risk in risks) {
          for (final reason in risk.reasons) {
            counts.update(reason, (value) => value + 1, ifAbsent: () => 1);
          }
        }
        stdout.writeln('高リスク候補を${risks.length}組抽出しました: $output');
        for (final entry
            in counts.entries.toList()
              ..sort((left, right) => left.key.compareTo(right.key))) {
          stdout.writeln('- ${entry.key}: ${entry.value}');
        }
        break;
      default:
        throw ContentReviewException('unknown command: $command');
    }
  } on ContentReviewException catch (error) {
    stderr.writeln('Content review failed: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Content review file error: ${error.message}');
    exitCode = 1;
  }
}

Map<String, String> _parseOptions(List<String> arguments) {
  final options = <String, String>{};
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (!argument.startsWith('--')) {
      throw ContentReviewException('unexpected argument: $argument');
    }
    final key = argument.substring(2);
    if (key == 'write') {
      options[key] = 'true';
      continue;
    }
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      throw ContentReviewException('$argument requires a value');
    }
    options[key] = arguments[++index];
  }
  return options;
}

Future<void> _writeOutput(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content, flush: true);
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/content_review.dart export [--output <csv>]
  dart run tool/content_review.dart import --input <csv> [--write]
  dart run tool/content_review.dart progress
  dart run tool/content_review.dart risk [--output <csv>]

Common options:
  --questions <path>  Questions JSON path
  --cards <path>      Cards JSON path

Import performs a full dry-run by default. JSON is changed only when every row
passes validation and --write is supplied.

imageFit is a review-only field and accepts:
  unchecked, fit, generic_placeholder, replace_required

Risk output separates dynamic and stable comparisons, current roles and current
facts, health and anatomy, financial advice, prices, currency history, and
near-duplicate facts.
''');
}
