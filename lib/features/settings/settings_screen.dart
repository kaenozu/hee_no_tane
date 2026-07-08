import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

class SettingsScreen extends StatefulWidget {
  final SaveRepository saveRepository;
  final RewardService rewardService;
  final GameAudioService audioService;
  final VoidCallback onDataReset;

  const SettingsScreen({
    super.key,
    required this.saveRepository,
    required this.rewardService,
    required this.audioService,
    required this.onDataReset,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await widget.saveRepository.load();
    setState(() => _soundEnabled = data.settings.soundEnabled);
  }

  Future<void> _toggleSound(bool value) async {
    final data = await widget.saveRepository.load();
    data.settings.soundEnabled = value;
    await widget.saveRepository.save(data);
    await widget.audioService.setEnabled(value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _confirmReset() async {
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
    if (confirmed == true) {
      await widget.saveRepository.reset();
      widget.onDataReset();
      if (mounted) Navigator.pop(context);
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
          SwitchListTile(
            secondary: Icon(Icons.volume_up_outlined, color: cs.primary),
            title: const Text('サウンド'),
            subtitle: const Text('BGMと効果音のON/OFF'),
            value: _soundEnabled,
            onChanged: _toggleSound,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[300]),
            title: const Text('データリセット'),
            subtitle: const Text('すべてのデータを初期状態に戻す'),
            onTap: _confirmReset,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: cs.primary),
            title: const Text('アプリ情報'),
            subtitle: const Text('へぇダンジョン v1.0.0'),
          ),
        ],
      ),
    );
  }
}
