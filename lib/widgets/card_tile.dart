import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/models/card.dart';

final Map<String, Color> _categoryColors = {
  'daily_why': Color(0xFFE67E22),
  'history_bite': Color(0xFFC0392B),
  'science_nearby': Color(0xFF2980B9),
  'food_origin': Color(0xFF27AE60),
  'language_trivia': Color(0xFF8E44AD),
  'culture_japan': Color(0xFFD35400),
};

final Map<String, IconData> _categoryIcons = {
  'daily_why': Icons.help_outline_rounded,
  'history_bite': Icons.history_rounded,
  'science_nearby': Icons.science_rounded,
  'food_origin': Icons.restaurant_rounded,
  'language_trivia': Icons.translate_rounded,
  'culture_japan': Icons.palette_rounded,
};

class HeeCardTile extends StatelessWidget {
  final HeeCard card;
  final VoidCallback onTap;

  const HeeCardTile({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildCategoryChip(context),
                      const Spacer(),
                      _buildConfidenceDot(context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.hook,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        'タップして読む',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    final cat = card.category;
    final color = _categoryColors[cat] ?? Colors.grey;
    final icon = _categoryIcons[cat] ?? Icons.circle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _categoryLabel(cat),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceDot(BuildContext context) {
    final colors = {'A': Color(0xFF27AE60), 'B': Color(0xFF2980B9), 'C': Color(0xFFF39C12), 'D': Color(0xFFE74C3C)};
    final c = colors[card.confidenceLevel] ?? Colors.grey;
    return Tooltip(
      message: '信頼度: ${card.confidenceLevel}',
      child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    );
  }

  String _categoryLabel(String slug) {
    const labels = {
      'daily_why': '日常のなぜ',
      'history_bite': '歴史',
      'science_nearby': '科学',
      'food_origin': '食べ物',
      'language_trivia': '言葉',
      'culture_japan': '文化',
    };
    return labels[slug] ?? slug;
  }
}
