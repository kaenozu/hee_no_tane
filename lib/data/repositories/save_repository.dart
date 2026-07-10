/// lib/data/repositories/save_repository.dart
///
/// セーブデータの永続化（SharedPreferences）。
library;
///
/// 関連:
///   - ../../domain/models/save_data.dart
///   - ../../domain/services/reward_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

class SaveRepository {
  static const _key = 'hee_no_tane_save_data';

  Future<SaveData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return SaveData();
      return SaveData.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('Failed to load save data: $e');
      debugPrintStack(stackTrace: stackTrace);
      return SaveData();
    }
  }

  Future<void> save(SaveData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(data.toJson()));
    } catch (e, stackTrace) {
      debugPrint('Failed to save data: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e, stackTrace) {
      debugPrint('Failed to reset save data: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
