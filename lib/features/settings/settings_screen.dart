/// lib/features/settings/settings_screen.dart
///
/// 設定画面。価格比較・データリセット・アプリ情報を表示。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/core/app_version_info.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/comparison/price_comparison_screen.dart';
import 'package:hee_no_tane_app/features/settings/legal_information_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SaveRepository saveRepository;
  final Future<void> Function() onDataReset;
  final AppVersionInfoLoader versionInfoLoader;

  const SettingsScreen({
    super.key,
    required this.saveRepository,
    required this.onDataReset,
    this.versionInfoLoader = loadAppVersionInfoSafely,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _resetting = false;
  late final Future<AppVersionInfo> _versionInfoFuture;

  @override
  void initState() {
    super.initState();
    _versionInfoFuture = widget.versionInfoLoader();
  }

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
    try {
      await widget.onDataReset();
    } catch (_) {
      if (!mounted) return;
      setState(() => _resetting = false);
      _showError('データは削除されましたが、画面の更新に失敗しました。設定画面を閉じて再度お試しください。');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openVersionInformation() async {
    final versionInfo = await _versionInfoFuture;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LegalInformationScreen(
          initialSection: LegalInformationSection.version,
          versionInfo: versionInfo,
        ),
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
            key: const ValueKey('settings-price-comparison'),
            leading: Icon(Icons.compare_arrows, color: cs.primary),
            title: const Text('価格比較'),
            subtitle: const Text('容量・割引・ポイント・送料を含めて比較'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const PriceComparisonScreen()),
              );
            },
          ),
          const Divider(),
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
            subtitle: Text(_resetting ? '削除しています…' : 'すべてのデータを初期状態に戻す'),
            enabled: !_resetting,
            onTap: _confirmReset,
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('settings-privacy-policy'),
            leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
            title: const Text('プライバシーポリシー'),
            subtitle: const Text('データの取り扱いについて'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const LegalInformationScreen(
                    initialSection: LegalInformationSection.privacyPolicy,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('settings-support'),
            leading: Icon(Icons.support_agent, color: cs.primary),
            title: const Text('サポート'),
            subtitle: const Text('不具合報告・お問い合わせ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const LegalInformationScreen(
                    initialSection: LegalInformationSection.support,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('settings-version'),
            leading: Icon(Icons.info_outline, color: cs.primary),
            title: const Text('バージョン情報'),
            subtitle: FutureBuilder<AppVersionInfo>(
              future: _versionInfoFuture,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Text(info?.settingsSubtitle ?? 'へぇのタネ');
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openVersionInformation,
          ),
        ],
      ),
    );
  }
}
