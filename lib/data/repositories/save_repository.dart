/// lib/data/repositories/save_repository.dart
///
/// セーブデータの永続化（SharedPreferences）。
library;

///
/// 関連:
///   - ../../domain/models/save_data.dart
///   - ../../domain/services/reward_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

/// セーブデータ読込時の例外。
class SaveLoadException implements Exception {
  final String message;
  final Object? cause;
  const SaveLoadException(this.message, {this.cause});

  @override
  String toString() => 'SaveLoadException: $message (cause: $cause)';
}

/// セーブデータ保存時の例外。
class SaveException implements Exception {
  final String message;
  final Object? cause;
  const SaveException(this.message, {this.cause});

  @override
  String toString() => 'SaveException: $message (cause: $cause)';
}

class SaveRepository {
  static const _key = 'hee_no_tane_save_data';

  /// update() calls are chained so load-transform-save runs one at a time.
  Future<void> _updateTail = Future<void>.value();

  /// 既存画面向けのベストエフォート読込。
  ///
  /// 読込に失敗した場合は従来どおり空のSaveDataを返す。
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
      throw SaveLoadException('データの読み込みに失敗しました。もう一度お試しください。', cause: e);
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
      throw SaveException('データの保存に失敗しました。もう一度お試しください。', cause: e);
    }
  }

  /// Atomically applies [updater] to the latest save data.
  ///
  /// Calls on the same repository instance run in FIFO order. A failed update
  /// is reported to its caller but does not block later updates.
  Future<SaveData> update(SaveData Function(SaveData current) updater) {
    final operation = _updateTail.then((_) async {
      final current = await loadOrThrow();
      final updated = updater(current);
      await save(updated);
      return updated;
    });

    _updateTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e, stackTrace) {
      debugPrint('Failed to reset save data: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
