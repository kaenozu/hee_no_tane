/// Startup fallback shown when required bundled data cannot be loaded.
library;

import 'package:flutter/material.dart';

class StartupErrorApp extends StatelessWidget {
  final String message;

  const StartupErrorApp({
    super.key,
    this.message = 'アプリの起動に必要なデータを読み込めませんでした。',
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'へぇのタネ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 72),
                    const SizedBox(height: 24),
                    Text(
                      '起動できませんでした',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'アプリを終了して再度起動してください。解決しない場合は、最新版へ更新するか再インストールしてください。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
