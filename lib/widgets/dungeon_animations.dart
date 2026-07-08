// File: lib/widgets/dungeon_animations.dart
// ダンジョンUIで使用するアニメーションウィジェット（AliveMotion, PulseGlow）
// リッチなモーション表現を独立させて他の画面からも再利用しやすくする
// Related files: dungeon_widgets.dart, dungeon_palette.dart, dungeon_chrome.dart

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// AliveMotion
// ──────────────────────────────────────────────

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

// ──────────────────────────────────────────────
// PulseGlow
// ──────────────────────────────────────────────

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
