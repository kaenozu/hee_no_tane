import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingAudioService extends GameAudioService {
  bool? lastEnabledValue;

  RecordingAudioService() : super(enabled: false);

  @override
  Future<void> setEnabled(bool value) async {
    lastEnabledValue = value;
    await super.setEnabled(value);
  }
}

void main() {
  testWidgets('reset data also restores runtime audio to enabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = SaveRepository();
    final data = SaveData();
    data.settings.soundEnabled = false;
    await repository.save(data);
    final audioService = RecordingAudioService();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          saveRepository: repository,
          rewardService: RewardService(),
          audioService: audioService,
          onDataReset: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('データリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リセット'));
    await tester.pumpAndSettle();

    expect(audioService.lastEnabledValue, true);
    expect((await repository.load()).settings.soundEnabled, true);
  });
}
