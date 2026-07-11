/// lib/features/home/home_screen.dart
///
/// ホーム画面。毎日1問のクイズに答え、知識カードを収集する。
library;
/// ストリーク・収集数・閲覧数を表示し、今日の1問を開始する。
///
/// 関連:
///   - ../../domain/services/daily_question_service.dart
///   - ../../core/date_utils.dart
///   - ../question/daily_question_screen.dart
///   - ../collection/card_detail_screen.dart
///   - ../collection/card_list_screen.dart
///   - ../settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/core/date_utils.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';
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
  Question? _todayQuestion;
  HeeCard? _todayCard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.saveRepository.load();
    if (!mounted) return;
    final dateStr = todayDateString();
    final service = DailyQuestionService();
    final questions = service.generateQuestions(
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
    });
  }

  HeeCard? _resolveCard(Question question) {
    final cardMap = {for (final c in widget.allCards) c.id: c};
    return cardMap[question.relatedCardId];
  }

  bool get _isTodayAnswered {
    return _saveData.lastDailyQuestionDate == todayDateString();
  }

  /// 今日の1問を開始する。
  Future<void> _startDailyQuestion() async {
    if (_todayQuestion == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyQuestionScreen(
          question: _todayQuestion!,
          relatedCard: _todayCard,
          saveRepository: widget.saveRepository,
          rewardService: widget.rewardService,
          saveData: _saveData,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) await _load();
  }

  /// カード詳細画面へ遷移する。
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
          saveData: _saveData,
        ),
      ),
    );
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
            SliverToBoxAdapter(child: _dailyQuestionSection()),
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

  /// 今日の1問セクション。
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
                    color: _categoryColor(question.category).withValues(alpha: 0.12),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
              // 回答済み表示
              Container(
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openCardDetail,
                  icon: const Icon(Icons.auto_stories, size: 18),
                  label: const Text('カードを読む'),
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
            ] else ...[
              // 未回答表示
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startDailyQuestion,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('今日の1問を始める'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
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
