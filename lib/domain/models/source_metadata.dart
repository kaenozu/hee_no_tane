/// Structured source and verification metadata for knowledge content.
library;

class SourceMetadata {
  static const allowedVerificationLevels = <String>{
    'primary',
    'secondary',
    'unverified',
  };

  static const allowedReviewStatuses = <String>{
    'approved',
    'pending',
    'rejected',
    'legacy',
  };

  final String title;
  final String publisher;
  final String? url;
  final String? verifiedAt;
  final String verificationLevel;
  final String reviewStatus;

  const SourceMetadata({
    required this.title,
    required this.publisher,
    required this.url,
    required this.verifiedAt,
    required this.verificationLevel,
    required this.reviewStatus,
  });

  const SourceMetadata.legacy(String sourceNote)
    : title = sourceNote,
      publisher = '',
      url = null,
      verifiedAt = null,
      verificationLevel = 'unverified',
      reviewStatus = 'legacy';

  factory SourceMetadata.fromJson(Map<String, dynamic> json) {
    final title = _requiredString(json, 'title');
    final publisher = _requiredString(json, 'publisher');
    final url = _optionalString(json, 'url');
    final verifiedAt = _optionalString(json, 'verifiedAt');
    final verificationLevel = _requiredString(json, 'verificationLevel');
    final reviewStatus = _requiredString(json, 'reviewStatus');

    if (!allowedVerificationLevels.contains(verificationLevel)) {
      throw FormatException(
        'Unknown source verificationLevel: $verificationLevel',
      );
    }
    if (!allowedReviewStatuses.contains(reviewStatus)) {
      throw FormatException('Unknown source reviewStatus: $reviewStatus');
    }
    if (url != null && tryParseSourceUri(url) == null) {
      throw FormatException('Source URL must use http or https: $url');
    }
    if (verifiedAt != null && !isIsoDate(verifiedAt)) {
      throw FormatException('Source verifiedAt must use YYYY-MM-DD: $verifiedAt');
    }

    return SourceMetadata(
      title: title,
      publisher: publisher,
      url: url,
      verifiedAt: verifiedAt,
      verificationLevel: verificationLevel,
      reviewStatus: reviewStatus,
    );
  }

  /// Parses optional runtime content without allowing one malformed source
  /// object to prevent the rest of the bundled content from loading.
  ///
  /// Release tooling must continue to use [fromJson] so invalid metadata is
  /// rejected by CI instead of being silently accepted for publication.
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
    return reviewStatus == 'approved' &&
        verificationLevel != 'unverified' &&
        title.isNotEmpty &&
        publisher.isNotEmpty &&
        sourceUri != null &&
        verifiedAt != null &&
        isIsoDate(verifiedAt!);
  }

  bool get isLegacy => reviewStatus == 'legacy';

  String get displayLabel {
    if (publisher.isEmpty || publisher == title) return title;
    return '$publisher「$title」';
  }

  static Uri? tryParseSourceUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }

  static bool isIsoDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    return parsed.toIso8601String().startsWith(value);
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
