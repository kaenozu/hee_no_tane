import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/features/collection/category_util.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';

class CardListScreen extends StatefulWidget {
  final SaveData saveData;
  final List<HeeCard> allCards;

  const CardListScreen({super.key, required this.saveData, required this.allCards});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  String _selectedCategory = '';

  List<HeeCard> get _displayCards {
    final filtered = _selectedCategory.isEmpty
        ? List<HeeCard>.from(widget.allCards)
        : widget.allCards.where((c) => c.category == _selectedCategory).toList();
    filtered.sort((a, b) {
      final aOwned = widget.saveData.ownedCardIds.contains(a.id);
      final bOwned = widget.saveData.ownedCardIds.contains(b.id);
      if (aOwned && !bOwned) return -1;
      if (!aOwned && bOwned) return 1;
      return a.id.compareTo(b.id);
    });
    return filtered;
  }

  Set<String> get _categories =>
      widget.allCards.map((c) => c.category).toSet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final owned = widget.saveData.ownedCardIds.length;
    final total = widget.allCards.length;

    return Scaffold(
      appBar: AppBar(title: Text('へぇ図鑑 ($owned/$total)')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _chip('すべて', '', cs),
                ..._categories.map((c) => _chip(categoryLabel(c), c, cs)),
              ],
            ),
          ),
          Expanded(
            child: _displayCards.isEmpty
                ? const Center(child: Text('カードがありません'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _displayCards.length,
                    itemBuilder: (context, index) => _cardTile(_displayCards[index], cs),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, ColorScheme cs) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = selected ? '' : value),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        selectedColor: cs.primary.withValues(alpha: 0.15),
        checkmarkColor: cs.primary,
      ),
    );
  }

  Widget _cardTile(HeeCard card, ColorScheme cs) {
    final isOwned = widget.saveData.ownedCardIds.contains(card.id);
    final catColor = categoryColor(card.category);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CardDetailScreen(card: card, isOwned: isOwned)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isOwned ? cs.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOwned ? catColor.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isOwned ? catColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  isOwned ? Icons.auto_stories : Icons.lock_outline,
                  color: isOwned ? catColor : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                isOwned ? card.title : '???',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isOwned ? cs.onSurface : Colors.grey[400]),
                maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOwned)
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.rarity == 'rare' ? '★' : '●',
                  style: TextStyle(fontSize: 10, color: catColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
