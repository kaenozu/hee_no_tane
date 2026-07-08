import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';

class BattleState {
  final int playerHp;
  final int playerMaxHp;
  final int enemyHp;
  final int enemyMaxHp;
  final int combo;
  final int floor;
  final int currentQuestionIndex;
  final List<Question> questions;
  final Enemy enemy;
  final int correctCount;

  const BattleState({
    required this.playerHp,
    required this.playerMaxHp,
    required this.enemyHp,
    required this.enemyMaxHp,
    required this.combo,
    required this.floor,
    required this.currentQuestionIndex,
    required this.questions,
    required this.enemy,
    this.correctCount = 0,
  });

  BattleState copyWith({
    int? playerHp,
    int? enemyHp,
    int? combo,
    int? floor,
    int? currentQuestionIndex,
    Enemy? enemy,
    int? correctCount,
  }) {
    return BattleState(
      playerHp: playerHp ?? this.playerHp,
      playerMaxHp: playerMaxHp,
      enemyHp: enemyHp ?? this.enemyHp,
      enemyMaxHp: enemy?.maxHp ?? enemyMaxHp,
      combo: combo ?? this.combo,
      floor: floor ?? this.floor,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questions: questions,
      enemy: enemy ?? this.enemy,
      correctCount: correctCount ?? this.correctCount,
    );
  }
}

class BattleAnswerResult {
  final bool isCorrect;
  final int damageDealt;
  final int damageTaken;
  final int playerHpAfter;
  final int enemyHpAfter;
  final int comboAfter;
  final bool isFloorCleared;
  final bool isGameOver;
  final bool isClear;
  final Question question;

  const BattleAnswerResult({
    required this.isCorrect,
    required this.damageDealt,
    required this.damageTaken,
    required this.playerHpAfter,
    required this.enemyHpAfter,
    required this.comboAfter,
    required this.isFloorCleared,
    required this.isGameOver,
    required this.isClear,
    required this.question,
  });
}
