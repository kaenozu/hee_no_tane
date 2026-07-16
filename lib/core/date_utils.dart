/// lib/core/date_utils.dart
///
/// 日付フォーマットの共通ユーティリティ。
library;

/// [dateTime]のローカル暦日を`yyyy-MM-dd`形式で返す。
String calendarDateString(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

/// 現在のローカル暦日を`yyyy-MM-dd`形式で返す。
String todayDateString() => calendarDateString(DateTime.now());
