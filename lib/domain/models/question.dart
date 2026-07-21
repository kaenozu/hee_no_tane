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

  Question({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required List<String> choices,
    required this.answerIndex,
    required this.explanation,
    required this.relatedCardId,
    required String sourceNote,
    required this.verified,
    this.sourceMetadata,
  }) : choices = List.unmodifiable(choices),
       legacySourceNote = sourceNote;

  SourceMetadata get effectiveSource =>
      sourceMetadata ?? SourceMetadata.legacy(legacySourceNote);

  bool get isSourceReleaseApproved =>
      verified && sourceMetadata?.isReleaseApproved == true;

  String get sourceNote {
    final source = sourceMetadata;
    if (source == null) return legacySourceNote;
    final verifiedAt = source.verifiedAt;
    if (verifiedAt == null) return source.displayLabel;
    return '${source.displayLabel}（確認日: $verifiedAt）';
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    final choicesValue = json['choices'];
    if (choicesValue is! List || choicesValue.any((item) => item is! String)) {
      throw const FormatException('Question choices must be a string array.');
    }
    final choices = List<String>.from(choicesValue);
    final answerIndex = json['answerIndex'];
    if (answerIndex is! int) {
      throw const FormatException('Question answerIndex must be an integer.');
    }
    if (choices.isEmpty) {
      throw const FormatException('Question choices must not be empty.');
    }
    if (answerIndex < 0 || answerIndex >= choices.length) {
      throw FormatException(
        'Question answerIndex $answerIndex is outside choices range.',
      );
    }

    return Question(
      id: _requiredString(json, 'id'),
      category: _requiredString(json, 'category'),
      difficulty: _requiredString(json, 'difficulty'),
      question: _requiredString(json, 'question'),
      choices: choices,
      answerIndex: answerIndex,
      explanation: _requiredString(json, 'explanation'),
      relatedCardId: _requiredString(json, 'relatedCardId'),
      sourceNote: _requiredString(json, 'sourceNote'),
      verified: json['verified'] as bool,
      sourceMetadata: SourceMetadata.fromOptionalJson(json['source']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'category': category,
    'difficulty': difficulty,
    'question': question,
    'choices': choices,
    'answerIndex': answerIndex,
    'explanation': explanation,
    'relatedCardId': relatedCardId,
    'sourceNote': legacySourceNote,
    'verified': verified,
    if (sourceMetadata != null) 'source': sourceMetadata!.toJson(),
  };

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Question $key must be a non-empty string.');
    }
    return value.trim();
  }
}
