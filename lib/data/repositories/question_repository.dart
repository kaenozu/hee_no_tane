import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

class QuestionRepository {
  Future<List<Question>> loadAll() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/questions.json',
      );
      final list = json.decode(jsonString) as List<dynamic>;
      return list
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Failed to load questions: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  List<Question> getVerifiedQuestions(List<Question> all) {
    return all.where((q) => q.verified).toList();
  }
}
