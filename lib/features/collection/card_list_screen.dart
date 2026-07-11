/// lib/features/collection/card_list_screen.dart
///
/// 図鑑画面。カード一覧をグリッド表示し、カテゴリでフィルタリング可能。
library;

///
/// 関連:
///   - card_detail_screen.dart
///   - category_util.dart
///   - ../../core/save_dependencies.dart
///   - ../../domain/models/save_data.dart

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/core/save_dependencies.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/category_util.dart';

class CardListScreen extends StatefulWidget {
  final List<HeeCard> allCards;
  final SaveRepository? saveRepository;
  final RewardService? rewardService;
  final SaveData? saveData;

  const CardListScreen({
    super.key,
    required this.allCards,
    this.saveRepository,
    this.rewardService,
    this.saveData,
  });

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  String _selectedCategory = '';
  SaveData? _saveData;
  bool _loading = true;
  String? _loadError;
  bool _isFirstLoad = true;
  late SaveRepository _saveRepository;
  late RewardService _rewardService;

  @override
  void initState() {
    super.initState();
    _saveData = widget.saveData;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final inherited = SaveDependencies.maybeOf(context);
    _saveRepository =
        widget.saveRepository ??
        inherited?.saveRepository ??
        (throw FlutterError(
          'CardListScreen requires a SaveRepository. Pass it explicitly or '
          'wrap the app with SaveDependencies.',
        ));
    _rewardService =
        widget.rewardService ??
        inherited?.rewardService ??
        (throw FlutterError(
          'CardListScreen requires a RewardService. Pass it explicitly or '
          'wrap the app with SaveDependencies.',
        ));
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _load(initial: true);
    }
  }

  Future<void> _load({bool initial = false}) async {
    if (!initial && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final data = await _saveRepository.loadOrThrow();
      if (!mounted) return;
      setState(() {
        _saveData = data;
        _loading = false;
        _loadError = null;
      });
    } on SaveLoadException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  List<HeeCard> get _displayCards {
    final saveData = _saveData ?? SaveData();
    final filtered = _selectedCategory.isEmpty
        ? List<HeeCard>.from(widget.allCards)
        : widget.allCards
              .where((card) => card.category == _selectedCategory)
              .toList();
    filtered.sort((a, b) {
      final aOwned = saveData.ownedCardIds.contains(a.id);
      final bOwned = saveData.ownedCardIds.contains(b.id);
      if (aOwned && !bOwned) return -1;
      if (!aOwned && bOwned) return 1;
      return a.id.compareTo(b.id);
    });
    return filtered;
  }

  Set<String> get _categories => widget.allCards.map((c) => c.category).toSet();

  Future<void> _openCard(HeeCard card) async {
    final saveData = _saveData;
    if (saveData == null) return;
    final isOwned = saveData.ownedCardIds.contains(card.id);

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: card,
          isOwned: isOwned,
          rewardService: _rewardService,
          saveRepository: _saveRepository,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('へぇ図鑑')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('へぇ図鑑')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 12),
                const Text(
                  '図鑑データを読み込めませんでした',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final saveData = _saveData ?? SaveData();
    final cs = Theme.of(context).colorScheme;
    final owned = saveData.ownedCardIds.length;
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _displayCards.length,
                    itemBuilder: (context, index) =>
                        _cardTile(_displayCards[index], saveData, cs),
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
        onSelected: (_) =>
            setState(() => _selectedCategory = selected ? '' : value),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        selectedColor: cs.primary.withValues(alpha: 0.15),
        checkmarkColor: cs.primary,
      ),
    );
  }

  Widget _cardTile(HeeCard card, SaveData saveData, ColorScheme cs) {
    final isOwned = saveData.ownedCardIds.contains(card.id);
    final catColor = categoryColor(card.category);

    return GestureDetector(
      key: ValueKey('card-tile-${card.id}'),
      onTap: () => _openCard(card),
      child: Container(
        decoration: BoxDecoration(
          color: isOwned
              ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOwned
                ? catColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isOwned
                    ? catColor.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isOwned ? cs.onSurface : Colors.grey[400],
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
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
