import 'package:flutter/foundation.dart' as foundation;

/// Debug-only logging facade. Release builds do not emit exception details or
/// stack traces through these helpers.
void debugPrint(String? message, {int? wrapWidth}) {
  if (!foundation.kDebugMode) return;
  foundation.debugPrint(message, wrapWidth: wrapWidth);
}

void debugPrintStack({
  StackTrace? stackTrace,
  String? label,
  int? maxFrames,
}) {
  if (!foundation.kDebugMode) return;
  foundation.debugPrintStack(
    stackTrace: stackTrace,
    label: label,
    maxFrames: maxFrames,
  );
}
