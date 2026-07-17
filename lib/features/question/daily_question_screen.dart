/// Daily single-question flow.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/application/daily_progress_service.dart';
import 'package:hee_no_tane_app/core/date_utils.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/category_util.dart';

typedef QuestionDateProvider = DateTime Function();

DateTime _systemDateProvider() => DateTime.now();

class DailyQuestionScreen extends StatefulWidget {
  final Question question;
  final String? questionDate;
  final HeeCard? relatedCard;
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final DailyProgressService? dailyProgressService;
  final QuestionDateProvider dateProvider;

  const DailyQuestionScreen({
    super.key,
    required this.question,
    this.questionDate,
    this.relatedCard,
    required this.saveRepository,
    required this.rewardService,
    this.dailyProgressService,
    this.dateProvider = _systemDateProvider,
  });

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  DailyProgressService get _dailyProgressService =>
      widget.dailyProgressService ??
      DailyProgressService(
        saveRepository: widget.saveRepository,
        rewardService: widget.rewardService,
      );

  int? _selectedAnswerIndex;
  bool _saving = false;
  bool _saveSucceeded = false;
  String? _saveError;
  String? _answerDate;
  bool? _cardWasOwnedBeforeAnswer;

  bool get _hasAnswered => _selectedAnswerIndex != null;
  bool get _hasUnsavedAnswer => _hasAnswered && !_saveSucceeded;
  bool get _canLeave => !_hasUnsavedAnswer && !_saving;
  bool get _canNavigate => _saveSucceeded;
  bool get _canAnswer => !_hasAnswered && !_saving;

  Future<void> _answer(int index) async {
    if (!_canAnswer) return;

    final currentDate = calendarDateString(widget.dateProvider());
    final expectedDate = widget.questionDate;
    if (expectedDate != null && expectedDate != currentDate) {
      setState(() {
        _selectedAnswerIndex = index;
        _saving = false;
        _saveSucceeded = false;
        _answerDate = null;
        _saveError = '日付が変わりました。回答は保存されていません。ホームへ戻って今日の問題を開いてください。';
      });
      return;
    }

    setState(() {
      _selectedAnswerIndex = index;
      _saving = true;
      _saveError = null;
      _answerDate = expectedDate ?? currentDate;
    });
    await _doSave();
  }

  Future<void> _doSave() async {
    final date = _answerDate;
    if (date == null) return;

    final expectedDate = widget.questionDate;
    final currentDate = calendarDateString(widget.dateProvider());
    if (expectedDate != null &&
        (expectedDate != currentDate || date != currentDate)) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSucceeded = false;
        _answerDate = null;
        _saveError = '日付が変わりました。回答は保存されていません。ホームへ戻って今日の問題を開いてください。';
      });
      return;
    }

    try {
      final result = await _dailyProgressService.submitAnswer(
        date: date,
        question: widget.question,
        card: widget.relatedCard,
      );

      if (!mounted) return;
      setState(() {
        _cardWasOwnedBeforeAnswer = result.cardWasOwnedBeforeAnswer;
        _saving = false;
        _saveSucceeded = true;
        _saveError = null;
      });
    } catch (error) {
      if (!mounted) return;
      final String message;
      if (error is SaveException) {
        message = error.message;
      } else if (error is SaveLoadException) {
        message = error.message;
      } else {
        message = '回答の保存に失敗しました。もう一度お試しください。';
      }
      setState(() {
        _saving = false;
        _saveSucceeded = false;
        _saveError = message;
      });
    }
  }

  Future<void> _retrySave() async {
    if (_saveSucceeded || _saving || _answerDate == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    await _doSave();
  }

  Future<void> _confirmDiscardAndLeave() async {
    if (_saving || !_hasUnsavedAnswer) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('回答を破棄しますか？'),
        content: const Text('回答結果は保存されていません。破棄してホームへ戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('破棄して戻る'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _goHome();
  }

  Future<void> _openCardDetail() async {
    final card = widget.relatedCard;
    if (!_canNavigate || card == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(
          card: card,
          isOwned: true,
          relatedQuestion: widget.question,
          rewardService: widget.rewardService,
          saveRepository: widget.saveRepository,
        ),
      ),
    );
  }

  void _goHome() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final question = widget.question;
    final card = widget.relatedCard;
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving && _hasUnsavedAnswer) {
          unawaited(_confirmDiscardAndLeave());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('今日の1問'),
          automaticallyImplyLeading: !_saving,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _categoryBadge(question.category),
              const SizedBox(height: 16),
              Text(
                question.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < question.choices.length; index++)
                _choiceItem(question, index, cs),
              if (_hasAnswered) ...[
                const SizedBox(height: 8),
                _explanationBlock(question, cs),
                const SizedBox(height: 20),
                if (_saving) _savingIndicator(),
                if (_saveError != null) _errorBlock(),
                if (_saveSucceeded && card != null) _cardRewardBlock(card, cs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryBadge(String category) {
    final color = categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoryLabel(category),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _choiceItem(Question question, int index, ColorScheme cs) {
    final choice = question.choices[index];
    final isCorrect = index == question.answerIndex;
    final isSelected = _selectedAnswerIndex == index;
    Color? background;
    Color? border;
    Color? textColor;
    String? suffix;
    if (_hasAnswered) {
      if (isCorrect) {
        background = Colors.green.withValues(alpha: 0.1);
        border = Colors.green;
        textColor = Colors.green.shade800;
        suffix = '✓ 正解';
      } else if (isSelected) {
        background = Colors.red.withValues(alpha: 0.08);
        border = Colors.red.withValues(alpha: 0.5);
        textColor = Colors.red.shade700;
        suffix = '✗';
      }
    }

    final semantics = _hasAnswered
        ? '$choice${isCorrect
              ? '、正解'
              : isSelected
              ? '、選択した不正解'
              : ''}'
        : choice;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        enabled: _canAnswer,
        selected: isSelected,
        label: semantics,
        child: Material(
          color: background ?? cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: border ?? cs.outlineVariant.withValues(alpha: 0.5),
              width: isSelected && !_hasAnswered ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            key: ValueKey('answer-choice-$index'),
            onTap: _canAnswer ? () => _answer(index) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor ?? cs.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
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
        ),
      ),
    );
  }

  Widget _explanationBlock(Question question, ColorScheme cs) {
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
            question.explanation,
            style: TextStyle(
              height: 1.6,
              color: cs.onSurface.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '出典: ${question.sourceNote}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savingIndicator() => const Center(
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

  Widget _errorBlock() => Container(
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
        const Text(
          '保存エラー',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
        ),
        const SizedBox(height: 8),
        Text(_saveError!, style: TextStyle(color: Colors.red.shade700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_answerDate != null)
              FilledButton.icon(
                onPressed: _retrySave,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('再試行'),
              ),
            OutlinedButton.icon(
              onPressed: _confirmDiscardAndLeave,
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text('破棄してホームへ戻る'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _cardRewardBlock(HeeCard card, ColorScheme cs) {
    final isNew = !(_cardWasOwnedBeforeAnswer ?? true);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNew ? '新しい知識カードを発見' : 'このカードは発見済みです',
            style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary),
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
                  child: Text(isNew ? '図鑑で見る' : 'カードを読む'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _canNavigate ? _goHome : null,
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
