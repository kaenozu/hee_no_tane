/// lib/data/repositories/price_comparison_repository.dart
///
/// 価格比較ドラフトを端末内へ保存・復元するリポジトリ。
library;

import 'dart:async';
import 'dart:convert';

import 'package:hee_no_tane_app/core/app_log.dart';
import 'package:hee_no_tane_app/data/models/price_comparison_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PriceComparisonStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

final class SharedPreferencesPriceComparisonStore
    implements PriceComparisonStore {
  final SharedPreferencesAsync _preferences;

  SharedPreferencesPriceComparisonStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

class PriceComparisonLoadException implements Exception {
  final String message;
  final Object? cause;

  const PriceComparisonLoadException(this.message, {this.cause});

  @override
  String toString() => 'PriceComparisonLoadException: $message';
}

class PriceComparisonSaveException implements Exception {
  final String message;
  final Object? cause;

  const PriceComparisonSaveException(this.message, {this.cause});

  @override
  String toString() => 'PriceComparisonSaveException: $message';
}

final class PriceComparisonRepository {
  static const String _key = 'hee_no_tane_price_comparison_draft_v1';
  static const int _schemaVersion = 1;

  final PriceComparisonStore _store;
  Future<void>? _operationTail;

  PriceComparisonRepository({PriceComparisonStore? store})
    : _store = store ?? SharedPreferencesPriceComparisonStore();

  Future<PriceComparisonDraft?> loadDraft() async {
    try {
      final raw = await _store.getString(_key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Draft root must be an object.');
      }
      final map = Map<String, dynamic>.from(decoded);
      if (map['version'] != _schemaVersion || map['draft'] is! Map) {
        throw const FormatException('Unsupported draft schema.');
      }
      return PriceComparisonDraft.fromJson(
        Map<String, dynamic>.from(map['draft'] as Map),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load price comparison draft: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw PriceComparisonLoadException(
        '保存した価格比較データを読み込めませんでした。',
        cause: error,
      );
    }
  }

  Future<void> saveDraft(PriceComparisonDraft draft) => _enqueue(() async {
    try {
      await _store.setString(
        _key,
        jsonEncode(<String, dynamic>{
          'version': _schemaVersion,
          'draft': draft.toJson(),
        }),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to save price comparison draft: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw PriceComparisonSaveException(
        '価格比較データを保存できませんでした。',
        cause: error,
      );
    }
  });

  Future<void> clearDraft() => _enqueue(() async {
    try {
      await _store.remove(_key);
    } catch (error, stackTrace) {
      debugPrint('Failed to clear price comparison draft: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw PriceComparisonSaveException(
        '価格比較データを削除できませんでした。',
        cause: error,
      );
    }
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final previous = _operationTail;
    final future = previous == null
        ? operation()
        : previous.then<T>((_) => operation());
    final tail = future.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _operationTail = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_operationTail, tail)) _operationTail = null;
      }),
    );
    return future;
  }
}
