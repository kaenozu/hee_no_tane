from pathlib import Path
import re


def replace_once(source: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, source, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"Expected one replacement for {label}, got {count}")
    return updated


def patch_daily_question_screen() -> None:
    path = Path("lib/features/question/daily_question_screen.dart")
    source = path.read_text()
    import_line = (
        "import 'package:hee_no_tane_app/application/daily_progress_service.dart';\n"
    )
    if import_line not in source:
        source = source.replace(
            "import 'package:flutter/material.dart';\n",
            "import 'package:flutter/material.dart';\n" + import_line,
            1,
        )

    replacement = r'''  Future<void> _doSave() async {
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
      final progressService = DailyProgressService(
        saveRepository: widget.saveRepository,
        rewardService: widget.rewardService,
      );
      final result = await progressService.submitAnswer(
        date: date,
        question: widget.question,
        card: widget.relatedCard,
      );
      _cardWasOwnedBeforeAnswer ??= result.cardWasOwnedBeforeAnswer;

      if (!mounted) return;
      setState(() {
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

  Future<void> _retrySave() async {'''
    source = replace_once(
        source,
        r"  Future<void> _doSave\(\) async \{.*?\n  Future<void> _retrySave\(\) async \{",
        replacement,
        "daily question save flow",
    )
    path.write_text(source)


def patch_home_screen() -> None:
    path = Path("lib/features/home/home_screen.dart")
    source = path.read_text()
    import_line = (
        "import 'package:hee_no_tane_app/application/daily_progress_service.dart';\n"
    )
    if import_line not in source:
        source = source.replace(
            "import 'package:flutter/material.dart';\n",
            "import 'package:flutter/material.dart';\n" + import_line,
            1,
        )

    replacement = r'''  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      var data = await widget.saveRepository.loadOrThrow();

      // Capture the provider value only once so the displayed date and the
      // assigned question cannot differ if midnight is crossed during load.
      final currentDateTime = widget.dailyQuestionService.currentDateTime();
      final date = widget.dailyQuestionService.currentDateSeed(currentDateTime);
      final progressService = DailyProgressService(
        saveRepository: widget.saveRepository,
        rewardService: widget.rewardService,
      );

      String? questionId;
      String? cardId;
      if (data.lastDailyQuestionDate == date &&
          data.lastDailyQuestionId.isNotEmpty &&
          data.lastDailyCardId.isNotEmpty) {
        questionId = data.lastDailyQuestionId;
        cardId = data.lastDailyCardId;
      } else if (data.dailyAssignmentDate == date &&
          data.dailyAssignmentQuestionId.isNotEmpty &&
          data.dailyAssignmentCardId.isNotEmpty) {
        questionId = data.dailyAssignmentQuestionId;
        cardId = data.dailyAssignmentCardId;
      } else {
        final generated = widget.dailyQuestionService.generateTodayQuestions(
          widget.allQuestions,
          allCards: widget.allCards,
          count: 1,
          dateTime: currentDateTime,
        );
        if (generated.isNotEmpty) {
          final generatedQuestion = generated.first;
          final generatedCard = _resolveCard(generatedQuestion.relatedCardId);
          if (generatedCard == null ||
              !_isReleaseApprovedPair(generatedQuestion, generatedCard)) {
            throw const SaveLoadException(
              '本日の問題とカードの組み合わせを確認できませんでした。',
            );
          }
          questionId = generatedQuestion.id;
          cardId = generatedCard.id;
        }
      }

      Question? question;
      HeeCard? card;
      if (questionId != null && cardId != null) {
        data = await progressService.ensureAssignment(
          date: date,
          questionId: questionId,
          cardId: cardId,
        );
        questionId = data.dailyAssignmentQuestionId;
        cardId = data.dailyAssignmentCardId;
        question = _resolveQuestion(questionId);
        card = _resolveCard(cardId);
        if (question == null ||
            card == null ||
            !_isReleaseApprovedPair(question, card)) {
          throw const SaveLoadException(
            '本日分として保存された問題が現在のコンテンツと一致しません。アプリを更新して再度お試しください。',
          );
        }

        if (data.lastDailyQuestionDate == date) {
          final exactCompletion = data.hasDailyCompletion(
            date: date,
            questionId: question.id,
            cardId: card.id,
          );
          final legacyCompletion =
              data.lastDailyQuestionId.isEmpty &&
              data.lastDailyCardId.isEmpty &&
              data.ownedCardIds.contains(card.id);
          if ((!exactCompletion && !legacyCompletion) ||
              !data.ownedCardIds.contains(card.id)) {
            throw const SaveLoadException(
              '本日の回答履歴とコンテンツが一致しません。アプリを更新して再度お試しください。',
            );
          }
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
    } on SaveException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    }
  }

  Question? _resolveQuestion'''
    source = replace_once(
        source,
        r"  Future<void> _load\(\) async \{.*?\n  Question\? _resolveQuestion",
        replacement,
        "home load flow",
    )
    path.write_text(source)


def patch_flutter_ci() -> None:
    path = Path(".github/workflows/flutter-ci.yml")
    source = path.read_text()
    step = """\n      - name: Validate generated content bundle\n        run: dart run tool/generate_content_bundle.dart --check\n"""
    marker = "      - name: Validate content\n        run: dart run tool/validate_content.dart\n"
    if step.strip() not in source:
        source = source.replace(marker, marker + step, 1)

    release_marker = (
        "      - name: Generate release blocker report\n"
        "        run: dart run tool/generate_release_blockers.dart\n"
    )
    release_step = (
        "\n      - name: Validate generated content bundle\n"
        "        run: dart run tool/generate_content_bundle.dart --check\n"
    )
    second_index = source.find(release_marker, source.find(release_marker) + 1)
    if second_index != -1:
        insert_at = second_index + len(release_marker)
        tail = source[insert_at:]
        if not tail.lstrip().startswith("- name: Validate generated content bundle"):
            source = source[:insert_at] + release_step + source[insert_at:]
    path.write_text(source)


def patch_release_metadata_validator() -> None:
    path = Path("tool/validate_release_metadata.dart")
    source = path.read_text()
    asset_check = """  _requireContains(
    pubspec,
    '- assets/data/content_bundle.json',
    'approved content bundle must be bundled as an asset',
    issues,
  );
"""
    marker = "  if (!File('assets/app_icon.png').existsSync()) {\n"
    if asset_check.strip() not in source:
        source = source.replace(marker, asset_check + marker, 1)

    required_marker = "    'assets/data/app_version.json',\n"
    if "    'assets/data/content_bundle.json',\n" not in source:
        source = source.replace(
            required_marker,
            required_marker + "    'assets/data/content_bundle.json',\n",
            1,
        )
    path.write_text(source)


patch_daily_question_screen()
patch_home_screen()
patch_flutter_ci()
patch_release_metadata_validator()
