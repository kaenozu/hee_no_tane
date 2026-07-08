import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/screens/home_screen.dart';

class HeeNoTaneApp extends StatelessWidget {
  const HeeNoTaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'へぇの種',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E23)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
