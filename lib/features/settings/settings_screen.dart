/// lib/features/settings/settings_screen.dart
///
/// 設定画面。データリセット、プライバシー、サポート、ライセンスを表示する。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/settings/legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final VoidCallback onDataReset;

  const SettingsScreen({
    super.key,
    required this.saveRepository,
    required this.rewardService,
    required this.onDataReset,
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
        content: const Text('獲得カード、連続日数、閲覧数、設定を削除します。この操作は取り消せません。'),
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
      if (!mounted) return;
      widget.onDataReset();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on SaveException catch (error) {
      if (!mounted) return;
      setState(() => _resetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to reset settings data: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _resetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データの初期化に失敗しました。もう一度お試しください。')),
      );
    }
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'へぇのタネ',
      applicationVersion: '1.0.0 (1)',
      applicationIcon: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.auto_stories_rounded, size: 48),
      ),
    );
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
            subtitle: const Text('端末内の進行状況と設定を初期状態に戻す'),
            trailing: _resetting
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : null,
            enabled: !_resetting,
            onTap: _confirmReset,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.support_agent_outlined, color: cs.primary),
            title: const Text('サポート'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: cs.primary),
            title: const Text('オープンソースライセンス'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLicenses,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: cs.primary),
            title: const Text('アプリ情報'),
            subtitle: const Text('へぇのタネ v1.0.0 (1)'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '問題とカードはアプリに同梱され、利用状況を外部へ自動送信しません。',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
