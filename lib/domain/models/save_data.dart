/// Persistent application state.
library;

import 'dart:collection';

import 'package:flutter/material.dart';

class GameSettings {
  final ThemeMode themeMode;

  const GameSettings({this.themeMode = ThemeMode.system});

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      themeMode: _parseThemeMode(json['themeMode'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {'themeMode': themeMode.name};

  GameSettings copyWith({ThemeMode? themeMode}) =>
      GameSettings(themeMode: themeMode ?? this.themeMode);

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
  final int totalPlayCount;
  final int streakDays;
  final String lastPlayedDate;
  final String lastRewardDate;
  final String lastDailyQuestionDate;
  final String lastDailyQuestionId;
  final String lastDailyCardId;
  final String dailyAssignmentDate;
  final String dailyAssignmentQuestionId;
  final String dailyAssignmentCardId;
  final List<String> ownedCardIds;
  final GameSettings settings;
  final bool onboardingCompleted;

  SaveData({
    this.version = 4,
    this.totalBrowseCount = 0,
    this.totalPlayCount = 0,
    this.streakDays = 0,
    this.lastPlayedDate = '',
    this.lastRewardDate = '',
    this.lastDailyQuestionDate = '',
    this.lastDailyQuestionId = '',
    this.lastDailyCardId = '',
    this.dailyAssignmentDate = '',
    this.dailyAssignmentQuestionId = '',
    this.dailyAssignmentCardId = '',
    List<String>? ownedCardIds,
    GameSettings? settings,
    this.onboardingCompleted = false,
  }) : ownedCardIds = UnmodifiableListView<String>(
         List<String>.from(ownedCardIds ?? const <String>[]),
       ),
       settings = settings ?? const GameSettings();

  factory SaveData.fromJson(Map<String, dynamic> json) {
    final owned = json['ownedCardIds'];
    if (owned != null &&
        (owned is! List || owned.any((item) => item is! String))) {
      throw const FormatException('ownedCardIds must be a string array.');
    }

    final completionDate = json['lastDailyQuestionDate'] as String? ?? '';
    final completionQuestionId = json['lastDailyQuestionId'] as String? ?? '';
    final completionCardId = json['lastDailyCardId'] as String? ?? '';

    return SaveData(
      version: json['version'] as int? ?? 2,
      totalBrowseCount:
          json['totalBrowseCount'] as int? ??
          (json['totalPlayCount'] as int? ?? 0),
      totalPlayCount: json['totalPlayCount'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastPlayedDate: json['lastPlayedDate'] as String? ?? '',
      lastRewardDate: json['lastRewardDate'] as String? ?? '',
      lastDailyQuestionDate: completionDate,
      lastDailyQuestionId: completionQuestionId,
      lastDailyCardId: completionCardId,
      dailyAssignmentDate:
          json['dailyAssignmentDate'] as String? ?? completionDate,
      dailyAssignmentQuestionId:
          json['dailyAssignmentQuestionId'] as String? ?? completionQuestionId,
      dailyAssignmentCardId:
          json['dailyAssignmentCardId'] as String? ?? completionCardId,
      ownedCardIds: owned == null ? const <String>[] : List<String>.from(owned),
      settings: json['settings'] is Map
          ? GameSettings.fromJson(
              Map<String, dynamic>.from(json['settings'] as Map),
            )
          : const GameSettings(),
      onboardingCompleted: _parseOnboardingCompleted(json),
    );
  }

  bool hasDailyCompletion({
    required String date,
    required String questionId,
    required String cardId,
  }) =>
      lastDailyQuestionDate == date &&
      lastDailyQuestionId == questionId &&
      lastDailyCardId == cardId;

  bool get hasIdentifiedDailyCompletion =>
      lastDailyQuestionDate.isNotEmpty &&
      lastDailyQuestionId.isNotEmpty &&
      lastDailyCardId.isNotEmpty;

  bool hasDailyAssignment({
    required String date,
    required String questionId,
    required String cardId,
  }) =>
      dailyAssignmentDate == date &&
      dailyAssignmentQuestionId == questionId &&
      dailyAssignmentCardId == cardId;

  bool get hasIdentifiedDailyAssignment =>
      dailyAssignmentDate.isNotEmpty &&
      dailyAssignmentQuestionId.isNotEmpty &&
      dailyAssignmentCardId.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'version': 4,
    'totalBrowseCount': totalBrowseCount,
    'totalPlayCount': totalPlayCount,
    'streakDays': streakDays,
    'lastPlayedDate': lastPlayedDate,
    'lastRewardDate': lastRewardDate,
    'lastDailyQuestionDate': lastDailyQuestionDate,
    'lastDailyQuestionId': lastDailyQuestionId,
    'lastDailyCardId': lastDailyCardId,
    'dailyAssignmentDate': dailyAssignmentDate,
    'dailyAssignmentQuestionId': dailyAssignmentQuestionId,
    'dailyAssignmentCardId': dailyAssignmentCardId,
    'ownedCardIds': ownedCardIds,
    'settings': settings.toJson(),
    'onboardingCompleted': onboardingCompleted,
  };

  SaveData copyWith({
    int? totalBrowseCount,
    int? totalPlayCount,
    int? streakDays,
    String? lastPlayedDate,
    String? lastRewardDate,
    String? lastDailyQuestionDate,
    String? lastDailyQuestionId,
    String? lastDailyCardId,
    String? dailyAssignmentDate,
    String? dailyAssignmentQuestionId,
    String? dailyAssignmentCardId,
    List<String>? ownedCardIds,
    GameSettings? settings,
    bool? onboardingCompleted,
  }) => SaveData(
    version: 4,
    totalBrowseCount: totalBrowseCount ?? this.totalBrowseCount,
    totalPlayCount: totalPlayCount ?? this.totalPlayCount,
    streakDays: streakDays ?? this.streakDays,
    lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
    lastRewardDate: lastRewardDate ?? this.lastRewardDate,
    lastDailyQuestionDate: lastDailyQuestionDate ?? this.lastDailyQuestionDate,
    lastDailyQuestionId: lastDailyQuestionId ?? this.lastDailyQuestionId,
    lastDailyCardId: lastDailyCardId ?? this.lastDailyCardId,
    dailyAssignmentDate: dailyAssignmentDate ?? this.dailyAssignmentDate,
    dailyAssignmentQuestionId:
        dailyAssignmentQuestionId ?? this.dailyAssignmentQuestionId,
    dailyAssignmentCardId:
        dailyAssignmentCardId ?? this.dailyAssignmentCardId,
    ownedCardIds: ownedCardIds ?? this.ownedCardIds,
    settings: settings ?? this.settings,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );

  static bool _parseOnboardingCompleted(Map<String, dynamic> json) {
    final stored = json['onboardingCompleted'];
    if (stored is bool) return stored;
    final owned = json['ownedCardIds'];
    final hasOwnedCards = owned is List && owned.isNotEmpty;
    final hasCounters =
        (json['totalBrowseCount'] as int? ?? 0) > 0 ||
        (json['totalPlayCount'] as int? ?? 0) > 0 ||
        (json['streakDays'] as int? ?? 0) > 0;
    final hasDates =
        (json['lastPlayedDate'] as String? ?? '').isNotEmpty ||
        (json['lastRewardDate'] as String? ?? '').isNotEmpty ||
        (json['lastDailyQuestionDate'] as String? ?? '').isNotEmpty;
    return hasOwnedCards || hasCounters || hasDates;
  }
}
