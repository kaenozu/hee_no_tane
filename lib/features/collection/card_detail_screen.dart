/// lib/features/collection/card_detail_screen.dart
///
/// カード詳細画面。読書に特化したUI。
library;
/// タイトル → 概要 → 詳細 → 出典 → 関連カード → クイズ のフロー。
/// 初回閲覧時に自動で図鑑に追加される。
///
/// 関連:
///   - ../collection/category_util.dart
///   - ../../domain/services/reward_service.dart
///   - ../../data/repositories/save_repository.dart

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/collection/category_util.dart';

class CardDetailScreen extends StatefulWidget {
  final HeeCard card;
  final bool isOwned;
  final Question? relatedQuestion;
  final RewardService rewardService;
  final SaveRepository saveRepository;
  final SaveData saveData;

  const CardDetailScreen({
    super.key,
    required this.card,
    required this.isOwned,
    this.relatedQuestion,
    required this.rewardService,
    required this.saveRepository,
    required this.saveData,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _justUnlocked = false;
  int? _selectedChoice;
  bool _answered = false;

  bool get _showRealContent => _justUnlocked || widget.isOwned;

  @override
  void initState() {
    super.initState();
    _checkFirstView();
  }

  Future<void> _checkFirstView() async {
    if (widget.isOwned) return;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    var data = widget.saveData;
    data = widget.rewardService.applyReward(data, widget.card);
    data = widget.rewardService.updatePlayStats(data, dateStr);
    await widget.saveRepository.save(data);
    if (!mounted) return;
    setState(() => _justUnlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryLabel(widget.card.category)),
        actions: [
          if (_justUnlocked)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    '図鑑に追加',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_justUnlocked)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        '新しい知識を収集しました',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: categoryColor(widget.card.category)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 32,
                  color: categoryColor(widget.card.category),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _showRealContent ? widget.card.title : '???',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.card.rarity == 'rare' && _showRealContent)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 14, color: cs.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'レア',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_showRealContent) ...[
              _sectionTitle('へぇポイント'),
              const SizedBox(height: 8),
              Text(
                widget.card.shortText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('くわしい知識'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.card.detailText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.source_outlined,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text(
                    '出典: ${widget.card.sourceNote}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'このカードはまだ获得していません',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (widget.relatedQuestion != null && _showRealContent) ...[
              _quizSection(widget.relatedQuestion!, cs),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _quizSection(Question question, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '覚えてた？',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(question.choices.length, (index) {
              final choice = question.choices[index];
              final isCorrect = index == question.answerIndex;
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
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: _answered
                      ? null
                      : () => setState(() {
                            _selectedChoice = index;
                            _answered = true;
                          }),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor ?? cs.surface,
                      borderRadius: BorderRadius.circular(10),
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
            if (_answered) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: cs.primary),
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
                    const SizedBox(height: 6),
                    Text(
                      question.explanation,
                      style: TextStyle(
                        height: 1.5,
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '今日もひとつ賢くなりました',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
