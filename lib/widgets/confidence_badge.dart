import 'package:flutter/material.dart';

class ConfidenceBadge extends StatelessWidget {
  final String level;

  const ConfidenceBadge({super.key, required this.level});

  Color _colorForLevel(BuildContext context, String level) {
    switch (level) {
      case 'A':
        return Theme.of(context).colorScheme.primaryContainer;
      case 'B':
        return Theme.of(context).colorScheme.secondaryContainer;
      case 'C':
        return Theme.of(context).colorScheme.tertiaryContainer;
      case 'D':
        return Theme.of(context).colorScheme.errorContainer;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  String _labelForLevel(String level) {
    switch (level) {
      case 'A':
        return '複数の信頼できる出典で確認済み';
      case 'B':
        return '信頼できる出典で確認済み';
      case 'C':
        return '諸説あり。断定せず紹介しています';
      case 'D':
        return '小話レベル。公開前確認が必要';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _colorForLevel(context, level),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$level ${_labelForLevel(level)}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
