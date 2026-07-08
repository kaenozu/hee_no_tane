import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/audio_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

class HeeNoTaneApp extends StatefulWidget {
  final List<Question> allQuestions;
  final List<HeeCard> allCards;
  final List<Enemy> allEnemies;
  final SaveData saveData;
  final SaveRepository saveRepository;
  final BattleService battleService;
  final RewardService rewardService;

  const HeeNoTaneApp({
    super.key,
    required this.allQuestions,
    required this.allCards,
    required this.allEnemies,
    required this.saveData,
    required this.saveRepository,
    required this.battleService,
    required this.rewardService,
  });

  @override
  State<HeeNoTaneApp> createState() => _HeeNoTaneAppState();
}

class _HeeNoTaneAppState extends State<HeeNoTaneApp> {
  final _userRepo = UserRepository();
  late final GameAudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = GameAudioService(
      enabled: widget.saveData.settings.soundEnabled,
    );
    _loadThemeMode();
    _loadSoundSettingAndStartBgm();
  }

  Future<void> _loadThemeMode() async {
    final mode = await _userRepo.getThemeMode();
    themeModeNotifier.value = mode;
  }

  Future<void> _loadSoundSettingAndStartBgm() async {
    final data = await widget.saveRepository.load();
    await _audioService.setEnabled(data.settings.soundEnabled);
    await _audioService.playBgm();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeModeNotifier,
      builder: (context, _) {
        final mode = themeModeNotifier.value;
        return MaterialApp(
          title: 'へぇダンジョン',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: mode,
          home: HomeScreen(
            allQuestions: widget.allQuestions,
            allCards: widget.allCards,
            allEnemies: widget.allEnemies,
            saveRepository: widget.saveRepository,
            battleService: widget.battleService,
            rewardService: widget.rewardService,
            audioService: _audioService,
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme() =>
      _baseTheme(Brightness.light, const Color(0xFFFBF8F3));
  ThemeData _buildDarkTheme() =>
      _baseTheme(Brightness.dark, const Color(0xFF121212));

  ThemeData _baseTheme(Brightness brightness, Color surface) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: const Color(0xFF1A6B5A),
        onPrimary: Colors.white,
        secondary: const Color(0xFFE8A87C),
        onSecondary: Colors.white,
        tertiary: const Color(0xFF5C6BC0),
        onTertiary: Colors.white,
        surface: surface,
        onSurface: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A2E),
        error: const Color(0xFFBA1A1A),
        onError: Colors.white,
        surfaceContainerHighest: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFEDE7DD),
        outline: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF8C8178),
        outlineVariant: isDark
            ? const Color(0xFF616161)
            : const Color(0xFFD0C5B8),
      ),
      fontFamily: 'NotoSansJP',
      textTheme: _textTheme(isDark),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: isDark ? const Color(0xFF1E1E1E) : null,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : null,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : null,
    );
  }

  TextTheme _textTheme(bool isDark) {
    final c = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A2E);
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: c,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: c,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: c,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: c,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: c,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: c,
      ),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: c),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: c,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: c,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: c,
      ),
    );
  }
}
