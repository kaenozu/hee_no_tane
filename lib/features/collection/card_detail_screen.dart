import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/features/collection/category_util.dart';

class CardDetailScreen extends StatelessWidget {
  final HeeCard card;
  final bool isOwned;

  const CardDetailScreen({super.key, required this.card, required this.isOwned});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(card.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120, height: 160,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 48, color: cs.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('へぇカード', style: TextStyle(fontSize: 12, color: cs.primary.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(categoryLabel(card.category),
                    style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(card.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(card.rarity == 'rare' ? '★ レア' : '● ノーマル',
                  style: TextStyle(fontSize: 12, color: cs.secondary)),
            ),
            const SizedBox(height: 20),
            if (!isOwned)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Text('未獲得', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            if (!isOwned) const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(card.detailText, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.source_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text('出典: ${card.sourceNote}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
