/// lib/features/home/home_screen.dart
///
/// ホーム画面。毎日1問のクイズに答え、知識カードを収集する。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/core/date_utils.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_list_screen.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Question> allQuestions;
  final List<HeeCard> allCards;
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final VoidCallback? onDataReset;

  const HomeScreen({
    super.key,
    required this.allQuestions,
    required this.allCards,
    required this.saveRepository,
    required this.rewardService,
    this.onDataReset,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SaveData _saveData = SaveData();
  Question? _todayQuestion;
  HeeCard? _todayCard;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final data = await widget.saveRepository.loadOrThrow();
      if (!mounted) return;
      final dateStr = todayDateString();
      final questions = DailyQuestionService().generateQuestions(
        dateStr,
        widget.allQuestions,
        count: 1,
      );
      final question = questions.isNotEmpty ? questions.first : null;
      final card = question != null ? _resolveCard(question) : null;
      setState(() {
        _saveData = data;
        _todayQuestion = question;
        _todayCard = card;
        _loading = false;
        _loadError = null;
      });
    } on SaveLoadException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    }
  }

  HeeCard? _resolveCard(Question question) {
    final cardMap = {for (final card in widget.allCards) card.id: card};
    return cardMap[question.relatedCardId];
  }

  bool get _isTodayAnswered =>
      _saveData.lastDailyQuestionDate == todayDateString();

  Future<void> _startDailyQuestion() async {
    if (_todayQuestion == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyQuestionScreen(
          question: _todayQuestion!,
          relatedCard: _todayCard,
          saveRepository: widget.saveRepository,
          rewardService: widget.rewardService,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openCardDetail() async {
    if (_todayCard == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: _todayCard!,
          isOwned: true,
          relatedQuestion: _todayQuestion,
          rewardService: widget.rewardService,
          saveRepository: widget.saveRepository,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          saveRepository: widget.saveRepository,
          rewardService: widget.rewardService,
          onDataReset: () {
            widget.onDataReset?.call();
          },
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return _buildLoadError();
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _statsRow()),
            SliverToBoxAdapter(child: _dailyQuestionSection()),
            SliverToBoxAdapter(child: _bottomNav()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
                  const SizedBox(height: 20),
                  Text(
                    'データを読み込めませんでした',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('home-load-retry'),
                    onPressed: () => _load(showLoading: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
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
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
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
      child: Semantics(
        label: '$label $value',
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
      ),
    );
  }

  Widget _dailyQuestionSection() {
    final cs = Theme.of(context).colorScheme;
    final question = _todayQuestion;
    final card = _todayCard;
    final answered = _isTodayAnswered;

    if (question == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text(
          '利用可能な問題がありません',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _categoryColor(question.category).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                    color: _categoryColor(
                      question.category,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _categoryLabel(question.category),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _categoryColor(question.category),
                    ),
                  ),
                ),
                const Spacer(),
                if (answered)
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '今日の1問',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '約30秒',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 16),
            if (answered && card != null) ...[
              _answeredCard(card, cs),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openCardDetail,
                  icon: const Icon(Icons.auto_stories, size: 18),
                  label: const Text('カードを読む'),
                ),
              ),
            ] else if (answered) ...[
              _missingCard(cs),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startDailyQuestion,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('今日の1問を始める'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answeredCard(HeeCard card, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日の1問は完了しました',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _missingCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日の1問は完了しました',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'カード情報を読み込めませんでした',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    final cs = Theme.of(context).colorScheme;
    final owned = _saveData.ownedCardIds.length;
    final total = widget.allCards.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => CardListScreen(
                  allCards: widget.allCards,
                  saveRepository: widget.saveRepository,
                  rewardService: widget.rewardService,
                ),
              ),
            );
            if (!mounted) return;
            await _load();
          },
          icon: const Icon(Icons.collections_bookmark, size: 20),
          label: Text('図鑑 ($owned/$total)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
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

String _categoryLabel(String category) =>
    _categoryLabels[category] ?? category;
Color _categoryColor(String category) =>
    _categoryColors[category] ?? Colors.grey;
