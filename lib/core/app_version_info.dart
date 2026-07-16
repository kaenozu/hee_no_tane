import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  final String version;
  final String buildNumber;

  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
  });

  const AppVersionInfo.unavailable()
    : version = '',
      buildNumber = '';

  bool get isAvailable => version.isNotEmpty;

  String get displayValue {
    if (!isAvailable) return '取得できません';
    return buildNumber.isEmpty ? version : '$version ($buildNumber)';
  }

  String get settingsSubtitle =>
      isAvailable ? 'へぇのタネ v$displayValue' : 'へぇのタネ';

  static Future<AppVersionInfo> load() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppVersionInfo(
      version: packageInfo.version.trim(),
      buildNumber: packageInfo.buildNumber.trim(),
    );
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
