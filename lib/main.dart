/// lib/main.dart
///
/// アプリのエントリポイント。
library;

/// 公開用コンテンツbundleとセーブデータを読み込み、依存関係を注入する。
///
/// 関連:
///   - app.dart
///   - data/repositories/
///   - domain/services/

import 'dart:async';

import 'package:flutter/foundation.dart' hide debugPrint, debugPrintStack;
import 'package:flutter/material.dart' hide debugPrint, debugPrintStack;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/core/app_log.dart';
import 'package:hee_no_tane_app/data/repositories/content_bundle_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/startup/startup_error_screen.dart';
import 'package:hee_no_tane_app/monetization/ad_consent.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Consent must be resolved before initializing the ad SDK. A consent or
  // network failure disables ads for this session but never blocks the app.
  await AdConsent.prepare();
  if (AdConsent.canRequestAds) {
    unawaited(MobileAds.instance.initialize());
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('Uncaught platform error: $error');
    debugPrintStack(stackTrace: stackTrace);

    // Returning false keeps the error observable by the host platform instead
    // of claiming it was fully handled by debug-only logging.
    return false;
  };

  try {
    await SaveRepository.migrateLegacyStorage();

    final contentRepository = ContentBundleRepository();
    final saveRepository = SaveRepository();
    const dailyQuestionService = DailyQuestionService();
    final rewardService = RewardService();

    final contentBundle = await contentRepository.load();
    final saveData = await saveRepository.loadOrThrow();

    runApp(
      HeeNoTaneApp(
        allQuestions: contentBundle.questions,
        allCards: contentBundle.cards,
        saveData: saveData,
        saveRepository: saveRepository,
        rewardService: rewardService,
        dailyQuestionService: dailyQuestionService,
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize app: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(StartupErrorApp(details: _safeStartupErrorDetails(error)));
  }
}

String _safeStartupErrorDetails(Object error) {
  if (error is SaveLoadException) {
    return error.message;
  }

  if (error is SaveException) {
    return error.message;
  }

  if (error is ContentBundleLoadException) {
    return error.message;
  }

  return 'アプリ内データの読み込み中に予期しない問題が発生しました。';
}
