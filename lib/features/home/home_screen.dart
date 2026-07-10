/// lib/features/home/home_screen.dart
///
/// ホーム画面。毎日3問のクイズに答え、知識カードを収集する。
library;
/// ストリーク・収集数・閲覧数を表示し、カードをタップで詳細へ。
///
/// 関連:
///   - ../../domain/services/daily_question_service.dart
///   - ../collection/card_detail_screen.dart
///   - ../settings/settings_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_list_screen.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Question> allQuestions;
  final List<HeeCard> allCards;
  final SaveRepository saveRepository;
  final RewardService rewardService;

  const HomeScreen({
    super.key,
    required this.allQuestions,
    required this.allCards,
    required this.saveRepository,
    required this.rewardService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SaveData _saveData = SaveData();
  List<HeeCard> _todayCards = [];
  List<Question> _todayQuestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.saveRepository.load();
    if (!mounted) return;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final service = DailyQuestionService();
    final questions = service.generateQuestions(
      dateStr,
      widget.allQuestions,
      count: 3,
    );
    final cards = _resolveCards(questions);
    setState(() {
      _saveData = data;
      _todayQuestions = questions;
      _todayCards = cards;
      _loading = false;
    });
  }

  List<HeeCard> _resolveCards(List<Question> questions) {
    final cardMap = {for (final c in widget.allCards) c.id: c};
    final seen = <String>{};
    final result = <HeeCard>[];
    for (final q in questions) {
      if (seen.contains(q.relatedCardId)) continue;
      final card = cardMap[q.relatedCardId];
      if (card != null) {
        result.add(card);
        seen.add(card.id);
      }
    }
    return result;
  }

  Future<void> _openCard(HeeCard card, Question? relatedQuestion) async {
    final isOwned = _saveData.ownedCardIds.contains(card.id);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: card,
          isOwned: isOwned,
          relatedQuestion: relatedQuestion,
          rewardService: widget.rewardService,
          saveRepository: widget.saveRepository,
          saveData: _saveData,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _statsRow()),
            SliverToBoxAdapter(child: _todaySectionHeader()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _cardTile(
                  _todayCards[index],
                  _todayQuestions.length > index
                      ? _todayQuestions[index]
                      : null,
                ),
                childCount: _todayCards.length,
              ),
            ),
            SliverToBoxAdapter(child: _bottomNav()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'へぇのタネ',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    saveRepository: widget.saveRepository,
                    rewardService: widget.rewardService,
                    onDataReset: () => _load(),
                  ),
                ),
              ).then((_) => _load());
            },
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final cs = Theme.of(context).colorScheme;
    final owned = _saveData.ownedCardIds.length;
    final total = widget.allCards.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _statChip(
            Icons.local_fire_department,
            '${_saveData.streakDays}日',
            '連続',
            cs.primary,
            cs,
          ),
          const SizedBox(width: 10),
          _statChip(
            Icons.collections_bookmark,
            '$owned/$total',
            '図鑑',
            cs.secondary,
            cs,
          ),
          const SizedBox(width: 10),
          _statChip(
            Icons.menu_book_rounded,
            '${_saveData.totalBrowseCount}',
            '閲覧',
            cs.tertiary,
            cs,
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    IconData icon,
    String value,
    String label,
    Color color,
    ColorScheme cs,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todaySectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Text(
            '今日の3枚',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'タップして読む',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTile(HeeCard card, Question? question) {
    final cs = Theme.of(context).colorScheme;
    final isOwned = _saveData.ownedCardIds.contains(card.id);
    final catColor = _categoryColor(card.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () => _openCard(card, question),
        child: Container(
          decoration: BoxDecoration(
            color: isOwned
                ? cs.surface
                : cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: catColor.withValues(alpha: isOwned ? 0.2 : 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _categoryLabel(card.category),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: catColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isOwned)
                      Icon(Icons.circle_outlined,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    if (isOwned)
                      Icon(Icons.check_circle,
                          size: 14, color: cs.primary.withValues(alpha: 0.6)),
                    if (card.rarity == 'rare') ...[
                      const SizedBox(width: 4),
                      Icon(Icons.auto_awesome,
                          size: 14, color: cs.secondary),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  card.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.shortText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.auto_stories,
                        size: 12,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(width: 4),
                    Text(
                      '読む',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    final cs = Theme.of(context).colorScheme;
    final owned = _saveData.ownedCardIds.length;
    final total = widget.allCards.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardListScreen(
                      saveData: _saveData,
                      allCards: widget.allCards,
                    ),
                  ),
                ).then((_) => _load());
              },
              icon: const Icon(Icons.collections_bookmark, size: 20),
              label: Text('図鑑 ($owned/$total)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const Map<String, String> _categoryLabels = {
  'nature_geography': '自然・地理',
  'living_things': '生き物',
  'history': '歴史',
  'science': '科学',
  'food': '食べ物',
  'language': 'ことば',
  'daily_life': '生活',
};

const Map<String, Color> _categoryColors = {
  'nature_geography': Color(0xFF4CAF50),
  'living_things': Color(0xFFFF9800),
  'history': Color(0xFF795548),
  'science': Color(0xFF2196F3),
  'food': Color(0xFFE91E63),
  'language': Color(0xFF9C27B0),
  'daily_life': Color(0xFF607D8B),
};

String _categoryLabel(String cat) => _categoryLabels[cat] ?? cat;
Color _categoryColor(String cat) => _categoryColors[cat] ?? Colors.grey;
