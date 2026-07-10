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

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/data/repositories/card_repository.dart';
import 'package:hee_no_tane_app/data/repositories/question_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final questionRepo = QuestionRepository();
  final cardRepo = CardRepository();
  final saveRepo = SaveRepository();

  final questions = await questionRepo.loadAll();
  final cards = await cardRepo.loadAll();
  final saveData = await saveRepo.load();

  runApp(
    HeeNoTaneApp(
      allQuestions: questions,
      allCards: cards,
      saveData: saveData,
      saveRepository: saveRepo,
      rewardService: RewardService(),
    ),
  );
}
