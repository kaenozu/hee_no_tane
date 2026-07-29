import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

/// RC1へ渡す承認済みコンテンツの件数をfail-closedで固定する。
///
/// 2026-07-29に一時除外23ペアの直接出典再監査が完了したため、
/// 承認済み70ペアをすべて出題対象とする。
class Rc1ContentPolicy {
  const Rc1ContentPolicy._();

  static const int expectedReleasePairCount = 70;
  static const Set<String> excludedQuestionIds = <String>{};

  static ContentBundle apply(ContentBundle source) {
    if (source.entries.length != expectedReleasePairCount) {
      throw FormatException(
        'RC1 must contain exactly $expectedReleasePairCount audited pairs, got '
        '${source.entries.length}. Review approved content before releasing.',
      );
    }
    return source;
  }
}
