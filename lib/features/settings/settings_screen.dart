/// lib/features/settings/settings_screen.dart
///
/// 設定画面。データリセット・アプリ情報を表示。
library;
///
/// 関連:
///   - ../../data/repositories/save_repository.dart
///   - ../../domain/services/reward_service.dart

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

class SettingsScreen extends StatelessWidget {
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final VoidCallback onDataReset;

  const SettingsScreen({
    super.key,
    required this.saveRepository,
    required this.rewardService,
    required this.onDataReset,
  });

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('データリセット'),
        content: const Text('すべてのデータを削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await saveRepository.reset();
      onDataReset();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[300]),
            title: const Text('データリセット'),
            subtitle: const Text('すべてのデータを初期状態に戻す'),
            onTap: () => _confirmReset(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: cs.primary),
            title: const Text('アプリ情報'),
            subtitle: const Text('へぇのタネ v1.0.0'),
          ),
        ],
      ),
    );
  }
}
