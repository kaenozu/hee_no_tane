/// lib/domain/models/save_data.dart
///
/// 永続化データモデル。
library;
/// カード収集・ストリーク・プレイ統計・設定を保持する。
///
/// 関連:
///   - ../services/reward_service.dart
///   - ../../data/repositories/save_repository.dart
///   - hee_card.dart

import 'package:flutter/material.dart';

class GameSettings {
  final ThemeMode themeMode;

  const GameSettings({
    this.themeMode = ThemeMode.system,
  });

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      themeMode: _parseThemeMode(json['themeMode'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
  };

  GameSettings copyWith({
    ThemeMode? themeMode,
  }) {
    return GameSettings(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

class SaveData {
  final int version;
  final int totalBrowseCount;
  final int totalPlayCount; // kept for backward compat
  final int streakDays;
  final String lastPlayedDate;
  final String lastRewardDate; // kept for backward compat
  final String lastDailyQuestionDate;
  final List<String> ownedCardIds;
  final GameSettings settings;

  SaveData({
    this.version = 2,
    this.totalBrowseCount = 0,
    this.totalPlayCount = 0,
    this.streakDays = 0,
    this.lastPlayedDate = '',
    this.lastRewardDate = '',
    this.lastDailyQuestionDate = '',
    List<String>? ownedCardIds,
    GameSettings? settings,
  }) : ownedCardIds = ownedCardIds ?? [],
       settings = settings ?? const GameSettings();

  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      version: json['version'] as int? ?? 2,
      totalBrowseCount: json['totalBrowseCount'] as int? ??
          (json['totalPlayCount'] as int? ?? 0),
      totalPlayCount: json['totalPlayCount'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastPlayedDate: json['lastPlayedDate'] as String? ?? '',
      lastRewardDate: json['lastRewardDate'] as String? ?? '',
      lastDailyQuestionDate:
          json['lastDailyQuestionDate'] as String? ?? '',
      ownedCardIds: List<String>.from(json['ownedCardIds'] as List? ?? []),
      settings: json['settings'] != null
          ? GameSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const GameSettings(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'totalBrowseCount': totalBrowseCount,
    'totalPlayCount': totalPlayCount,
    'streakDays': streakDays,
    'lastPlayedDate': lastPlayedDate,
    'lastRewardDate': lastRewardDate,
    'lastDailyQuestionDate': lastDailyQuestionDate,
    'ownedCardIds': ownedCardIds,
    'settings': settings.toJson(),
  };

  SaveData copyWith({
    int? totalBrowseCount,
    int? totalPlayCount,
    int? streakDays,
    String? lastPlayedDate,
    String? lastRewardDate,
    String? lastDailyQuestionDate,
    List<String>? ownedCardIds,
    GameSettings? settings,
  }) {
    return SaveData(
      version: version,
      totalBrowseCount: totalBrowseCount ?? this.totalBrowseCount,
      totalPlayCount: totalPlayCount ?? this.totalPlayCount,
      streakDays: streakDays ?? this.streakDays,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      lastRewardDate: lastRewardDate ?? this.lastRewardDate,
      lastDailyQuestionDate:
          lastDailyQuestionDate ?? this.lastDailyQuestionDate,
      ownedCardIds: ownedCardIds ?? List.from(this.ownedCardIds),
      settings: settings ?? this.settings,
    );
  }
}
