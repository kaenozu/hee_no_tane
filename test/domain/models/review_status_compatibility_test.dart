import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/image_review_metadata.dart';
import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

void main() {
  test('correction_required is a valid non-approved source status', () {
    final metadata = SourceMetadata.fromJson(const <String, dynamic>{
      'title': '確認中の資料',
      'publisher': '確認中',
      'url': 'https://example.com/source',
      'verifiedAt': '2026-07-16',
      'verificationLevel': 'secondary',
      'reviewStatus': 'correction_required',
    });

    expect(metadata.reviewStatus, SourceMetadata.correctionRequiredStatus);
    expect(metadata.isApproved, isFalse);
    expect(metadata.isReleaseApproved, isFalse);
  });

  test('legacy CSV image status fit is normalized to approved', () {
    final metadata = ImageReviewMetadata.fromJson(const <String, dynamic>{
      'status': 'fit',
      'reviewedAt': '2026-07-16',
      'note': '旧CSVから移行',
    });

    expect(metadata.status, ImageReviewMetadata.approvedStatus);
    expect(metadata.isReleaseReady, isTrue);
    expect(metadata.toJson()['status'], ImageReviewMetadata.approvedStatus);
  });

  test('pending image review round-trips and remains release blocked', () {
    final metadata = ImageReviewMetadata.fromJson(const <String, dynamic>{
      'status': 'pending',
      'reviewedAt': '2026-08-10',
      'note': '生成画像の目視確認待ち',
    });

    expect(metadata.status, ImageReviewMetadata.pendingStatus);
    expect(metadata.isReleaseReady, isFalse);
    expect(metadata.toJson(), <String, dynamic>{
      'status': 'pending',
      'reviewedAt': '2026-08-10',
      'note': '生成画像の目視確認待ち',
    });
  });
}
