/// Home screen for the daily question and card collection.
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/content_validation/content_release_policy.dart';
import 'package:hee_no_tane_app/core/date_utils.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_list_screen.dart';
import 'package:hee_no_tane_app/features/collection/category_util.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Question> allQuestions;
  final List<HeeCard> allCards;
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final Future<void> Function()? onDataReset;

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
  String _todayDate = '';
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final data = await widget.saveRepository.loadOrThrow();
      final date = todayDateString();
      final generated = DailyQuestionService().generateQuestions(
        date,
        widget.allQuestions,
        allCards: widget.allCards,
        count: 1,
      );
      Question? question = generated.isEmpty ? null : generated.first;
      HeeCard? card = question == null
          ? null
          : _resolveCard(question.relatedCardId);

      if (data.lastDailyQuestionDate == date &&
          data.lastDailyQuestionId.isNotEmpty &&
          data.lastDailyCardId.isNotEmpty) {
        question = _resolveQuestion(data.lastDailyQuestionId);
        card = _resolveCard(data.lastDailyCardId);
        if (question == null ||
            card == null ||
            !_isReleaseApprovedPair(question, card) ||
            !data.ownedCardIds.contains(card.id)) {
          throw const SaveLoadException(
            '本日の回答履歴とコンテンツが一致しません。アプリを更新して再度お試しください。',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _saveData = data;
        _todayDate = date;
        _todayQuestion = question;
        _todayCard = card;
        _loading = false;
      });
    } on SaveLoadException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    }
  }

  Question? _resolveQuestion(String id) {
    for (final question in widget.allQuestions) {
      if (question.id == id && question.isSourceReleaseApproved) {
        return question;
      }
    }
    return null;
  }

  HeeCard? _resolveCard(String id) {
    for (final card in widget.allCards) {
      if (card.id == id && card.isSourceReleaseApproved) return card;
    }
    return null;
  }

  bool _isReleaseApprovedPair(Question question, HeeCard card) =>
      ContentReleasePolicy.isPlayablePair(question, card);

  List<HeeCard> get _releaseCards {
    final cardsById = <String, HeeCard>{
      for (final card in widget.allCards) card.id: card,
    };
    final result = <HeeCard>[];
    for (final question in widget.allQuestions) {
      final card = cardsById[question.relatedCardId];
      if (card != null && ContentReleasePolicy.isPlayablePair(question, card)) {
        result.add(card);
      }
    }
    return List<HeeCard>.unmodifiable(result);
  }

  int get _ownedReleaseCardCount => _releaseCards
      .where((card) => _saveData.ownedCardIds.contains(card.id))
      .length;

  bool get _isTodayAnswered {
    if (_saveData.lastDailyQuestionDate != _todayDate) return false;
    if (!_saveData.hasIdentifiedDailyCompletion) {
      return _todayCard != null &&
          _saveData.ownedCardIds.contains(_todayCard!.id);
    }
    return _saveData.lastDailyQuestionId == _todayQuestion?.id &&
        _saveData.lastDailyCardId == _todayCard?.id;
  }

  Future<void> _startDailyQuestion() async {
    final question = _todayQuestion;
    if (question == null || _todayDate.isEmpty) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyQuestionScreen(
          question: question,
          questionDate: _todayDate,
          relatedCard: _todayCard,
          saveRepository: widget.saveRepository,
          rewardService: widget.rewardService,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openCardDetail() async {
    final card = _todayCard;
    if (card == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: card,
          isOwned: _saveData.ownedCardIds.contains(card.id),
          relatedQuestion: _todayQuestion,
          rewardService: widget.rewardService,
          saveRepository: widget.saveRepository,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                const Text('保存データを読み込めませんでした'),
                const SizedBox(height: 8),
                Text(_loadError!, textAlign: TextAlign.center),
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
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    saveRepository: widget.saveRepository,
                    onDataReset: () async {
                      await widget.onDataReset?.call();
                    },
                  ),
                ),
              );
              if (mounted) await _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final cs = Theme.of(context).colorScheme;
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
            '$_ownedReleaseCardCount/${_releaseCards.length}',
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
          '承認済みの問題がありません',
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
            color: categoryColor(question.category).withValues(alpha: 0.2),
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
                    color: categoryColor(
                      question.category,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    categoryLabel(question.category),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: categoryColor(question.category),
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
                  onPressed: _saveData.ownedCardIds.contains(card.id)
                      ? _openCardDetail
                      : null,
                  icon: const Icon(Icons.auto_stories, size: 18),
                  label: const Text('カードを読む'),
                ),
              ),
            ] else if (answered) ...[
              const Text('今日の1問は完了しました'),
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

  Widget _bottomNav() {
    final cs = Theme.of(context).colorScheme;
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
                  allCards: _releaseCards,
                  saveRepository: widget.saveRepository,
                  rewardService: widget.rewardService,
                ),
              ),
            );
            if (mounted) await _load();
          },
          icon: const Icon(Icons.collections_bookmark, size: 20),
          label: Text('図鑑 ($_ownedReleaseCardCount/${_releaseCards.length})'),
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
