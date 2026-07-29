import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

/// RC1では直接根拠の再監査が完了していない23ペアを出題対象から除外する。
///
/// 編集元と承認台帳は保持し、v1.1で直接記事URLを確認してから再追加する。
class Rc1ContentPolicy {
  const Rc1ContentPolicy._();

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
    final availableQuestionIds = <String>{
      for (final entry in source.entries) entry.question.id,
    };
    final missingExclusions = excludedQuestionIds.difference(
      availableQuestionIds,
    );
    if (missingExclusions.isNotEmpty) {
      final sorted = missingExclusions.toList()..sort();
      throw FormatException(
        'RC1 exclusion list contains missing question ids: '
        '${sorted.join(', ')}.',
      );
    }

    final releaseEntries = <ContentBundleEntry>[
      for (final entry in source.entries)
        if (!excludedQuestionIds.contains(entry.question.id)) entry,
    ];
    if (releaseEntries.length != expectedReleasePairCount) {
      throw FormatException(
        'RC1 must contain exactly $expectedReleasePairCount pairs, got '
        '${releaseEntries.length}. Review approved content and the exclusion '
        'list before releasing.',
      );
    }

    return ContentBundle.create(
      contentVersion: source.contentVersion,
      entries: releaseEntries,
    );
  }
}
