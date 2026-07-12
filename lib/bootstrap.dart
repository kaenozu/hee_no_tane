/// lib/bootstrap.dart
///
/// アプリ起動時のコンテンツ・セーブデータ読込と、失敗時の復旧UIを管理する。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/data/repositories/card_repository.dart';
import 'package:hee_no_tane_app/data/repositories/question_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

typedef QuestionLoader = Future<List<Question>> Function();
typedef CardLoader = Future<List<HeeCard>> Function();
typedef SaveDataLoader = Future<SaveData> Function();

class AppBootstrap extends StatefulWidget {
  final QuestionLoader? loadQuestions;
  final CardLoader? loadCards;
  final SaveDataLoader? loadSaveData;
  final SaveRepository? saveRepository;
  final RewardService? rewardService;

  const AppBootstrap({
    super.key,
    this.loadQuestions,
    this.loadCards,
    this.loadSaveData,
    this.saveRepository,
    this.rewardService,
  });

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final SaveRepository _saveRepository;
  late final RewardService _rewardService;

  List<Question>? _questions;
  List<HeeCard>? _cards;
  SaveData? _saveData;
  Object? _error;
  bool _loading = true;
  bool _resetting = false;
  bool _canResetSave = false;

  @override
  void initState() {
    super.initState();
    _saveRepository = widget.saveRepository ?? SaveRepository();
    _rewardService = widget.rewardService ?? RewardService();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _canResetSave = false;
      });
    }

    final loadQuestions =
        widget.loadQuestions ?? QuestionRepository().loadAll;
    final loadCards = widget.loadCards ?? CardRepository().loadAll;
    final loadSaveData = widget.loadSaveData ?? _saveRepository.loadOrThrow;

    try {
      final results = await Future.wait<Object>([
        loadQuestions(),
        loadCards(),
        loadSaveData(),
      ]);
      if (!mounted) return;
      setState(() {
        _questions = results[0] as List<Question>;
        _cards = results[1] as List<HeeCard>;
        _saveData = results[2] as SaveData;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to bootstrap app: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _error = error;
        _canResetSave = error is SaveLoadException;
        _loading = false;
      });
    }
  }

  Future<void> _resetSaveAndRetry() async {
    if (_resetting) return;
    setState(() => _resetting = true);
    try {
      await _saveRepository.reset();
      if (!mounted) return;
      setState(() => _resetting = false);
      await _load();
    } on SaveException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _resetting = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to reset save data during bootstrap: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _error = error;
        _resetting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final cards = _cards;
    final saveData = _saveData;

    if (questions != null && cards != null && saveData != null) {
      return HeeNoTaneApp(
        allQuestions: questions,
        allCards: cards,
        saveData: saveData,
        saveRepository: _saveRepository,
        rewardService: _rewardService,
      );
    }

    return MaterialApp(
      title: 'へぇのタネ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B8A5B),
        fontFamily: 'NotoSansJP',
      ),
      home: _BootstrapScreen(
        loading: _loading,
        resetting: _resetting,
        error: _error,
        canResetSave: _canResetSave,
        onRetry: _load,
        onResetSave: _resetSaveAndRetry,
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  final bool loading;
  final bool resetting;
  final Object? error;
  final bool canResetSave;
  final Future<void> Function() onRetry;
  final Future<void> Function() onResetSave;

  const _BootstrapScreen({
    required this.loading,
    required this.resetting,
    required this.error,
    required this.canResetSave,
    required this.onRetry,
    required this.onResetSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    error == null
                        ? Icons.auto_stories_rounded
                        : Icons.error_outline_rounded,
                    size: 72,
                    color: error == null ? cs.primary : cs.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    error == null ? 'へぇのタネ' : 'アプリを開始できませんでした',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error == null
                        ? 'データを読み込んでいます'
                        : canResetSave
                            ? '保存データを読み込めませんでした。再試行しても直らない場合は、保存データを初期化できます。'
                            : 'アプリ内の問題またはカードデータを読み込めませんでした。アプリを再起動するか、再試行してください。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  if (loading || resetting)
                    const CircularProgressIndicator()
                  else if (error != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('bootstrap-retry'),
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('再試行'),
                      ),
                    ),
                    if (canResetSave) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('bootstrap-reset-save'),
                          onPressed: onResetSave,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('保存データを初期化'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '初期化すると、獲得カード・連続日数・設定が削除されます。',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
