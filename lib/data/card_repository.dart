import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/models/card.dart';

class CardRepository {
  static const _cardIds = [
    'card_manhole_round_001',
    'card_sewer_001',
    'card_static_electricity_001',
    'card_wasabi_001',
    'card_tempura_001',
    'card_itadakimasu_001',
    'card_ringo_001',
    'card_syrup_001',
    'card_magnet_001',
  ];

  Future<Map<String, HeeCard>> loadAllCards() async {
    final cards = <String, HeeCard>{};
    for (final id in _cardIds) {
      try {
        final path = 'data/cards/$id.json';
        final jsonString = await rootBundle.loadString(path);
        final card = HeeCard.fromJson(json.decode(jsonString) as Map<String, dynamic>);
        cards[card.id] = card;
      } catch (e) {
        // Skip missing cards
        continue;
      }
    }
    return cards;
  }
}
