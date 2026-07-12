/// lib/data/repositories/save_repository.dart
///
/// セーブデータの永続化（SharedPreferences）。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// セーブデータ読込時の例外。
class SaveLoadException implements Exception {
  final String message;
  final Object? cause;
  const SaveLoadException(this.message, {this.cause});

  @override
  String toString() => 'SaveLoadException: $message (cause: $cause)';
}

/// セーブデータ保存・削除時の例外。
class SaveException implements Exception {
  final String message;
  final Object? cause;
  const SaveException(this.message, {this.cause});

  @override
  String toString() => 'SaveException: $message (cause: $cause)';
}

class SaveRepository {
  static const _key = 'hee_no_tane_save_data';

  /// Pending serialized operation. Null when no operation is running or queued.
  Future<void>? _operationTail;

  /// 既存画面向けのベストエフォート読込。
  ///
  /// 読込に失敗した場合は空のSaveDataを返す。書き込み前や重要な画面では
  /// [loadOrThrow]を使用し、破損データを空データで上書きしないこと。
  Future<SaveData> load() async {
    try {
      return await loadOrThrow();
    } on SaveLoadException {
      return SaveData();
    }
  }

  /// 読込失敗を呼び出し側へ通知する厳格な読込。
  ///
  /// 保存データが存在しない場合は正常な初期状態として空のSaveDataを返す。
  Future<SaveData> loadOrThrow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return SaveData();
      return SaveData.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('Failed to load save data: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw SaveLoadException(
        'データの読み込みに失敗しました。もう一度お試しください。',
        cause: e,
      );
    }
  }

  Future<void> save(SaveData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final succeeded = await prefs.setString(_key, json.encode(data.toJson()));
      if (!succeeded) {
        throw const SaveException('データの保存に失敗しました。もう一度お試しください。');
      }
    } on SaveException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Failed to save data: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw SaveException(
        'データの保存に失敗しました。もう一度お試しください。',
        cause: e,
      );
    }
  }

  /// Atomically applies [updater] to the latest save data.
  ///
  /// Calls on the same repository instance run in FIFO order. A failed update
  /// is reported to its caller but does not block later operations.
  Future<SaveData> update(SaveData Function(SaveData current) updater) {
    return _enqueue(() => _runUpdate(updater));
  }

  Future<SaveData> _runUpdate(
    SaveData Function(SaveData current) updater,
  ) async {
    final current = await loadOrThrow();
    final updated = updater(current);
    await save(updated);
    return updated;
  }

  /// セーブデータを削除する。
  ///
  /// 進行中の更新がある場合は完了を待ち、その後の更新も削除完了後に実行する。
  /// 削除に失敗した場合は[SaveException]を通知する。
  Future<void> reset() {
    return _enqueue(_runReset);
  }

  Future<void> _runReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hadData = prefs.containsKey(_key);
      final succeeded = await prefs.remove(_key);
      if (hadData && !succeeded) {
        throw const SaveException('データの初期化に失敗しました。もう一度お試しください。');
      }
    } on SaveException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Failed to reset save data: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw SaveException(
        'データの初期化に失敗しました。もう一度お試しください。',
        cause: e,
      );
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final previous = _operationTail;
    final result = previous == null
        ? operation()
        : previous.then((_) => operation());

    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _operationTail = tail;
    tail.whenComplete(() {
      if (identical(_operationTail, tail)) {
        _operationTail = null;
      }
    });
    return result;
  }
}
