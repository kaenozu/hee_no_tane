class HeeCardSource {
  final String title;
  final String url;
  final String sourceType;
  final String retrievedAt;

  const HeeCardSource({
    required this.title,
    required this.url,
    required this.sourceType,
    required this.retrievedAt,
  });

  factory HeeCardSource.fromJson(Map<String, dynamic> json) {
    return HeeCardSource(
      title: json['title'] as String,
      url: json['url'] as String,
      sourceType: json['source_type'] as String,
      retrievedAt: json['retrieved_at'] as String,
    );
  }
}

class Quiz {
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  const Quiz({
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      question: json['question'] as String,
      choices: List<String>.from(json['choices'] as List),
      answerIndex: json['answer_index'] as int,
      explanation: json['explanation'] as String,
    );
  }
}

class HeeCard {
  final String id;
  final String title;
  final String hook;
  final String shortBody;
  final String longBody;
  final String category;
  final String confidenceLevel;
  final List<HeeCardSource> sources;
  final Quiz quiz;
  final List<String> relatedCardIds;

  const HeeCard({
    required this.id,
    required this.title,
    required this.hook,
    required this.shortBody,
    required this.longBody,
    required this.category,
    required this.confidenceLevel,
    required this.sources,
    required this.quiz,
    required this.relatedCardIds,
  });

  factory HeeCard.fromJson(Map<String, dynamic> json) {
    return HeeCard(
      id: json['id'] as String,
      title: json['title'] as String,
      hook: json['hook'] as String,
      shortBody: json['short_body'] as String,
      longBody: json['long_body'] as String,
      category: json['category'] as String,
      confidenceLevel: json['confidence_level'] as String,
      sources: (json['sources'] as List)
          .map((s) => HeeCardSource.fromJson(s as Map<String, dynamic>))
          .toList(),
      quiz: Quiz.fromJson(json['quiz'] as Map<String, dynamic>),
      relatedCardIds: List<String>.from(json['related_card_ids'] as List),
    );
  }
}
