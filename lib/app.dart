import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/screens/home_screen.dart';

class HeeNoTaneApp extends StatelessWidget {
  const HeeNoTaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'へぇの種',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF1A6B5A);
    const secondary = Color(0xFFE8A87C);
    const surface = Color(0xFFFBF8F3);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        tertiary: const Color(0xFF5C6BC0),
        onTertiary: Colors.white,
        surface: surface,
        onSurface: const Color(0xFF1A1A2E),
        error: const Color(0xFFBA1A1A),
        onError: Colors.white,
        surfaceContainerHighest: const Color(0xFFEDE7DD),
        outline: const Color(0xFF8C8178),
        outlineVariant: const Color(0xFFD0C5B8),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        elevation: 0,
      ),
    );
  }
}
