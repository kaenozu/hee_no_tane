// File: lib/widgets/dungeon_palette.dart
// ダンジョンUIで使用するカラーパレット定数
// 色の一貫性を保ち複数ウィジェットから参照しやすくするため独立させた
// Related files: dungeon_widgets.dart, dungeon_animations.dart, dungeon_chrome.dart

import 'package:flutter/material.dart';

class DungeonPalette {
  const DungeonPalette._();

  static const ink = Color(0xFF24140D);
  static const parchment = Color(0xFFFFF2D6);
  static const parchmentDeep = Color(0xFFF3D69A);
  static const teal = Color(0xFF0D766E);
  static const gold = Color(0xFFFFC743);
  static const ember = Color(0xFFE95A2A);
  static const dungeonTop = Color(0xFF10243A);
  static const dungeonBottom = Color(0xFF261A20);
  static const stone = Color(0xFF394050);
}
