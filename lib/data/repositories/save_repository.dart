/// SharedPreferencesAsync-backed persistent state.
library;

import 'dart:convert';

import 'package:hee_no_tane_app/core/app_log.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

/// Key-value storage abstraction used by [SaveRepository].
///
/// Production code uses [SharedPreferencesAsyncStore]. Tests can inject an
/// in-memory implementation without replacing [SaveRepository] itself.
abstract interface class PreferenceStore {
  Future<String?> getString(String key);

  Future<bool> containsKey(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

/// [PreferenceStore] implementation backed by [SharedPreferencesAsync].
final class SharedPreferencesAsyncStore implements PreferenceStore {
  final SharedPreferencesAsync _preferences;

  SharedPreferencesAsyncStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<bool> containsKey(String key) => _preferences.containsKey(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

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
  static const String _key = 'hee_no_tane_save_data';

  /// Marker written to SharedPreferencesAsync after legacy migration succeeds.
  ///
  /// Do not rename or delete this key after releasing the migration. Doing so
  /// would allow the legacy migration to run again.
  static const String migrationCompletedKey =
      'hee_no_tane_shared_preferences_async_migration_completed';

  final PreferenceStore _store;

  Future<void>? _operationTail;

  SaveRepository({PreferenceStore? store})
    : _store = store ?? SharedPreferencesAsyncStore();

  /// Migrates values from the legacy [SharedPreferences] API to
  /// [SharedPreferencesAsync].
  ///
  /// This method is safe to invoke at every application startup because the
  /// migration utility checks [migrationCompletedKey] before copying data.
  static Future<void> migrateLegacyStorage({
    SharedPreferences? legacyPreferences,
    SharedPreferencesOptions asyncOptions = const SharedPreferencesOptions(),
  }) async {
    try {
      final preferences =
          legacyPreferences ?? await SharedPreferences.getInstance();

      await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
        legacySharedPreferencesInstance: preferences,
        sharedPreferencesAsyncOptions: asyncOptions,
        migrationCompletedKey: migrationCompletedKey,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to migrate legacy save data: $error');
      debugPrintStack(stackTrace: stackTrace);

      throw SaveException('保存データの移行に失敗しました。もう一度お試しください。', cause: error);
    }
  }

  /// Kept for API compatibility; loading is intentionally strict.
  Future<SaveData> load() => loadOrThrow();

  Future<SaveData> loadOrThrow() async {
    try {
      final raw = await _store.getString(_key);

      if (raw == null || raw.isEmpty) {
        return SaveData();
      }

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
      final encoded = jsonEncode(data.toJson());
      await _store.setString(_key, encoded);
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

  Future<void> reset() {
    return _enqueue<void>(() async {
      try {
        await _store.remove(_key);

        final stillExists = await _store.containsKey(_key);
        if (stillExists) {
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
  }

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
      if (identical(_operationTail, tail)) {
        _operationTail = null;
      }
    });

    return future;
  }
}
