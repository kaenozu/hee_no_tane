import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/application/daily_progress_service.dart';
import 'package:hee_no_tane_app/content_validation/content_release_policy.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';

class DailyAssignmentGate extends StatefulWidget {
  final List<Question> allQuestions;
  final List<HeeCard> allCards;
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final DailyQuestionService dailyQuestionService;
  final Future<void> Function()? onDataReset;

  const DailyAssignmentGate({
    super.key,
    required this.allQuestions,
    required this.allCards,
    required this.saveRepository,
    required this.rewardService,
    required this.dailyQuestionService,
    this.onDataReset,
  });

  @override
  State<DailyAssignmentGate> createState() => _DailyAssignmentGateState();
}

class _DailyAssignmentGateState extends State<DailyAssignmentGate> {
  late final AppLifecycleListener _lifecycleListener;
  DailyQuestionService? _pinnedService;
  String _assignedDate = '';
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _handleResume);
    unawaited(_load());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _handleResume() {
    final currentDate = widget.dailyQuestionService.currentDateSeed();
    if (!_loading && (_assignedDate != currentDate || _errorMessage != null)) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      var saveData = await widget.saveRepository.loadOrThrow();
      final currentDateTime = widget.dailyQuestionService.currentDateTime();
      final date = widget.dailyQuestionService.currentDateSeed(currentDateTime);

      String? questionId;
      String? cardId;
      if (saveData.lastDailyQuestionDate == date &&
          saveData.lastDailyQuestionId.isNotEmpty &&
          saveData.lastDailyCardId.isNotEmpty) {
        questionId = saveData.lastDailyQuestionId;
        cardId = saveData.lastDailyCardId;
      } else if (saveData.dailyAssignmentDate == date &&
          saveData.dailyAssignmentQuestionId.isNotEmpty &&
          saveData.dailyAssignmentCardId.isNotEmpty) {
        questionId = saveData.dailyAssignmentQuestionId;
        cardId = saveData.dailyAssignmentCardId;
      } else {
        final generated = widget.dailyQuestionService.generateTodayQuestions(
          widget.allQuestions,
          allCards: widget.allCards,
          count: 1,
          dateTime: currentDateTime,
        );
        if (generated.isNotEmpty) {
          questionId = generated.first.id;
          cardId = generated.first.relatedCardId;
        }
      }

      DailyQuestionService pinnedService = widget.dailyQuestionService;
      if (questionId != null && cardId != null) {
        final proposedQuestion = _questionById(questionId);
        final proposedCard = _cardById(cardId);
        _requirePlayablePair(proposedQuestion, proposedCard);

        final progressService = DailyProgressService(
          saveRepository: widget.saveRepository,
          rewardService: widget.rewardService,
        );
        saveData = await progressService.ensureAssignment(
          date: date,
          questionId: proposedQuestion!.id,
          cardId: proposedCard!.id,
        );

        final assignedQuestion = _questionById(
          saveData.dailyAssignmentQuestionId,
        );
        final assignedCard = _cardById(saveData.dailyAssignmentCardId);
        _requirePlayablePair(assignedQuestion, assignedCard);
        pinnedService = _PinnedDailyQuestionService(
          delegate: widget.dailyQuestionService,
          assignedDate: date,
          assignedQuestion: assignedQuestion!,
        );
      }

      if (!mounted) return;
      setState(() {
        _assignedDate = date;
        _pinnedService = pinnedService;
        _loading = false;
      });
    } on SaveLoadException catch (error) {
      _showError(error.message);
    } on SaveException catch (error) {
      _showError(error.message);
    } on FormatException catch (error) {
      _showError(error.message.toString());
    }
  }

  void _requirePlayablePair(Question? question, HeeCard? card) {
    if (question == null ||
        card == null ||
        !ContentReleasePolicy.isPlayablePair(question, card)) {
      throw const FormatException(
        '本日分として保存された問題が現在の公開コンテンツと一致しません。アプリを更新して再度お試しください。',
      );
    }
  }

  Question? _questionById(String id) {
    for (final question in widget.allQuestions) {
      if (question.id == id) return question;
    }
    return null;
  }

  HeeCard? _cardById(String id) {
    for (final card in widget.allCards) {
      if (card.id == id) return card;
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                const Text('今日の問題を準備できませんでした'),
                const SizedBox(height: 8),
                Text(errorMessage, textAlign: TextAlign.center),
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

    final service = _pinnedService;
    if (service == null) {
      return const Scaffold(body: Center(child: Text('公開可能な問題がありません')));
    }

    return HomeScreen(
      key: ValueKey<String>('home-$_assignedDate'),
      allQuestions: widget.allQuestions,
      allCards: widget.allCards,
      saveRepository: widget.saveRepository,
      rewardService: widget.rewardService,
      dailyQuestionService: service,
      onDataReset: widget.onDataReset,
    );
  }
}

final class _PinnedDailyQuestionService extends DailyQuestionService {
  final DailyQuestionService delegate;
  final String assignedDate;
  final Question assignedQuestion;

  const _PinnedDailyQuestionService({
    required this.delegate,
    required this.assignedDate,
    required this.assignedQuestion,
  });

  @override
  DateTime currentDateTime() => delegate.currentDateTime();

  @override
  String currentDateSeed([DateTime? dateTime]) =>
      delegate.currentDateSeed(dateTime);

  @override
  List<Question> generateTodayQuestions(
    List<Question> allQuestions, {
    required List<HeeCard> allCards,
    int rotation = 0,
    int count = 3,
    DateTime? dateTime,
  }) {
    final date = delegate.currentDateSeed(
      dateTime ?? delegate.currentDateTime(),
    );
    if (date == assignedDate && count > 0) {
      return <Question>[assignedQuestion];
    }
    return delegate.generateTodayQuestions(
      allQuestions,
      allCards: allCards,
      rotation: rotation,
      count: count,
      dateTime: dateTime,
    );
  }

  @override
  List<Question> generateQuestions(
    String dateSeed,
    List<Question> allQuestions, {
    required List<HeeCard> allCards,
    int rotation = 0,
    int count = 3,
  }) {
    if (dateSeed == assignedDate && count > 0) {
      return <Question>[assignedQuestion];
    }
    return delegate.generateQuestions(
      dateSeed,
      allQuestions,
      allCards: allCards,
      rotation: rotation,
      count: count,
    );
  }
}
