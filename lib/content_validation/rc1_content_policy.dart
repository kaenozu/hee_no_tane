import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

/// RC1リリースバンドルの境界を定義する。
///
/// 「承認済み70ペアちょうど」という件数ゲートはtool/validate_rc1_content.dart
/// （ビルド時）で検証する。ランタイムが件数を固定すると、コンテンツ追加の
/// たびにlib/の定数修正とアプリ更新が必要になり、起動不能の原因になるため、
/// ランタイムは空バンドルの出題（何も出題できない状態での正常動作装い）を
/// 拒否するfail-closedのみを行う。
class Rc1ContentPolicy {
  const Rc1ContentPolicy._();

  /// ビルド時にtool/validate_rc1_content.dartが要求する承認済みペア数。
  static const int expectedReleasePairCount = 70;
  static const Set<String> excludedQuestionIds = <String>{};

  static ContentBundle apply(ContentBundle source) {
    if (source.entries.isEmpty) {
      throw const FormatException(
        'RC1 content bundle must contain at least one audited pair.',
      );
    }
    return source;
  }
}
