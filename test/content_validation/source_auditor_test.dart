import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/source_auditor.dart';

void main() {
  const auditor = ContentSourceAuditor();

  test('legacy source notes are reported as pending, not malformed', () {
    final result = auditor.auditJsonStrings(
      questionsJson: jsonEncode([_question()]),
      cardsJson: jsonEncode([_card()]),
    );

    expect(result.totalCount, 2);
    expect(result.approvedCount, 0);
    expect(result.pendingCount, 2);
    expect(result.invalidCount, 0);
    expect(result.allApproved, isFalse);
    expect(result.toMarkdown(), contains('構造化されたsourceが未設定'));
  });

  test('complete approved sources pass the strict audit state', () {
    final source = _source(url: 'https://www.jma.go.jp/example');
    final result = auditor.auditJsonStrings(
      questionsJson: jsonEncode([_question(source: source)]),
      cardsJson: jsonEncode([_card(source: source)]),
    );

    expect(result.approvedCount, 2);
    expect(result.pendingCount, 0);
    expect(result.invalidCount, 0);
    expect(result.allApproved, isTrue);
  });

  test('approved metadata with missing requirements is invalid', () {
    final result = auditor.auditJsonStrings(
      questionsJson: jsonEncode([
        _question(
          source: {
            'title': '大気の組成',
            'publisher': '気象庁',
            'verificationLevel': 'primary',
            'reviewStatus': 'approved',
          },
        ),
      ]),
      cardsJson: jsonEncode([_card()]),
    );

    expect(result.hasInvalidMetadata, isTrue);
    expect(result.invalidCount, 1);
    expect(result.entries.first.findings, contains('approvedですが必須情報が不足しています'));
  });

  test('different approved question and card URLs are rejected', () {
    final result = auditor.auditJsonStrings(
      questionsJson: jsonEncode([
        _question(source: _source(url: 'https://example.com/question')),
      ]),
      cardsJson: jsonEncode([
        _card(source: _source(url: 'https://example.com/card')),
      ]),
    );

    expect(result.hasInvalidMetadata, isTrue);
    expect(result.globalIssues, hasLength(1));
    expect(
      result.globalIssues.single,
      contains('different approved source URLs'),
    );
  });
}

Map<String, dynamic> _source({required String url}) {
  return {
    'title': '大気の組成',
    'publisher': '気象庁',
    'url': url,
    'verifiedAt': '2026-07-12',
    'verificationLevel': 'primary',
    'reviewStatus': 'approved',
  };
}

Map<String, dynamic> _question({Map<String, dynamic>? source}) {
  return {
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
    ...(source == null
        ? const <String, dynamic>{}
        : <String, dynamic>{'source': source}),
  };
}

Map<String, dynamic> _card({Map<String, dynamic>? source}) {
  return {
    'id': 'card_001',
    'title': '大気の成分',
    'category': 'science',
    'shortText': '空気の約78%は窒素。',
    'detailText': '地球の大気は窒素、酸素などで構成されています。',
    'imageAsset': '',
    'rarity': 'normal',
    'sourceNote': '気象庁',
    ...(source == null
        ? const <String, dynamic>{}
        : <String, dynamic>{'source': source}),
  };
}
