/// バトル背景・キャラクター・エフェクトを描画するウィジェット
///
/// BattleScreen の _stage() メソッドから抽出したステージ描画部分。
/// 背景、プレイヤー、敵、エフェクト画像、スタンプ、ダメージポップアップ、
/// クリアバナーをStackで重ねて表示する。
///
/// 関連ファイル:
/// - battle_screen.dart (このウィジェットを使用)
/// - quiz_panel.dart (画面右/下半分)
/// - battle_ui_phase.dart (UIフェーズ定義)
library;
import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/features/battle/battle_ui_phase.dart';
import 'package:hee_no_tane_app/widgets/animated_shake.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';

class BattleStage extends StatelessWidget {
  final BattleUiPhase phase;
  final BattleAnswerResult? lastResult;
  final Enemy enemy;
  final int reactionSerial;

  const BattleStage({
    super.key,
    required this.phase,
    required this.lastResult,
    required this.enemy,
    required this.reactionSerial,
  });

  @override
  Widget build(BuildContext context) {
    final result = lastResult;
    final correctResolving =
        phase == BattleUiPhase.resolving && result?.isCorrect == true;
    final wrongResolving =
        phase == BattleUiPhase.resolving && result?.isCorrect == false;
    final defeated = result?.isFloorCleared == true &&
        (phase == BattleUiPhase.floorClear ||
            phase == BattleUiPhase.dungeonClear);
    final isAnswered = phase != BattleUiPhase.idle;

    return ParchmentPanel(
      padding: EdgeInsets.zero,
      color: const Color(0xFF1B2431),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/battle_stage.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF24344A), Color(0xFF0F1722)],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.72, 0.45),
              child: AnimatedSlide(
                offset: correctResolving
                    ? const Offset(0.14, -0.04)
                    : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: AnimatedShake(
                  trigger: wrongResolving ? reactionSerial : 0,
                  distance: 10,
                  child: AliveMotion(
                    duration: const Duration(milliseconds: 1600),
                    bob: 5,
                    sway: 2,
                    child: _characterImage(
                      'assets/images/characters/player.png',
                      112,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.7, 0.34),
              child: AnimatedOpacity(
                opacity: defeated ? 0 : 1,
                duration: const Duration(milliseconds: 360),
                child: AnimatedScale(
                  scale: defeated ? 0.4 : 1,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeInBack,
                  child: AnimatedShake(
                    trigger: correctResolving ? reactionSerial : 0,
                    distance: 13,
                    child: AliveMotion(
                      duration: const Duration(milliseconds: 1350),
                      bob: 6,
                      scale: 0.025,
                      reverse: true,
                      child: _enemyImage(enemy, 136),
                    ),
                  ),
                ),
              ),
            ),
            if (correctResolving) _effectImage('slash.png', 0.58, 0.28, 180),
            if (correctResolving)
              _effectImage('hit_spark.png', 0.67, 0.34, 150),
            if (wrongResolving) _stampImage('stamp_wrong.png'),
            if (result?.isCorrect == true && phase != BattleUiPhase.idle)
              _stampImage(
                'stamp_correct.png',
                align: const Alignment(-0.18, -0.7),
              ),
            if (defeated) _effectImage('defeat_smoke.png', 0.7, 0.48, 180),
            if (isAnswered) _damagePopup(),
            if (phase == BattleUiPhase.floorClear ||
                phase == BattleUiPhase.dungeonClear)
              _clearBanner(phase == BattleUiPhase.dungeonClear),
          ],
        ),
      ),
    );
  }

  Widget _effectImage(String name, double x, double y, double size) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$name-$reactionSerial'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: (1.1 - value).clamp(0.0, 1.0),
            child:
                Transform.scale(scale: 0.75 + value * 0.35, child: child),
          );
        },
        child: Align(
          alignment: Alignment(x * 2 - 1, y * 2 - 1),
          child:
              Image.asset('assets/images/effects/$name', width: size),
        ),
      ),
    );
  }

  Widget _stampImage(
    String name, {
    Alignment align = Alignment.center,
  }) {
    return Align(
      alignment: align,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$name-$reactionSerial'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.rotate(
            angle: -0.14 + value * 0.14,
            child: Transform.scale(
                scale: value.clamp(0.0, 1.0), child: child),
          );
        },
        child:
            Image.asset('assets/images/effects/$name', width: 126),
      ),
    );
  }

  Widget _clearBanner(bool dungeonClear) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color:
              dungeonClear ? DungeonPalette.gold : DungeonPalette.teal,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: DungeonPalette.ink, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          dungeonClear ? 'ダンジョンクリア！' : 'フロアクリア！',
          style: TextStyle(
            color:
                dungeonClear ? DungeonPalette.ink : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _damagePopup() {
    final result = lastResult;
    final isCorrect = result?.isCorrect ?? false;
    final label = isCorrect
        ? '-${result?.damageDealt ?? 0}'
        : '-${result?.damageTaken ?? 0} HP';
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(reactionSerial),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: (1.25 - value).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -38 * value),
              child: Transform.scale(
                  scale: 0.55 + value * 0.55, child: child),
            ),
          );
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isCorrect
                ? DungeonPalette.ember
                : const Color(0xFF4B5563),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _characterImage(String asset, double size) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person, color: Colors.white, size: 72),
      ),
    );
  }

  Widget _enemyImage(Enemy enemy, double size) {
    if (enemy.imageAsset.isNotEmpty) {
      return SizedBox(
        height: size,
        width: size,
        child: Image.asset(
          enemy.imageAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.local_fire_department,
            size: 64,
            color: Colors.red,
          ),
        ),
      );
    }
    return SizedBox(
      height: size,
      child: const Icon(
        Icons.local_fire_department,
        size: 64,
        color: Colors.red,
      ),
    );
  }
}
