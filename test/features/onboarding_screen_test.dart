import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';
import 'package:hee_no_tane_app/features/onboarding/onboarding_screen.dart';

import '../helpers/fake_save_repository.dart';

void main() {
  group('SaveData onboarding migration', () {
    test('new save data starts with onboarding incomplete', () {
      expect(SaveData().onboardingCompleted, isFalse);
    });

    test('onboarding completion survives JSON round-trip', () {
      final restored = SaveData.fromJson(
        SaveData(onboardingCompleted: true).toJson(),
      );

      expect(restored.onboardingCompleted, isTrue);
    });

    test('legacy save with user progress is treated as completed', () {
      final restored = SaveData.fromJson({
        'version': 2,
        'totalBrowseCount': 1,
        'ownedCardIds': <String>[],
      });

      expect(restored.onboardingCompleted, isTrue);
    });

    test('legacy empty save remains incomplete', () {
      final restored = SaveData.fromJson({
        'version': 2,
        'ownedCardIds': <String>[],
      });

      expect(restored.onboardingCompleted, isFalse);
    });
  });

  group('first-run onboarding', () {
    testWidgets('shows onboarding for an incomplete save', (tester) async {
      final repository = FakeSaveRepository();
      final data = SaveData();
      repository.setLoadedData(data);

      await tester.pumpWidget(_buildApp(data, repository));
      await tester.pump();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('1日1問、約30秒'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('shows home immediately for a completed save', (tester) async {
      final repository = FakeSaveRepository();
      final data = SaveData(onboardingCompleted: true);
      repository.setLoadedData(data);

      await tester.pumpWidget(_buildApp(data, repository));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('承認済みの問題がありません'), findsOneWidget);
    });

    testWidgets('completes all pages, persists, and opens home', (
      tester,
    ) async {
      final repository = FakeSaveRepository();
      final data = SaveData();
      repository.setLoadedData(data);

      await tester.pumpWidget(_buildApp(data, repository));
      await tester.pump();

      await _advanceToLastPage(tester);
      await tester.tap(find.byKey(const ValueKey('onboarding-start')));
      await tester.pumpAndSettle();

      expect(repository.saveCallCount, 1);
      expect(repository.lastSavedData?.onboardingCompleted, isTrue);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('prevents duplicate completion while saving', (tester) async {
      final repository = FakeSaveRepository();
      final data = SaveData();
      repository.setLoadedData(data);
      repository.holdNextSave();

      await tester.pumpWidget(_buildApp(data, repository));
      await tester.pump();
      await _advanceToLastPage(tester);

      final startButton = find.byKey(const ValueKey('onboarding-start'));
      await tester.tap(startButton);
      await tester.pump();
      await tester.tap(startButton);
      await tester.pump();

      expect(repository.saveCallCount, 1);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.completeSave();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('stays on onboarding and shows an error when saving fails', (
      tester,
    ) async {
      final repository = FakeSaveRepository();
      final data = SaveData();
      repository.setLoadedData(data);
      repository.holdNextSave();

      await tester.pumpWidget(_buildApp(data, repository));
      await tester.pump();
      await _advanceToLastPage(tester);

      await tester.tap(find.byKey(const ValueKey('onboarding-start')));
      await tester.pump();
      repository.failSave();
      await tester.pumpAndSettle();

      expect(repository.saveCallCount, 1);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('保存に失敗しました'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('onboarding-start')),
            )
            .onPressed,
        isNotNull,
      );
    });
  });
}

Widget _buildApp(SaveData data, FakeSaveRepository repository) {
  return HeeNoTaneApp(
    allQuestions: const [],
    allCards: const [],
    saveData: data,
    saveRepository: repository,
    rewardService: RewardService(),
  );
}

Future<void> _advanceToLastPage(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
  expect(find.text('答えるとカードを獲得'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
  expect(find.text('少しずつ知識を育てる'), findsOneWidget);
  expect(find.byKey(const ValueKey('onboarding-start')), findsOneWidget);
}
