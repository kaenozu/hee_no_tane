import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

class ContentLoadException implements Exception {
  final String message;
  final Object? cause;

  const ContentLoadException(this.message, {this.cause});

  @override
  String toString() => 'ContentLoadException: $message (cause: $cause)';
}

class QuestionRepository {
  Future<List<Question>> loadAll() async {
    try {
      final raw = await rootBundle.loadString('assets/data/questions.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) {
        throw const FormatException(
          'questions.json must be a non-empty array.',
        );
      }
      final questions = <Question>[
        for (var index = 0; index < decoded.length; index++)
          Question.fromJson(Map<String, dynamic>.from(decoded[index] as Map)),
      ];
      return List<Question>.unmodifiable(questions);
    } catch (error) {
      throw ContentLoadException('問題データの読み込みに失敗しました。', cause: error);
    }
  }
}
