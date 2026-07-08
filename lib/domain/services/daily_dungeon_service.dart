import 'dart:math';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';

class DailyDungeonService {
  final List<Enemy> _normalEnemies;
  final Enemy _bossEnemy;

  DailyDungeonService(this._normalEnemies, this._bossEnemy);

  List<Question> generateQuestions(String dateSeed, List<Question> allQuestions) {
    final playable = allQuestions.where((q) => q.verified).toList();
    if (playable.length < 5) return playable;

    final random = Random(dateSeed.hashCode);
    final shuffled = List<Question>.from(playable)..shuffle(random);
    return shuffled.take(5).toList();
  }

  Enemy getEnemyForFloor(int floor) {
    if (floor == 5) return _bossEnemy;
    if (_normalEnemies.isEmpty) return _bossEnemy;

    final index = (floor - 1).clamp(0, _normalEnemies.length - 1);
    return _normalEnemies[index];
  }
}
