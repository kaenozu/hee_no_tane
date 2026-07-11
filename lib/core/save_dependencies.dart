/// lib/core/save_dependencies.dart
///
/// 画面ツリーへセーブ関連の依存関係を注入する。
library;

import 'package:flutter/widgets.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

class SaveDependencies extends InheritedWidget {
  final SaveRepository saveRepository;
  final RewardService rewardService;

  const SaveDependencies({
    super.key,
    required this.saveRepository,
    required this.rewardService,
    required super.child,
  });

  static SaveDependencies? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SaveDependencies>();
  }

  static SaveDependencies of(BuildContext context) {
    final dependencies = maybeOf(context);
    if (dependencies == null) {
      throw FlutterError(
        'SaveDependencies was not found in the widget tree. '
        'Pass SaveRepository and RewardService explicitly or wrap the app '
        'with SaveDependencies.',
      );
    }
    return dependencies;
  }

  @override
  bool updateShouldNotify(SaveDependencies oldWidget) {
    return saveRepository != oldWidget.saveRepository ||
        rewardService != oldWidget.rewardService;
  }
}
