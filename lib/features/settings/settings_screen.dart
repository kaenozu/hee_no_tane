/// lib/features/settings/settings_screen.dart
///
/// 設定画面。データリセット・アプリ情報を表示。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/settings/legal_information_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SaveRepository saveRepository;
  final RewardService rewardService;

  const SettingsScreen({
    super.key,
    required this.saveRepository,
    required this.rewardService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _resetting = false;

  Future<void> _confirmReset() async {
    if (_resetting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('データリセット'),
        content: const Text('すべてのデータを削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _resetting = true);
    try {
      await widget.saveRepository.reset();
    } on SaveException catch (error) {
      if (!mounted) return;
      setState(() => _resetting = false);
      _showError(error.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _resetting = false);
      _showError('データの削除に失敗しました。もう一度お試しください。');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            key: const ValueKey('settings-reset-data'),
            leading: _resetting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(Icons.delete_outline, color: Colors.red[300]),
            title: const Text('データリセット'),
            subtitle: Text(
              _resetting ? '削除しています…' : 'すべてのデータを初期状態に戻す',
            ),
            enabled: !_resetting,
            onTap: _confirmReset,
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('settings-legal-information'),
            leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
            title: const Text('プライバシーとサポート'),
            subtitle: const Text('データの取り扱い・免責事項・問い合わせ方法'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const LegalInformationScreen(),
                ),
              );
            },
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
