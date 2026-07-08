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
    'card_umbrella_001',
    'card_shoes_001',
    'card_slippers_001',
    'card_train_delay_001',
    'card_eki_001',
    'card_karoshi_001',
    'card_samurai_001',
    'card_kimono_001',
    'card_furoshiki_001',
    'card_mizu_001',
    'card_microwave_001',
    'card_sky_001',
    'card_rainbow_001',
    'card_ice_001',
    'card_yawning_001',
    'card_ramen_001',
    'card_curry_001',
    'card_sushi_001',
    'card_onigiri_001',
    'card_natto_001',
    'card_arigato_001',
    'card_hentai_001',
    'card_kirakira_001',
    'card_sugoi_001',
    'card_kawaii_001',
    'card_hanami_001',
    'card_omotenashi_001',
    'card_omikuji_001',
    'card_hatsuyume_001',
    'card_bento_001',
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
