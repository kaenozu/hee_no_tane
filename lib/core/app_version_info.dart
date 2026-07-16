import 'dart:convert';

import 'package:flutter/services.dart';

class AppVersionInfo {
  static const assetPath = 'assets/data/app_version.json';

  final String version;
  final String buildNumber;

  const AppVersionInfo({required this.version, required this.buildNumber});

  const AppVersionInfo.unavailable() : version = '', buildNumber = '';

  bool get isAvailable => version.isNotEmpty;

  String get displayValue {
    if (!isAvailable) return '取得できません';
    return buildNumber.isEmpty ? version : '$version ($buildNumber)';
  }

  String get settingsSubtitle => isAvailable ? 'へぇのタネ v$displayValue' : 'へぇのタネ';

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final buildNumber = json['buildNumber'];
    if (version is! String || version.trim().isEmpty) {
      throw const FormatException('app version must be a non-empty string');
    }
    if (buildNumber is! String || buildNumber.trim().isEmpty) {
      throw const FormatException('app buildNumber must be a non-empty string');
    }
    return AppVersionInfo(
      version: version.trim(),
      buildNumber: buildNumber.trim(),
    );
  }

  static Future<AppVersionInfo> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'app version metadata root must be an object',
      );
    }
    return AppVersionInfo.fromJson(Map<String, dynamic>.from(decoded));
  }
}

typedef AppVersionInfoLoader = Future<AppVersionInfo> Function();

Future<AppVersionInfo> loadAppVersionInfoSafely() async {
  try {
    return await AppVersionInfo.load();
  } catch (_) {
    return const AppVersionInfo.unavailable();
  }
}
