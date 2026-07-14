import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/data/repositories/question_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';

class CardRepository {
  Future<List<HeeCard>> loadAll() async {
    try {
      final raw = await rootBundle.loadString('assets/data/cards.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) {
        throw const FormatException('cards.json must be a non-empty array.');
      }
      final cards = <HeeCard>[
        for (var index = 0; index < decoded.length; index++)
          HeeCard.fromJson(Map<String, dynamic>.from(decoded[index] as Map)),
      ];
      return List<HeeCard>.unmodifiable(cards);
    } catch (error) {
      throw ContentLoadException('カードデータの読み込みに失敗しました。', cause: error);
    }
  }
}
