/// test/helpers/fake_save_repository.dart
///
/// SaveRepositoryのFake実装。Completerで保存Futureを制御する。
library;

///
/// 使用例:
///   final repo = FakeSaveRepository();
///   repo.holdNextSave();
///   // ... trigger save ...
///   expect(repo.saveCallCount, 1);
///   repo.completeSave();  // または repo.failSave()
///
/// 関連:
///   - ../../lib/data/repositories/save_repository.dart

import 'dart:async';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';

class FakeSaveRepository extends SaveRepository {
  int saveCallCount = 0;
  SaveData? lastSavedData;
  final List<SaveData> savedDataHistory = [];
  SaveData? _loadedData;

  Completer<void>? _completer;

  /// SaveDataのload()戻り値を設定する。
  void setLoadedData(SaveData data) {
    _loadedData = data;
  }

  /// 次のsave()をCompleterで保留する。
  void holdNextSave() {
    _completer = Completer<void>();
  }

  /// 保留中のsave()を成功させる。
  void completeSave() {
    assert(_completer != null, 'No pending save to complete');
    _completer!.complete();
    _completer = null;
  }

  /// 保留中のsave()を失敗させる。
  void failSave([Object error = const SaveException('保存に失敗しました')]) {
    assert(_completer != null, 'No pending save to fail');
    _completer!.completeError(error);
    _completer = null;
  }

  @override
  Future<SaveData> load() async {
    return _loadedData ?? await super.load();
  }

  @override
  Future<void> save(SaveData data) async {
    saveCallCount++;
    // 保存呼び出し時点のスナップショットを記録する（後からdataが変更されても影響しない）。
    final snapshot = SaveData.fromJson(data.toJson());
    lastSavedData = snapshot;
    savedDataHistory.add(snapshot);
    if (_completer != null) {
      await _completer!.future;
    }
  }
}
