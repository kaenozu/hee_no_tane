class DailyDeck {
  final String date;
  final List<String> cardIds;
  final String generatedAt;

  const DailyDeck({
    required this.date,
    required this.cardIds,
    required this.generatedAt,
  });

  factory DailyDeck.fromJson(Map<String, dynamic> json) {
    return DailyDeck(
      date: json['date'] as String,
      cardIds: List<String>.from(json['cards'] as List),
      generatedAt: json['generated_at'] as String,
    );
  }
}
