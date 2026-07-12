import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/bootstrap.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

void main() {
  testWidgets('bootstrap shows the app after all data loads', (tester) async {
    final repository = _RecoverableRepository(failing: false);

    await tester.pumpWidget(
      AppBootstrap(
        loadQuestions: () async => const [],
        loadCards: () async => const [],
        saveRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('へぇのタネ'), findsOneWidget);
    expect(find.text('利用可能な問題がありません'), findsOneWidget);
  });

  testWidgets('bootstrap retries content loading without discarding save data', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      AppBootstrap(
        loadQuestions: () async {
          attempts++;
          if (attempts == 1) throw const FormatException('broken questions');
          return const [];
        },
        loadCards: () async => const [],
        loadSaveData: () async => SaveData(onboardingCompleted: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('アプリを開始できませんでした'), findsOneWidget);
    expect(find.byKey(const ValueKey('bootstrap-reset-save')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('利用可能な問題がありません'), findsOneWidget);
  });

  testWidgets('bootstrap can reset a broken save and retry', (tester) async {
    final repository = _RecoverableRepository(failing: true);

    await tester.pumpWidget(
      AppBootstrap(
        loadQuestions: () async => const [],
        loadCards: () async => const [],
        saveRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bootstrap-reset-save')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bootstrap-reset-save')));
    await tester.pumpAndSettle();

    expect(repository.resetCount, 1);
    expect(find.text('利用可能な問題がありません'), findsOneWidget);
  });
}

class _RecoverableRepository extends SaveRepository {
  bool failing;
  int resetCount = 0;

  _RecoverableRepository({required this.failing});

  @override
  Future<SaveData> loadOrThrow() async {
    if (failing) {
      throw const SaveLoadException('保存データが壊れています');
    }
    return SaveData(onboardingCompleted: true);
  }

  @override
  Future<void> reset() async {
    resetCount++;
    failing = false;
  }
}
