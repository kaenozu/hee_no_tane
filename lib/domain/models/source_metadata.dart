/// Structured source and verification metadata for knowledge content.
library;

import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';

class SourceMetadata {
  static const approvedStatus = 'approved';
  static const pendingStatus = 'pending';
  static const correctionRequiredStatus = 'correction_required';
  static const legacyStatus = 'legacy';

  static const allowedVerificationLevels = <String>{
    'primary',
    'secondary',
    'unverified',
  };

  /// Persisted structured review states shared by the CSV workflow and release
  /// blocker tools. Legacy metadata is represented only by [SourceMetadata.legacy].
  static const allowedReviewStatuses = <String>{
    approvedStatus,
    pendingStatus,
    correctionRequiredStatus,
  };

  final String title;
  final String publisher;
  final String? url;
  final String? verifiedAt;
  final String verificationLevel;
  final String reviewStatus;
  final String? reviewNote;
  final String? contentHash;

  const SourceMetadata({
    required this.title,
    required this.publisher,
    required this.url,
    required this.verifiedAt,
    required this.verificationLevel,
    required this.reviewStatus,
    this.reviewNote,
    this.contentHash,
  });

  const SourceMetadata.legacy(String sourceNote)
    : title = sourceNote,
      publisher = '',
      url = null,
      verifiedAt = null,
      verificationLevel = 'unverified',
      reviewStatus = legacyStatus,
      reviewNote = null,
      contentHash = null;

  factory SourceMetadata.fromJson(Map<String, dynamic> json) {
    final title = _requiredString(json, 'title');
    final publisher = _requiredString(json, 'publisher');
    final url = _optionalString(json, 'url');
    final verifiedAt = _optionalString(json, 'verifiedAt');
    final verificationLevel = _requiredString(json, 'verificationLevel');
    final reviewStatus = _requiredString(json, 'reviewStatus');
    final reviewNote = _optionalString(json, 'reviewNote');
    final contentHash = _optionalString(json, 'contentHash');

    if (!allowedVerificationLevels.contains(verificationLevel)) {
      throw FormatException(
        'Unknown source verificationLevel: $verificationLevel',
      );
    }
    if (!allowedReviewStatuses.contains(reviewStatus)) {
      throw FormatException('Unknown source reviewStatus: $reviewStatus');
    }
    if (url != null && tryParseSourceUri(url) == null) {
      throw FormatException('Source URL must use https: $url');
    }
    if (verifiedAt != null && !isIsoDate(verifiedAt)) {
      throw FormatException(
        'Source verifiedAt must use YYYY-MM-DD: $verifiedAt',
      );
    }
    if (contentHash != null && !ContentFingerprint.isSha256(contentHash)) {
      throw FormatException('Source contentHash must be a lowercase SHA-256.');
    }

    return SourceMetadata(
      title: title,
      publisher: publisher,
      url: url,
      verifiedAt: verifiedAt,
      verificationLevel: verificationLevel,
      reviewStatus: reviewStatus,
      reviewNote: reviewNote,
      contentHash: contentHash,
    );
  }

  static SourceMetadata? fromOptionalJson(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Source metadata must be an object.');
    }

    final json = Map<String, dynamic>.from(value);
    if (_isPendingReviewStub(json)) return null;
    return SourceMetadata.fromJson(json);
  }

  static SourceMetadata? tryFromJson(Object? value) {
    if (value is! Map) return null;
    try {
      return SourceMetadata.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  Uri? get sourceUri {
    final value = url;
    return value == null ? null : tryParseSourceUri(value);
  }

  bool get isApproved {
    return reviewStatus == approvedStatus &&
        verificationLevel != 'unverified' &&
        title.isNotEmpty &&
        publisher.isNotEmpty &&
        sourceUri != null &&
        verifiedAt != null &&
        isIsoDate(verifiedAt!);
  }

  bool get isReleaseApproved =>
      isApproved && ContentFingerprint.isSha256(contentHash);

  bool get isLegacy => reviewStatus == legacyStatus;

  String get displayLabel {
    if (publisher.isEmpty || publisher == title) return title;
    return '$publisher「$title」';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'publisher': publisher,
    if (url != null) 'url': url,
    if (verifiedAt != null) 'verifiedAt': verifiedAt,
    'verificationLevel': verificationLevel,
    'reviewStatus': reviewStatus,
    if (reviewNote != null && reviewNote!.isNotEmpty) 'reviewNote': reviewNote,
    if (contentHash != null) 'contentHash': contentHash,
  };

  static Uri? tryParseSourceUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') return null;
    return uri;
  }

  static bool isIsoDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    return parsed.toIso8601String().startsWith(value);
  }

  static bool _isPendingReviewStub(Map<String, dynamic> json) {
    final reviewStatus = json['reviewStatus'];
    if (reviewStatus != pendingStatus &&
        reviewStatus != correctionRequiredStatus) {
      return false;
    }

    return !_hasNonEmptyString(json, 'title') &&
        !_hasNonEmptyString(json, 'publisher') &&
        !_hasNonEmptyString(json, 'verificationLevel');
  }

  static bool _hasNonEmptyString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.trim().isNotEmpty;
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Source $key must be a non-empty string.');
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Source $key must be a string when provided.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
