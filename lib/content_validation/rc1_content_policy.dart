import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

/// Android v1.0 RC1へ渡す監査済みコンテンツ境界をfail-closedで固定する。
///
/// 編集元bundleは70ペアを保持するが、Issue #75でv1.1向け再監査中の23ペアは
/// v1.0 runtimeへ戻さない。再監査完了後の再追加はv1.1以降で別途判断する。
class Rc1ContentPolicy {
  const Rc1ContentPolicy._();

  static const int expectedSourcePairCount = 70;
  static const int expectedReleasePairCount = 47;

  static const Set<String> excludedQuestionIds = <String>{
    'q_daily_life_010',
    'q_food_005',
    'q_food_006',
    'q_food_009',
    'q_history_007',
    'q_language_002',
    'q_language_005',
    'q_language_009',
    'q_language_010',
    'q_living_things_008',
    'q_living_things_009',
    'q_living_things_012',
    'q_living_things_013',
    'q_living_things_015',
    'q_living_things_016',
    'q_nature_geography_009',
    'q_sci_001',
    'q_sci_002',
    'q_sci_004',
    'q_science_001',
    'q_science_002',
    'q_science_009',
    'q_science_010',
  };

  static ContentBundle apply(ContentBundle source) {
    if (source.entries.length != expectedSourcePairCount) {
      throw FormatException(
        'RC1 source must contain exactly $expectedSourcePairCount editorial pairs, '
        'got ${source.entries.length}. Review generated content before releasing.',
      );
    }

    final sourceIds = source.entries.map((entry) => entry.question.id).toSet();
    final missingExclusions = excludedQuestionIds.difference(sourceIds);
    if (missingExclusions.isNotEmpty) {
      throw FormatException(
        'RC1 exclusion contract references missing question IDs: '
        '${missingExclusions.toList()..sort()}',
      );
    }

    final releaseEntries = source.entries
        .where((entry) => !excludedQuestionIds.contains(entry.question.id))
        .toList(growable: false);
    if (releaseEntries.length != expectedReleasePairCount) {
      throw FormatException(
        'RC1 must expose exactly $expectedReleasePairCount audited runtime pairs, '
        'got ${releaseEntries.length}.',
      );
    }

    return ContentBundle.create(
      contentVersion: source.contentVersion,
      entries: releaseEntries,
    );
  }
}
