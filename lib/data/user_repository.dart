import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  static const _keySavedCardIds = 'saved_card_ids';
  static const _keyStreakCurrent = 'streak_current';
  static const _keyStreakLastDate = 'streak_last_date';
  static const _keyTodayReadCount = 'today_read_count';
  static const _keyTodayReadDate = 'today_read_date';
  static const _keyPreferredCategories = 'preferred_categories';
  static const _keyThemeMode = 'theme_mode';

  Future<List<String>> getSavedCardIds() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(_keySavedCardIds) ?? const <String>[]);
  }

  Future<bool> isCardSaved(String cardId) async {
    final ids = await getSavedCardIds();
    return ids.contains(cardId);
  }

  Future<void> saveCard(String cardId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(prefs.getStringList(_keySavedCardIds) ?? const <String>[]);
    ids.add(cardId);
    await prefs.setStringList(_keySavedCardIds, ids);
  }

  Future<void> unsaveCard(String cardId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(prefs.getStringList(_keySavedCardIds) ?? const <String>[]);
    ids.remove(cardId);
    await prefs.setStringList(_keySavedCardIds, ids);
  }

  Future<int> getStreakCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakCurrent) ?? 0;
  }

  Future<String?> getStreakLastDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStreakLastDate);
  }

  Future<void> recordRead(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyStreakLastDate);
    final currentStreak = prefs.getInt(_keyStreakCurrent) ?? 0;

    if (lastDate == null) {
      await prefs.setInt(_keyStreakCurrent, 1);
    } else if (lastDate == date) {
      // Same day: no streak change
    } else if (_isYesterday(lastDate, date)) {
      await prefs.setInt(_keyStreakCurrent, currentStreak + 1);
    } else {
      await prefs.setInt(_keyStreakCurrent, 1);
    }
    await prefs.setString(_keyStreakLastDate, date);
  }

  bool _isYesterday(String lastDate, String today) {
    try {
      final last = DateTime.parse(lastDate);
      final now = DateTime.parse(today);
      final diff = now.difference(last).inDays;
      return diff == 1;
    } catch (_) {
      return false;
    }
  }

  Future<void> recordCardReadToday(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final todayReadDate = prefs.getString(_keyTodayReadDate);

    if (todayReadDate != date) {
      await prefs.setInt(_keyTodayReadCount, 1);
      await prefs.setString(_keyTodayReadDate, date);
    } else {
      final count = prefs.getInt(_keyTodayReadCount) ?? 0;
      await prefs.setInt(_keyTodayReadCount, count + 1);
    }
  }

  Future<int> getTodayReadCount(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final todayReadDate = prefs.getString(_keyTodayReadDate);
    if (todayReadDate != date) return 0;
    return prefs.getInt(_keyTodayReadCount) ?? 0;
  }

  Future<List<String>> getPreferredCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(_keyPreferredCategories) ?? const <String>[]);
  }

  Future<void> setPreferredCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyPreferredCategories, categories);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }
}
