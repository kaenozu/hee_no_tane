import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

void main() {
  group('SourceMetadata', () {
    test('approved metadata exposes a safe source URI', () {
      final source = SourceMetadata.fromJson({
        'title': '大気の組成',
        'publisher': '気象庁',
        'url': 'https://www.jma.go.jp/example',
        'verifiedAt': '2026-07-12',
        'verificationLevel': 'primary',
        'reviewStatus': 'approved',
      });

      expect(source.isApproved, isTrue);
      expect(source.sourceUri, Uri.parse('https://www.jma.go.jp/example'));
      expect(source.displayLabel, '気象庁「大気の組成」');
    });

    test('invalid URL and date are rejected', () {
      expect(
        () => SourceMetadata.fromJson({
          'title': '資料',
          'publisher': '発行元',
          'url': 'javascript:alert(1)',
          'verifiedAt': '2026-02-31',
          'verificationLevel': 'primary',
          'reviewStatus': 'approved',
        }),
        throwsFormatException,
      );
    });

    test('legacy question and card remain readable', () {
      final question = Question.fromJson({
        'id': 'q_001',
        'category': 'science',
        'difficulty': 'easy',
        'question': '空気の中で一番多い成分は？',
        'choices': ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
        'answerIndex': 1,
        'explanation': '空気の約78%は窒素です。',
        'relatedCardId': 'card_001',
        'sourceNote': '気象庁',
        'verified': true,
      });
      final card = HeeCard.fromJson({
        'id': 'card_001',
        'title': '大気の成分',
        'category': 'science',
        'shortText': '空気の約78%は窒素。',
        'detailText': '地球の大気は窒素、酸素などで構成されています。',
        'imageAsset': '',
        'rarity': 'normal',
        'sourceNote': '気象庁',
      });

      expect(question.effectiveSource.isLegacy, isTrue);
      expect(card.effectiveSource.isLegacy, isTrue);
      expect(question.effectiveSource.title, '気象庁');
      expect(card.effectiveSource.title, '気象庁');
    });

    test('question and card parse structured source objects', () {
      final source = {
        'title': '大気の組成',
        'publisher': '気象庁',
        'url': 'https://www.jma.go.jp/example',
        'verifiedAt': '2026-07-12',
        'verificationLevel': 'primary',
        'reviewStatus': 'approved',
      };
      final question = Question.fromJson({
        'id': 'q_001',
        'category': 'science',
        'difficulty': 'easy',
        'question': '空気の中で一番多い成分は？',
        'choices': ['酸素', '窒素', '二酸化炭素', 'アルゴン'],
        'answerIndex': 1,
        'explanation': '空気の約78%は窒素です。',
        'relatedCardId': 'card_001',
        'sourceNote': '気象庁',
        'verified': true,
        'source': source,
      });
      final card = HeeCard.fromJson({
        'id': 'card_001',
        'title': '大気の成分',
        'category': 'science',
        'shortText': '空気の約78%は窒素。',
        'detailText': '地球の大気は窒素、酸素などで構成されています。',
        'imageAsset': '',
        'rarity': 'normal',
        'sourceNote': '気象庁',
        'source': source,
      });

      expect(question.effectiveSource.isApproved, isTrue);
      expect(card.effectiveSource.isApproved, isTrue);
    });
  });
}
