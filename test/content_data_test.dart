import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('question card references are backed by card data', () {
    final questions = _readJsonList('assets/data/questions.json');
    final cards = _readJsonList('assets/data/cards.json');
    final cardCategories = {
      for (final card in cards)
        card['id'] as String: card['category'] as String,
    };

    final missing = <String>[];
    final mismatchedCategories = <String>[];
    for (final question in questions) {
      final relatedCardId = question['relatedCardId'] as String;
      final cardCategory = cardCategories[relatedCardId];
      if (cardCategory == null) {
        missing.add('${question['id']} -> $relatedCardId');
      } else if (cardCategory != question['category']) {
        mismatchedCategories.add(
          '${question['id']} -> $relatedCardId ($cardCategory)',
        );
      }
    }

    expect(missing, isEmpty);
    expect(mismatchedCategories, isEmpty);
  });

  test('question choices are complete and unique', () {
    final questions = _readJsonList('assets/data/questions.json');
    final invalid = <String>[];

    for (final question in questions) {
      final choices = (question['choices'] as List<dynamic>).cast<String>();
      if (choices.length != 4 || choices.toSet().length != choices.length) {
        invalid.add(question['id'] as String);
      }
      if (choices.any((choice) => choice.trim().isEmpty)) {
        invalid.add('${question['id']} has blank choice');
      }
    }

    expect(invalid, isEmpty);
  });
}

List<Map<String, dynamic>> _readJsonList(String path) {
  final file = File(path);
  final raw = file.readAsStringSync();
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
}
