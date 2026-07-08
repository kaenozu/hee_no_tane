class Question {
  final String id;
  final String category;
  final String difficulty;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
  final String relatedCardId;
  final String sourceNote;
  final bool verified;

  const Question({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    required this.relatedCardId,
    required this.sourceNote,
    required this.verified,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      question: json['question'] as String,
      choices: List<String>.from(json['choices'] as List),
      answerIndex: json['answerIndex'] as int,
      explanation: json['explanation'] as String,
      relatedCardId: json['relatedCardId'] as String,
      sourceNote: json['sourceNote'] as String,
      verified: json['verified'] as bool,
    );
  }
}
