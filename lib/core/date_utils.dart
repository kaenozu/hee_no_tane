/// lib/core/date_utils.dart
///
/// 日付フォーマットの共通ユーティリティ。
library;

/// `yyyy-MM-dd` 形式の日付文字列を返す。
String todayDateString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
