import 'package:flutter/material.dart';

class AnimatedShake extends StatelessWidget {
  final int trigger;
  final double distance;
  final Widget child;

  const AnimatedShake({
    super.key,
    required this.trigger,
    required this.child,
    this.distance = 8,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final wave = (1 - value) * distance;
        final dx = trigger == 0 ? 0.0 : wave * (value < 0.5 ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}
