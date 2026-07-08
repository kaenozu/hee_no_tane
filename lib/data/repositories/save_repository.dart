import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

class SaveRepository {
  static const _key = 'hee_dungeon_save_data';

  Future<SaveData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return SaveData();
      return SaveData.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (e) {
      return SaveData();
    }
  }

  Future<void> save(SaveData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(data.toJson()));
    } catch (e) {
      // fail silently
    }
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      // fail silently
    }
  }
}
