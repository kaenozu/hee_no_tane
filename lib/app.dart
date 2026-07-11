/// lib/app.dart
///
/// アプリのルートウィジェット。
library;

/// Material 3 テーマ定義（暖色系・紙/木/植物モチーフ）、画面遷移の起点。
///
/// 関連:
///   - main.dart
///   - features/home/home_screen.dart
///   - domain/models/save_data.dart

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

class HeeNoTaneApp extends StatefulWidget {
  final List<Question> allQuestions;
  final List<HeeCard> allCards;
  final SaveData saveData;
  final SaveRepository saveRepository;
  final RewardService rewardService;

  const HeeNoTaneApp({
    super.key,
    required this.allQuestions,
    required this.allCards,
    required this.saveData,
    required this.saveRepository,
    required this.rewardService,
  });

  @override
  State<HeeNoTaneApp> createState() => _HeeNoTaneAppState();
}

class _HeeNoTaneAppState extends State<HeeNoTaneApp> {
  @override
  void initState() {
    super.initState();
    themeModeNotifier.value = widget.saveData.settings.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeModeNotifier,
      builder: (context, _) {
        final mode = themeModeNotifier.value;
        return MaterialApp(
          title: 'へぇのタネ',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: mode,
          home: HomeScreen(
            allQuestions: widget.allQuestions,
            allCards: widget.allCards,
            saveRepository: widget.saveRepository,
            rewardService: widget.rewardService,
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme() =>
      _baseTheme(Brightness.light, const Color(0xFFFBF6ED));
  ThemeData _buildDarkTheme() =>
      _baseTheme(Brightness.dark, const Color(0xFF1A1A1A));

  ThemeData _baseTheme(Brightness brightness, Color surface) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: const Color(0xFF5B8A5B),
        onPrimary: Colors.white,
        secondary: const Color(0xFFD4A373),
        onSecondary: Colors.white,
        tertiary: const Color(0xFF8B7E74),
        onTertiary: Colors.white,
        surface: surface,
        onSurface: isDark ? const Color(0xFFE8E0D8) : const Color(0xFF2C2416),
        error: const Color(0xFFBA1A1A),
        onError: Colors.white,
        surfaceContainerHighest: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFE8E0D5),
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
        color: isDark ? const Color(0xFF2C2416) : const Color(0xFFFFF8F0),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isDark
            ? const Color(0xFF2C2416)
            : const Color(0xFFFBF6ED).withValues(alpha: 0.9),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF1A1A1A) : null,
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF3D3A36) : const Color(0xFFDCD4C8),
      ),
    );
  }

  TextTheme _textTheme(bool isDark) {
    final c = isDark ? const Color(0xFFE8E0D8) : const Color(0xFF2C2416);
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
        height: 1.7,
        color: c,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
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
