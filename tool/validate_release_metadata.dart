import 'dart:convert';
import 'dart:io';

const _productName = 'へぇのタネ';
const _productDescription = '1日1問の雑学クイズで、知識カードを少しずつ集めるアプリ';

void main() {
  final issues = <String>[];

  final androidManifest = _read(
    'android/app/src/main/AndroidManifest.xml',
    issues,
  );
  _requireContains(
    androidManifest,
    'android:label="$_productName"',
    'Android application label must be $_productName',
    issues,
  );

  final iosInfo = _read('ios/Runner/Info.plist', issues);
  final productNameOccurrences = RegExp(
    '<string>${RegExp.escape(_productName)}</string>',
  ).allMatches(iosInfo).length;
  if (productNameOccurrences < 2) {
    issues.add(
      'iOS CFBundleDisplayName and CFBundleName must both be $_productName',
    );
  }

  final webManifestRaw = _read('web/manifest.json', issues);
  try {
    final manifest = jsonDecode(webManifestRaw) as Map<String, dynamic>;
    if (manifest['name'] != _productName) {
      issues.add('web/manifest.json name must be $_productName');
    }
    if (manifest['short_name'] != _productName) {
      issues.add('web/manifest.json short_name must be $_productName');
    }
    if (manifest['description'] != _productDescription) {
      issues.add('web/manifest.json description is out of date');
    }
  } on Object catch (error) {
    issues.add('web/manifest.json is invalid: $error');
  }

  final webIndex = _read('web/index.html', issues);
  _requireContains(
    webIndex,
    '<html lang="ja">',
    'web/index.html must declare Japanese language',
    issues,
  );
  _requireContains(
    webIndex,
    '<title>$_productName</title>',
    'web/index.html title must be $_productName',
    issues,
  );
  _requireContains(
    webIndex,
    'content="$_productDescription"',
    'web/index.html description is out of date',
    issues,
  );

  final privacyPage = _read('web/privacy.html', issues);
  _requireContains(
    privacyPage,
    '<title>プライバシーポリシー | $_productName</title>',
    'web/privacy.html title is missing or incorrect',
    issues,
  );
  _requireContains(
    privacyPage,
    'href="support.html"',
    'web/privacy.html must link to support.html',
    issues,
  );

  final supportPage = _read('web/support.html', issues);
  _requireContains(
    supportPage,
    '<title>サポート | $_productName</title>',
    'web/support.html title is missing or incorrect',
    issues,
  );
  _requireContains(
    supportPage,
    'href="privacy.html"',
    'web/support.html must link to privacy.html',
    issues,
  );

  final pubspec = _read('pubspec.yaml', issues);
  _requireContains(
    pubspec,
    'description: "$_productDescription"',
    'pubspec description is out of date',
    issues,
  );
  if (!RegExp(
    r'^version:\s+\d+\.\d+\.\d+\+\d+',
    multiLine: true,
  ).hasMatch(pubspec)) {
    issues.add('pubspec version must include a numeric build number');
  }
  _requireContains(
    pubspec,
    'image_path: "assets/app_icon.png"',
    'launcher icon source must be configured',
    issues,
  );
  if (!File('assets/app_icon.png').existsSync()) {
    issues.add('assets/app_icon.png does not exist');
  }

  final androidBuild = _read('android/app/build.gradle.kts', issues);
  if (androidBuild.contains('com.example')) {
    issues.add('Android applicationId must not use com.example');
  }
  _requireContains(
    androidBuild,
    'applicationId = "com.heenotane.hee_no_tane_app"',
    'Android applicationId changed unexpectedly',
    issues,
  );

  final iosProject = _read('ios/Runner.xcodeproj/project.pbxproj', issues);
  if (iosProject.contains('PRODUCT_BUNDLE_IDENTIFIER = com.example')) {
    issues.add('iOS bundle identifier must not use com.example');
  }
  _requireContains(
    iosProject,
    'PRODUCT_BUNDLE_IDENTIFIER = com.heenotane.heeNoTaneApp;',
    'iOS bundle identifier changed unexpectedly',
    issues,
  );

  final signingTemplate = _read(
    'android/app/keystore.properties.example',
    issues,
  );
  for (final key in ['storeFile', 'storePassword', 'keyAlias', 'keyPassword']) {
    if (!RegExp('^$key=.+', multiLine: true).hasMatch(signingTemplate)) {
      issues.add('keystore.properties.example is missing $key');
    }
  }

  for (final requiredPath in [
    'docs/09_プライバシーポリシー.md',
    'docs/10_リリースチェックリスト.md',
    'docs/11_ストア掲載文案.md',
    'docs/12_実機検証結果テンプレート.md',
    'docs/13_リリース判定.md',
    'web/privacy.html',
    'web/support.html',
  ]) {
    if (!File(requiredPath).existsSync()) {
      issues.add('required release document is missing: $requiredPath');
    }
  }

  for (final entry in {
    'android/app/src/main/AndroidManifest.xml': androidManifest,
    'ios/Runner/Info.plist': iosInfo,
    'web/manifest.json': webManifestRaw,
    'web/index.html': webIndex,
    'web/privacy.html': privacyPage,
    'web/support.html': supportPage,
    'pubspec.yaml': pubspec,
  }.entries) {
    if (entry.value.contains('へぇダンジョン')) {
      issues.add('${entry.key} still contains the retired product name');
    }
    if (entry.value.contains('毎日3枚')) {
      issues.add('${entry.key} still contains the retired product description');
    }
  }

  if (issues.isNotEmpty) {
    stderr.writeln('Release metadata validation failed:');
    for (final issue in issues) {
      stderr.writeln('- $issue');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Release metadata validation passed.');
}

String _read(String path, List<String> issues) {
  final file = File(path);
  if (!file.existsSync()) {
    issues.add('required file is missing: $path');
    return '';
  }
  return file.readAsStringSync();
}

void _requireContains(
  String source,
  String expected,
  String message,
  List<String> issues,
) {
  if (!source.contains(expected)) {
    issues.add(message);
  }
}
