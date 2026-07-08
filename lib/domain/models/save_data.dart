class GameSettings {
  bool soundEnabled;
  bool bgmEnabled;

  GameSettings({
    this.soundEnabled = true,
    this.bgmEnabled = true,
  });

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      bgmEnabled: json['bgmEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'bgmEnabled': bgmEnabled,
      };
}

class SaveData {
  final int version;
  int totalPlayCount;
  int totalClearCount;
  int streakDays;
  String lastPlayedDate;
  String lastRewardDate;
  List<String> ownedCardIds;
  GameSettings settings;

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
        settings = settings ?? GameSettings();

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
          : GameSettings(),
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
