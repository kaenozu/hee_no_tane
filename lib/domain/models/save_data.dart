import 'package:flutter/material.dart';

class GameSettings {
  final bool soundEnabled;
  final bool bgmEnabled;
  final ThemeMode themeMode;

  const GameSettings({
    this.soundEnabled = true,
    this.bgmEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      bgmEnabled: json['bgmEnabled'] as bool? ?? true,
      themeMode: _parseThemeMode(json['themeMode'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'bgmEnabled': bgmEnabled,
        'themeMode': themeMode.name,
      };

  GameSettings copyWith({
    bool? soundEnabled,
    bool? bgmEnabled,
    ThemeMode? themeMode,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
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
  final int totalPlayCount;
  final int totalClearCount;
  final int streakDays;
  final String lastPlayedDate;
  final String lastRewardDate;
  final List<String> ownedCardIds;
  final GameSettings settings;

  SaveData({
    this.version = 1,
    this.totalPlayCount = 0,
    this.totalClearCount = 0,
    this.streakDays = 0,
    this.lastPlayedDate = '',
    this.lastRewardDate = '',
    List<String>? ownedCardIds,
    GameSettings? settings,
  })  : ownedCardIds = ownedCardIds ?? [],
        settings = settings ?? const GameSettings();

  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      version: json['version'] as int? ?? 1,
      totalPlayCount: json['totalPlayCount'] as int? ?? 0,
      totalClearCount: json['totalClearCount'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastPlayedDate: json['lastPlayedDate'] as String? ?? '',
      lastRewardDate: json['lastRewardDate'] as String? ?? '',
      ownedCardIds: List<String>.from(json['ownedCardIds'] as List? ?? []),
      settings: json['settings'] != null
          ? GameSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const GameSettings(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'totalPlayCount': totalPlayCount,
        'totalClearCount': totalClearCount,
        'streakDays': streakDays,
        'lastPlayedDate': lastPlayedDate,
        'lastRewardDate': lastRewardDate,
        'ownedCardIds': ownedCardIds,
        'settings': settings.toJson(),
      };

  SaveData copyWith({
    int? totalPlayCount,
    int? totalClearCount,
    int? streakDays,
    String? lastPlayedDate,
    String? lastRewardDate,
    List<String>? ownedCardIds,
    GameSettings? settings,
  }) {
    return SaveData(
      version: version,
      totalPlayCount: totalPlayCount ?? this.totalPlayCount,
      totalClearCount: totalClearCount ?? this.totalClearCount,
      streakDays: streakDays ?? this.streakDays,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      lastRewardDate: lastRewardDate ?? this.lastRewardDate,
      ownedCardIds: ownedCardIds ?? List.from(this.ownedCardIds),
      settings: settings ?? this.settings,
    );
  }
}
