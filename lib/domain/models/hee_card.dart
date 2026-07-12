import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

class HeeCard {
  final String id;
  final String title;
  final String category;
  final String shortText;
  final String detailText;
  final String imageAsset;
  final String rarity;
  final String sourceNote;
  final SourceMetadata? sourceMetadata;

  const HeeCard({
    required this.id,
    required this.title,
    required this.category,
    required this.shortText,
    required this.detailText,
    required this.imageAsset,
    required this.rarity,
    required this.sourceNote,
    this.sourceMetadata,
  });

  SourceMetadata get effectiveSource {
    return sourceMetadata ?? SourceMetadata.legacy(sourceNote);
  }

  factory HeeCard.fromJson(Map<String, dynamic> json) {
    final sourceJson = json['source'];
    if (sourceJson != null && sourceJson is! Map<String, dynamic>) {
      throw const FormatException('Card source must be an object.');
    }

    return HeeCard(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      shortText: json['shortText'] as String,
      detailText: json['detailText'] as String,
      imageAsset: (json['imageAsset'] as String?) ?? '',
      rarity: json['rarity'] as String,
      sourceNote: json['sourceNote'] as String,
      sourceMetadata: sourceJson == null
          ? null
          : SourceMetadata.fromJson(sourceJson),
    );
  }
}
