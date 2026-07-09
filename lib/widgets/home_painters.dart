/// lib/widgets/home_painters.dart
///
/// ホーム画面で使うカスタムペインター（ダンジョン背景・宝箱）
///
/// 画像が読み込めなかった場合のフォールバック描画として使用する。
/// 通常は home_screen.dart が画像を優先し、errorBuilder 経由で本クラスが使われる。
///
/// 関連:
///   - ../features/home/home_screen.dart
///   - ../widgets/dungeon_chrome.dart
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/widgets/dungeon_chrome.dart';

class HomeDungeonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF14263A), Color(0xFF2A1C20)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      wall,
    );

    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xAAFFB02E), Color(0x22FF7A1A), Color(0x00000000)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.28),
              radius: size.width * 0.45,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 1.2;
    const blockHeight = 42.0;
    const blockWidth = 66.0;
    for (double y = 0; y < size.height; y += blockHeight) {
      final offset = ((y / blockHeight).round().isEven) ? 0.0 : blockWidth / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      for (double x = -offset; x < size.width + blockWidth; x += blockWidth) {
        canvas.drawLine(Offset(x, y), Offset(x, y + blockHeight), line);
      }
    }

    final floor = Paint()..color = const Color(0xFF2E2B2E);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.68)
        ..lineTo(size.width, size.height * 0.57)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      floor,
    );

    final shadow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.34)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shadow);

    final torch = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x88FFC743), Color(0x00FFC743)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.14, size.height * 0.26),
              radius: 90,
            ),
          );
    canvas.drawRect(Offset.zero & size, torch);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TreasureChestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.height - 18, size.width - 12, 14),
        const Radius.circular(12),
      ),
      shadow,
    );

    final outline = Paint()
      ..color = DungeonPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 24, size.width - 16, size.height - 28),
      const Radius.circular(10),
    );
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(13, 8, size.width - 26, 30),
      const Radius.circular(12),
    );

    canvas.drawRRect(lid, Paint()..color = const Color(0xFFE08A2D));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFB85E24));
    canvas.drawRRect(lid, outline);
    canvas.drawRRect(body, outline);

    final band = Paint()..color = DungeonPalette.gold;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 8, 12, 16, size.height - 18),
        const Radius.circular(4),
      ),
      band,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 30, size.width - 40, 8),
        const Radius.circular(4),
      ),
      band,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 10, 38, 20, 16),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFE28A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
