import 'package:flutter/material.dart';

class DungeonPalette {
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

class DungeonBackground extends StatelessWidget {
  final Widget child;
  final bool safeArea;

  const DungeonBackground({
    super.key,
    required this.child,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DungeonPalette.dungeonTop, DungeonPalette.dungeonBottom],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _StonePattern()),
          const Positioned(left: 18, top: 80, child: _TorchGlow()),
          const Positioned(right: 18, top: 120, child: _TorchGlow()),
          child,
        ],
      ),
    );
    return safeArea ? SafeArea(child: content) : content;
  }
}

class ParchmentPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  const ParchmentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? DungeonPalette.parchment;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x44FFC743),
            blurRadius: 18,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ParchmentPainter(radius: radius, color: base),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFF7A4B22), width: 2.4),
          ),
          child: child,
        ),
      ),
    );
  }
}

class RibbonTitle extends StatelessWidget {
  final String text;
  final IconData? icon;

  const RibbonTitle({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: DungeonPalette.teal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0A4D49), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: DungeonPalette.gold, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameHudBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final IconData icon;

  const GameHudBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$value/$maxValue',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFF11131A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black54),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.32),
                      color,
                    ),
                    color,
                    Color.alphaBlend(
                      Colors.black.withValues(alpha: 0.18),
                      color,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DungeonFloorNode extends StatelessWidget {
  final int floor;
  final Widget icon;
  final bool isBoss;
  final bool isCurrent;

  const DungeonFloorNode({
    super.key,
    required this.floor,
    required this.icon,
    this.isBoss = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBoss
        ? DungeonPalette.ember
        : (isCurrent ? DungeonPalette.gold : DungeonPalette.parchment);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: DungeonPalette.ink, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 6),
        Text(
          isBoss ? 'BOSS\n${floor}F' : '${floor}F',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: DungeonPalette.ink,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class AliveMotion extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double bob;
  final double sway;
  final double scale;
  final bool reverse;

  const AliveMotion({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1800),
    this.bob = 4,
    this.sway = 0,
    this.scale = 0.018,
    this.reverse = false,
  });

  @override
  State<AliveMotion> createState() => _AliveMotionState();
}

class _AliveMotionState extends State<AliveMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final curved = Curves.easeInOut.transform(_controller.value);
        final phase = widget.reverse ? 1 - curved : curved;
        final offsetY = (phase - 0.5) * 2 * widget.bob;
        final offsetX = (phase - 0.5) * 2 * widget.sway;
        final scale = 1 + ((phase - 0.5) * 2 * widget.scale);
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  final double blurRadius;
  final double spreadRadius;

  const PulseGlow({
    super.key,
    required this.child,
    required this.color,
    this.duration = const Duration(milliseconds: 1400),
    this.blurRadius = 20,
    this.spreadRadius = 1,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final glow = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.18 + glow * 0.22),
                blurRadius: widget.blurRadius + glow * 10,
                spreadRadius: widget.spreadRadius + glow * 2,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _TorchGlow extends StatelessWidget {
  const _TorchGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 90,
        height: 90,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xAAFFB02E), Color(0x33E95A2A), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}

class _ParchmentPainter extends CustomPainter {
  final double radius;
  final Color color;

  const _ParchmentPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(Colors.white.withValues(alpha: 0.22), color),
          color,
          Color.alphaBlend(
            const Color(0xFFE0AA55).withValues(alpha: 0.18),
            color,
          ),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, basePaint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = const Color(0xFFB9823B).withValues(alpha: 0.28);
    canvas.drawRRect(rrect.deflate(4), edgePaint);

    final grain = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF8B5D2E).withValues(alpha: 0.08);
    for (var i = 0; i < 18; i++) {
      final y = (i * 37 + 11) % size.height;
      final x0 = ((i * 53) % 90).toDouble();
      canvas.drawLine(Offset(x0, y), Offset(size.width - x0 / 2, y + 5), grain);
    }

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.32);
    canvas.drawRRect(rrect.deflate(3), highlight);
  }

  @override
  bool shouldRepaint(covariant _ParchmentPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}

class _StonePattern extends StatelessWidget {
  const _StonePattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StonePatternPainter());
  }
}

class _StonePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.06);

    const blockHeight = 54.0;
    const blockWidth = 78.0;
    for (double y = 0; y < size.height + blockHeight; y += blockHeight) {
      final offset = ((y / blockHeight).round().isEven) ? 0.0 : blockWidth / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      for (double x = -offset; x < size.width + blockWidth; x += blockWidth) {
        canvas.drawLine(Offset(x, y), Offset(x, y + blockHeight), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
