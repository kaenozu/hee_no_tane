import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';

class EnemyRepository {
  Future<List<Enemy>> loadAll() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/enemies.json');
      final list = json.decode(jsonString) as List<dynamic>;
      return list.map((e) => Enemy.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
