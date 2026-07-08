import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';

class CardRepository {
  Future<List<HeeCard>> loadAll() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/cards.json');
      final list = json.decode(jsonString) as List<dynamic>;
      return list.map((e) => HeeCard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
