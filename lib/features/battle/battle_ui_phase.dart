/// バトル画面のUI進行状態
///
/// 各フェーズで表示するウィジェットとアニメーションを切り替える。
///
/// 関連ファイル:
/// - battle_screen.dart (このenumを使用)
/// - battle_stage.dart (このenumを使用)
/// - quiz_panel.dart (このenumを使用)
enum BattleUiPhase {
  idle,
  resolving,
  showExplanation,
  floorClear,
  dungeonClear,
  gameOver,
}
