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
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/core/date_utils.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';

/// 毎日の1問クイズ画面。
///
/// [question] 今日の問題。
/// [relatedCard] 問題に関連するカード。
/// [saveRepository] セーブデータ永続化。
/// [rewardService] カード獲得ロジック。
class DailyQuestionScreen extends StatefulWidget {
  final Question question;
  final HeeCard? relatedCard;
  final SaveRepository saveRepository;
  final RewardService rewardService;

  const DailyQuestionScreen({
    super.key,
    required this.question,
    this.relatedCard,
    required this.saveRepository,
    required this.rewardService,
  });

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  /// 選択された選択肢のインデックス。null = 未選択。
  int? _selectedAnswerIndex;

  /// 保存処理中か。
  bool _saving = false;

  /// 永続化が成功したか。
  bool _saveSucceeded = false;

  /// 保存エラーメッセージ（null = エラーなし）。
  String? _saveError;

  /// 回答日。保存失敗後の再試行でも同じ日付を使用する。
  String? _answerDate;

  /// 回答処理開始時点で関連カードを所有していたか。
  bool? _cardWasOwnedBeforeAnswer;

  bool get _hasAnswered => _selectedAnswerIndex != null;
  bool get _hasUnsavedAnswer => _hasAnswered && !_saveSucceeded;
  bool get _canLeave => !_hasUnsavedAnswer && !_saving;
  bool get _canNavigate => _saveSucceeded;
  bool get _canAnswer => !_hasAnswered && !_saving;

  /// 解答を処理し、Repository上の最新データへ回答差分を適用する。
  Future<void> _answer(int index) async {
    if (!_canAnswer) return;

    setState(() {
      _selectedAnswerIndex = index;
      _saving = true;
      _saveError = null;
      _answerDate = todayDateString();
    });

    await _doSave();
  }

  /// 保存を実行する。（初回回答・再試行の共通処理）
  Future<void> _doSave() async {
    final dateStr = _answerDate;
    if (dateStr == null) return;

    try {
      await widget.saveRepository.update((current) {
        final card = widget.relatedCard;

        // 保存成功後に応答を受け取れなかった場合の再試行を冪等化する。
        if (current.lastDailyQuestionDate == dateStr) {
          _cardWasOwnedBeforeAnswer ??= true;
          return current;
        }

        if (card != null) {
          _cardWasOwnedBeforeAnswer ??= current.ownedCardIds.contains(card.id);
        }

        var updated = widget.rewardService.updatePlayStats(current, dateStr);
        updated = updated.copyWith(lastDailyQuestionDate: dateStr);

        if (card != null && !current.ownedCardIds.contains(card.id)) {
          updated = widget.rewardService.applyReward(updated, card);
        }
        return updated;
      });

      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSucceeded = true;
        _saveError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is SaveException
          ? e.message
          : e is SaveLoadException
          ? e.message
          : '回答の保存に失敗しました。もう一度お試しください。';
      setState(() {
        _saving = false;
        _saveSucceeded = false;
        _saveError = message;
      });
    }
  }

  /// 同じ回答日でupdateを再実行し、保存済みなら差分を適用しない。
  Future<void> _retrySave() async {
    if (_saveSucceeded || _saving || _answerDate == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    await _doSave();
  }

  Future<void> _openCardDetail() async {
    if (!_canNavigate || widget.relatedCard == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: widget.relatedCard!,
          isOwned: true,
          relatedQuestion: widget.question,
          rewardService: widget.rewardService,
          saveRepository: widget.saveRepository,
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = widget.question;
    final card = widget.relatedCard;

    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _canLeave) _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('今日の1問'),
          automaticallyImplyLeading: _canLeave,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _categoryBadge(q.category, cs),
              const SizedBox(height: 16),
              Text(
                q.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(q.choices.length, (index) {
                return _choiceItem(q, index, cs);
              }),
              if (_hasAnswered) ...[
                const SizedBox(height: 8),
                _explanationBlock(q, cs),
                const SizedBox(height: 20),
                if (_saving) _savingIndicator(),
                if (_saveError != null) _errorBlock(cs),
                if (_saveSucceeded && card != null) _cardRewardBlock(card, cs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryBadge(String category, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _categoryColor(category).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _categoryLabel(category),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _categoryColor(category),
        ),
      ),
    );
  }

  Widget _choiceItem(Question q, int index, ColorScheme cs) {
    final choice = q.choices[index];
    final isCorrect = index == q.answerIndex;
    final isSelected = _selectedAnswerIndex == index;
    Color? bgColor;
    Color? borderColor;
    Color? textColor;
    String? suffix;

    if (_hasAnswered) {
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
        onTap: _canAnswer ? () => _answer(index) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor ?? cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  borderColor ??
                  (isSelected && !_hasAnswered
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.5)),
              width: isSelected && !_hasAnswered ? 1.5 : 1,
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
  }

  Widget _explanationBlock(Question q, ColorScheme cs) {
    return Container(
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
              Icon(
                Icons.source_outlined,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
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
    );
  }

  Widget _savingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('回答を保存しています...'),
          ],
        ),
      ),
    );
  }

  Widget _errorBlock(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '保存エラー',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _saveError!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _retrySave,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('再試行'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// カード獲得ブロックを表示する。
  /// 保存成功後にのみ表示される。
  Widget _cardRewardBlock(HeeCard card, ColorScheme cs) {
    final isNew = !(_cardWasOwnedBeforeAnswer ?? true);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
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
                  color: isNew
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _canNavigate ? _openCardDetail : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isNew ? '図鑑で見る' : 'カードを読む'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _canNavigate ? _goHome : null,
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
