/// SharedPreferences-backed persistent state.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaveLoadException implements Exception {
  final String message;
  final Object? cause;
  const SaveLoadException(this.message, {this.cause});

  @override
  String toString() => 'SaveLoadException: $message (cause: $cause)';
}

class SaveException implements Exception {
  final String message;
  final Object? cause;
  const SaveException(this.message, {this.cause});

  @override
  String toString() => 'SaveException: $message (cause: $cause)';
}

class SaveRepository {
  static const _key = 'hee_no_tane_save_data';
  Future<void>? _operationTail;

  /// Kept for API compatibility; loading is intentionally strict.
  Future<SaveData> load() => loadOrThrow();

  Future<SaveData> loadOrThrow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return SaveData();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Save data root must be an object.');
      }
      return SaveData.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error, stackTrace) {
      debugPrint('Failed to load save data: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw SaveLoadException('データの読み込みに失敗しました。もう一度お試しください。', cause: error);
    }
  }

  Future<void> save(SaveData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final succeeded = await prefs.setString(_key, jsonEncode(data.toJson()));
      if (!succeeded) {
        throw const SaveException('データの保存に失敗しました。もう一度お試しください。');
      }
    } on SaveException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Failed to save data: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw SaveException('データの保存に失敗しました。もう一度お試しください。', cause: error);
    }
  }

  Future<SaveData> update(SaveData Function(SaveData current) updater) {
    return _enqueue<SaveData>(() async {
      final current = await loadOrThrow();
      final updated = updater(current);
      await save(updated);
      return updated;
    });
  }

  Future<void> reset() => _enqueue<void>(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final succeeded = await prefs.remove(_key);
      if (!succeeded && prefs.containsKey(_key)) {
        throw const SaveException('データの初期化に失敗しました。もう一度お試しください。');
      }
    } on SaveException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Failed to reset save data: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw SaveException('データの初期化に失敗しました。もう一度お試しください。', cause: error);
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
    tail.whenComplete(() {
      if (identical(_operationTail, tail)) _operationTail = null;
    });
    return future;
  }
}
