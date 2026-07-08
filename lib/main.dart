import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/question_repository.dart';
import 'package:hee_no_tane_app/data/repositories/card_repository.dart';
import 'package:hee_no_tane_app/data/repositories/enemy_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final questionRepo = QuestionRepository();
  final cardRepo = CardRepository();
  final enemyRepo = EnemyRepository();
  final saveRepo = SaveRepository();

  final questions = await questionRepo.loadAll();
  final cards = await cardRepo.loadAll();
  final enemies = await enemyRepo.loadAll();
  final saveData = await saveRepo.load();

  runApp(HeeNoTaneApp(
    allQuestions: questions,
    allCards: cards,
    allEnemies: enemies,
    saveData: saveData,
    saveRepository: saveRepo,
    battleService: BattleService(),
    rewardService: RewardService(),
  ));
}
