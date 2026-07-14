import 'package:hee_no_tane_app/domain/models/image_review_metadata.dart';
import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

class HeeCard {
  final String id;
  final String title;
  final String category;
  final String shortText;
  final String detailText;
  final String imageAsset;
  final String rarity;
  final String legacySourceNote;
  final SourceMetadata? sourceMetadata;
  final ImageReviewMetadata imageReview;

  const HeeCard({
    required this.id,
    required this.title,
    required this.category,
    required this.shortText,
    required this.detailText,
    required this.imageAsset,
    required this.rarity,
    required String sourceNote,
    this.sourceMetadata,
    this.imageReview = const ImageReviewMetadata.unchecked(),
  }) : legacySourceNote = sourceNote;

  SourceMetadata get effectiveSource =>
      sourceMetadata ?? SourceMetadata.legacy(legacySourceNote);

  bool get isSourceReleaseApproved =>
      sourceMetadata?.isReleaseApproved == true && imageReview.isReleaseReady;

  String get sourceNote {
    final source = sourceMetadata;
    if (source == null) return legacySourceNote;
    final verifiedAt = source.verifiedAt;
    if (verifiedAt == null) return source.displayLabel;
    return '${source.displayLabel}（確認日: $verifiedAt）';
  }

  factory HeeCard.fromJson(Map<String, dynamic> json) {
    final sourceValue = json['source'];
    final imageReviewValue = json['imageReview'];
    return HeeCard(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      category: _requiredString(json, 'category'),
      shortText: _requiredString(json, 'shortText'),
      detailText: _requiredString(json, 'detailText'),
      imageAsset: (json['imageAsset'] as String?)?.trim() ?? '',
      rarity: _requiredString(json, 'rarity'),
      sourceNote: _requiredString(json, 'sourceNote'),
      sourceMetadata: sourceValue == null
          ? null
          : SourceMetadata.fromJson(
              Map<String, dynamic>.from(sourceValue as Map),
            ),
      imageReview: imageReviewValue == null
          ? const ImageReviewMetadata.unchecked()
          : ImageReviewMetadata.fromJson(
              Map<String, dynamic>.from(imageReviewValue as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'category': category,
    'shortText': shortText,
    'detailText': detailText,
    'imageAsset': imageAsset,
    'rarity': rarity,
    'sourceNote': legacySourceNote,
    if (sourceMetadata != null) 'source': sourceMetadata!.toJson(),
    'imageReview': imageReview.toJson(),
  };

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Card $key must be a non-empty string.');
    }
    return value.trim();
  }
}
