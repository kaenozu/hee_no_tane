/// lib/features/question/daily_question_screen.dart
///
/// 毎日の1問クイズ画面。
library;
/// 3択・4択に回答し、正誤と解説を同じ画面で表示する。
/// 回答後にカードを獲得し、ホームまたは図鑑へ遷移する。
///
/// 関連:
///   - ../../domain/models/question.dart
///   - ../../domain/models/hee_card.dart
///   - ../../domain/models/save_data.dart
///   - ../../domain/services/reward_service.dart
///   - ../../data/repositories/save_repository.dart

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';

/// 毎日の1問クイズ画面。
///
/// [question] 今日の問題。
/// [relatedCard] 問題に関連するカード。
/// [allCards] 全カードリスト（関連カード検索用）。
/// [saveRepository] セーブデータ永続化。
/// [rewardService] カード獲得ロジック。
/// [saveData] 現在のセーブデータ。
class DailyQuestionScreen extends StatefulWidget {
  final Question question;
  final HeeCard? relatedCard;
  final List<HeeCard> allCards;
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final SaveData saveData;

  const DailyQuestionScreen({
    super.key,
    required this.question,
    this.relatedCard,
    required this.allCards,
    required this.saveRepository,
    required this.rewardService,
    required this.saveData,
  });

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  int? _selectedChoice;
  bool _answered = false;
  late SaveData _currentSaveData;
  bool _cardOwned = false;
  bool _rewardApplied = false;

  @override
  void initState() {
    super.initState();
    _currentSaveData = widget.saveData;
    _cardOwned = widget.relatedCard != null &&
        _currentSaveData.ownedCardIds.contains(widget.relatedCard!.id);
  }

  /// 解答を処理し、カードを獲得する。
  void _answer(int index) {
    if (_answered) return;

    // カード獲得を同期的に適用し、非同期で永続化する。
    final card = widget.relatedCard;
    SaveData newData = _currentSaveData;
    bool newCardOwned = _cardOwned;
    bool newRewardApplied = false;

    if (card != null && !_cardOwned) {
      newData = widget.rewardService.applyReward(newData, card);
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      newData = widget.rewardService.updatePlayStats(newData, dateStr);
      newData = newData.copyWith(lastDailyQuestionDate: dateStr);
      newCardOwned = true;
      newRewardApplied = true;
    }

    setState(() {
      _selectedChoice = index;
      _answered = true;
      _currentSaveData = newData;
      _cardOwned = newCardOwned;
      _rewardApplied = newRewardApplied;
    });

    // 永続化は非同期で行う（UI更新をブロックしない）。
    widget.saveRepository.save(newData);
  }

  /// カード詳細画面へ遷移する。
  Future<void> _openCardDetail() async {
    if (widget.relatedCard == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: widget.relatedCard!,
          isOwned: true,
          relatedQuestion: widget.question,
          rewardService: widget.rewardService,
          saveRepository: widget.saveRepository,
          saveData: _currentSaveData,
        ),
      ),
    );
  }

  /// ホーム画面へ戻る。
  void _goHome() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = widget.question;
    final card = widget.relatedCard;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('今日の1問'),
          actions: const [],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // カテゴリ表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor(q.category).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _categoryLabel(q.category),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _categoryColor(q.category),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 問題文
              Text(
                q.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              // 選択肢
              ...List.generate(q.choices.length, (index) {
                final choice = q.choices[index];
                final isCorrect = index == q.answerIndex;
                final isSelected = _selectedChoice == index;
                Color? bgColor;
                Color? borderColor;
                Color? textColor;
                String? suffix;

                if (_answered) {
                  if (isCorrect) {
                    bgColor = Colors.green.withValues(alpha: 0.1);
                    borderColor = Colors.green;
                    textColor = Colors.green.shade800;
                    suffix = '  ✓ 正解';
                  } else if (isSelected) {
                    bgColor = Colors.red.withValues(alpha: 0.08);
                    borderColor = Colors.red.withValues(alpha: 0.5);
                    textColor = Colors.red.shade700;
                    suffix = '  ✗';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: _answered ? null : () => _answer(index),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor ?? cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor ??
                              (isSelected
                                  ? cs.primary
                                  : cs.outlineVariant.withValues(alpha: 0.5)),
                          width: isSelected && !_answered ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              choice,
                              style: TextStyle(
                                fontSize: 15,
                                color: textColor ?? cs.onSurface,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (suffix != null)
                            Text(
                              suffix,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              // 解説（回答後）
              if (_answered) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            '解説',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q.explanation,
                        style: TextStyle(
                          height: 1.6,
                          color: cs.onSurface.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.source_outlined,
                              size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '出典: ${q.sourceNote}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // カード獲得ブロック
                if (card != null) _cardRewardBlock(card, cs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// カード獲得ブロックを表示する。
  Widget _cardRewardBlock(HeeCard card, ColorScheme cs) {
    final isNew = _rewardApplied;
    final isOwned = _cardOwned;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNew ? Icons.auto_stories : Icons.check_circle_outline,
                size: 18,
                color: isNew ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                isNew ? '新しい知識カードを発見' : 'このカードは発見済みです',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isNew ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _openCardDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isOwned ? 'カードを読む' : '図鑑で見る'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _goHome,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('ホームへ戻る'),
                ),
              ),
            ],
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
