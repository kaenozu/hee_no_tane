import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/models/deck.dart';

class DeckRepository {
  Future<DailyDeck> loadDailyDeck(String date) async {
    // Try today's deck first
    final todayPath = 'data/decks/daily/$date.json';
    try {
      final jsonString = await rootBundle.loadString(todayPath);
      return DailyDeck.fromJson(json.decode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      // Fallback to default deck
      try {
        const defaultPath = 'data/decks/daily/default.json';
        final jsonString = await rootBundle.loadString(defaultPath);
        return DailyDeck.fromJson(json.decode(jsonString) as Map<String, dynamic>);
      } catch (_) {
        return DailyDeck(date: date, cardIds: const <String>[], generatedAt: '');
      }
    }
  }
}
