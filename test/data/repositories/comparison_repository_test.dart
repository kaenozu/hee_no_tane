/// test/data/repositories/comparison_repository_test.dart
///
/// schemaVersion付き比較履歴が別インスタンスから復元できることを検証する。
///
/// 関連:
///   - lib/data/repositories/comparison_repository.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/comparison_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';

void main() {
  test('保存後に再生成したRepositoryから比較結果を読み込める', () async {
    final store = _MemoryStore();
    final repository = ComparisonRepository(store: store);
    const offers = <Offer>[
      Offer(
        id: 'a', productName: 'A', storeName: 'A店', price: 500,
        taxIncluded: true, taxRate: 0.10, earnedPoints: 0,
      ),
      Offer(
        id: 'b', productName: 'B', storeName: 'B店', price: 400,
        taxIncluded: true, taxRate: 0.10, earnedPoints: 0,
      ),
    ];

    await repository.save(offers);
    final restored = await ComparisonRepository(store: store).loadAll();

    expect(restored, hasLength(1));
    expect(restored.single.offers.map((offer) => offer.id), <String>['a', 'b']);
    expect(restored.single.result.bestId, 'b');
    expect(store.values.values.single, contains('"schemaVersion":1'));
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
