import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

class Question {
  final String id;
  final String category;
  final String difficulty;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
  final String relatedCardId;
  final String legacySourceNote;
  final bool verified;
  final SourceMetadata? sourceMetadata;

  const Question({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    required this.relatedCardId,
    required String sourceNote,
    required this.verified,
    this.sourceMetadata,
  }) : legacySourceNote = sourceNote;

  SourceMetadata get effectiveSource {
    return sourceMetadata ?? SourceMetadata.legacy(legacySourceNote);
  }

  String get sourceNote {
    final source = sourceMetadata;
    if (source == null) return legacySourceNote;
    final verifiedAt = source.verifiedAt;
    if (verifiedAt == null) return source.displayLabel;
    return '${source.displayLabel}（確認日: $verifiedAt）';
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    final choices = List<String>.from(json['choices'] as List);
    final answerIndex = json['answerIndex'] as int;
    if (choices.isEmpty) {
      throw const FormatException('Question choices must not be empty.');
    }
    if (answerIndex < 0 || answerIndex >= choices.length) {
      throw FormatException(
        'Question answerIndex $answerIndex is outside choices range.',
      );
    }

    final sourceJson = json['source'];
    if (sourceJson != null && sourceJson is! Map<String, dynamic>) {
      throw const FormatException('Question source must be an object.');
    }

    return Question(
      id: json['id'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      question: json['question'] as String,
      choices: choices,
      answerIndex: answerIndex,
      explanation: json['explanation'] as String,
      relatedCardId: json['relatedCardId'] as String,
      sourceNote: json['sourceNote'] as String,
      verified: json['verified'] as bool,
      sourceMetadata: sourceJson == null
          ? null
          : SourceMetadata.fromJson(sourceJson),
    );
  }
}
