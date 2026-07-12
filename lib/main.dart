/// lib/main.dart
///
/// アプリのエントリポイント。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}
