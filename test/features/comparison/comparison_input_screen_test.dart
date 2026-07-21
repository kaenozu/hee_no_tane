/// test/features/comparison/comparison_input_screen_test.dart
///
/// 2件の入力から比較結果画面へ遷移し、結果を保存できることを検証する。
///
/// 関連:
///   - lib/features/comparison/comparison_input_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/comparison_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/comparison/comparison_input_screen.dart';

void main() {
  testWidgets('2商品を入力して比較し保存できる', (tester) async {
    final store = _MemoryStore();
    final repository = ComparisonRepository(store: store);
    await tester.pumpWidget(
      MaterialApp(home: ComparisonInputScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('offer-offer-1-product')), '商品A');
    await tester.enterText(find.byKey(const Key('offer-offer-1-store')), 'A店');
    await tester.enterText(find.byKey(const Key('offer-offer-1-price')), '500');
    await tester.enterText(find.byKey(const Key('offer-offer-2-product')), '商品B');
    await tester.enterText(find.byKey(const Key('offer-offer-2-store')), 'B店');
    await tester.enterText(find.byKey(const Key('offer-offer-2-price')), '400');

    await tester.tap(find.byKey(const Key('compare-button')));
    await tester.pumpAndSettle();

    expect(find.text('比較結果'), findsOneWidget);
    expect(find.textContaining('商品B'), findsWidgets);

    await tester.tap(find.text('比較結果を保存'));
    await tester.pumpAndSettle();

    expect(find.text('保存済み'), findsOneWidget);
    expect(await repository.loadAll(), hasLength(1));
  });
}

class _MemoryStore implements PreferenceStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
