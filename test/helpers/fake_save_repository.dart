/// test/helpers/fake_save_repository.dart
///
/// SaveRepositoryのFake実装。Completerで保存Futureを制御する。
/// Issue #7とIssue #9の非同期保存・最新読込テストで使用する。
library;

import 'dart:async';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

class InMemoryPreferenceStore implements PreferenceStore {
  final Map<String, String> _values;

  InMemoryPreferenceStore({Map<String, String>? initialValues})
    : _values = Map<String, String>.from(
        initialValues ?? const <String, String>{},
      );

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

class FakeSaveRepository extends SaveRepository {
  int loadCallCount = 0;
  int saveCallCount = 0;
  SaveData? lastSavedData;
  final List<SaveData> savedDataHistory = [];
  SaveData? _loadedData;
  Object? _loadError;
  Completer<void>? _completer;

  FakeSaveRepository() : super(store: InMemoryPreferenceStore());

  void setLoadedData(SaveData data) {
    _loadedData = SaveData.fromJson(data.toJson());
  }

  void failLoads([Object error = const SaveLoadException('読み込みに失敗しました')]) {
    _loadError = error;
  }

  void clearLoadFailure() {
    _loadError = null;
  }

  void holdNextSave() {
    _completer = Completer<void>();
  }

  void completeSave() {
    assert(_completer != null, 'No pending save to complete');
    _completer!.complete();
    _completer = null;
  }

  void failSave([Object error = const SaveException('保存に失敗しました')]) {
    assert(_completer != null, 'No pending save to fail');
    _completer!.completeError(error);
    _completer = null;
  }

  @override
  Future<SaveData> loadOrThrow() async {
    loadCallCount++;
    final error = _loadError;
    if (error != null) {
      if (error is SaveLoadException) throw error;
      throw SaveLoadException('読み込みに失敗しました', cause: error);
    }
    if (_loadedData != null) {
      return SaveData.fromJson(_loadedData!.toJson());
    }
    return super.loadOrThrow();
  }

  @override
  Future<SaveData> load() async {
    try {
      return await loadOrThrow();
    } on SaveLoadException {
      return SaveData();
    }
  }

  @override
  Future<void> save(SaveData data) async {
    saveCallCount++;
    final snapshot = SaveData.fromJson(data.toJson());
    lastSavedData = snapshot;
    savedDataHistory.add(snapshot);

    final pendingCompleter = _completer;
    if (pendingCompleter != null) {
      await pendingCompleter.future;
    }
    _loadedData = snapshot;
  }
}
