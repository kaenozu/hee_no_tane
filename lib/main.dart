/// lib/main.dart
///
/// アプリのエントリポイント。
library;

/// JSONデータ（問題・カード）とセーブデータを読み込み、依存関係を注入する。
///
/// 関連:
///   - app.dart
///   - data/repositories/
///   - domain/services/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/content_validation/content_release_policy.dart';
import 'package:hee_no_tane_app/data/repositories/card_repository.dart';
import 'package:hee_no_tane_app/data/repositories/question_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/startup/startup_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    final questionRepo = QuestionRepository();
    final cardRepo = CardRepository();
    final saveRepo = SaveRepository();

    final questions = await questionRepo.loadAll();
    final cards = await cardRepo.loadAll();
    _requirePlayableContent(questions, cards);
    final saveData = await saveRepo.loadOrThrow();

    runApp(
      HeeNoTaneApp(
        allQuestions: questions,
        allCards: cards,
        saveData: saveData,
        saveRepository: saveRepo,
        rewardService: RewardService(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize app: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(StartupErrorApp(details: _safeStartupErrorDetails(error)));
  }
}

void _requirePlayableContent(List<Question> questions, List<HeeCard> cards) {
  final cardsById = <String, HeeCard>{for (final card in cards) card.id: card};
  final hasPlayablePair = questions.any((question) {
    final card = cardsById[question.relatedCardId];
    return card != null && ContentReleasePolicy.isPlayablePair(question, card);
  });
  if (!hasPlayablePair) {
    throw const ContentLoadException('公開可能な問題データが見つかりませんでした。');
  }
}

String _safeStartupErrorDetails(Object error) {
  if (error is SaveLoadException) {
    return error.message;
  }
  if (error is SaveException) {
    return error.message;
  }
  if (error is ContentLoadException) {
    return error.message;
  }
  return 'アプリ内データの読み込み中に予期しない問題が発生しました。';
}
