/// Persisted visual-fit review metadata for bundled card images.
library;

class ImageReviewMetadata {
  static const approvedStatus = 'approved';
  static const pendingStatus = 'pending';
  static const genericPlaceholderStatus = 'generic_placeholder';
  static const replaceRequiredStatus = 'replace_required';
  static const uncheckedStatus = 'unchecked';

  /// `fit` was used by an earlier review CSV. It remains accepted as an input
  /// alias, but is always persisted as [approvedStatus].
  static const fitAlias = 'fit';

  static const allowedStatuses = <String>{
    approvedStatus,
    pendingStatus,
    genericPlaceholderStatus,
    replaceRequiredStatus,
    uncheckedStatus,
  };

  static const acceptedInputStatuses = <String>{...allowedStatuses, fitAlias};

  final String status;
  final String reviewedAt;
  final String note;

  const ImageReviewMetadata({
    required this.status,
    required this.reviewedAt,
    required this.note,
  });

  const ImageReviewMetadata.unchecked()
    : status = uncheckedStatus,
      reviewedAt = '',
      note = '';

  factory ImageReviewMetadata.fromJson(Map<String, dynamic> json) {
    final rawStatus = _requiredString(json, 'status');
    if (!acceptedInputStatuses.contains(rawStatus)) {
      throw FormatException('Unknown image review status: $rawStatus');
    }
    final status = rawStatus == fitAlias ? approvedStatus : rawStatus;
    final reviewedAtValue = json['reviewedAt'];
    final reviewedAt = reviewedAtValue is String ? reviewedAtValue.trim() : '';
    final note = _optionalString(json, 'note') ?? '';
    if (status == uncheckedStatus) {
      if (reviewedAt.isNotEmpty) {
        _validateDate(reviewedAt);
      }
    } else {
      if (reviewedAt.isEmpty) {
        throw const FormatException(
          'Image review reviewedAt is required after review.',
        );
      }
      _validateDate(reviewedAt);
    }
    return ImageReviewMetadata(
      status: status,
      reviewedAt: reviewedAt,
      note: note,
    );
  }

  bool get isReleaseReady =>
      status == approvedStatus || status == genericPlaceholderStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status,
    'reviewedAt': reviewedAt,
    if (note.isNotEmpty) 'note': note,
  };

  static void _validateDate(String value) {
    final parsedDate = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        parsedDate == null ||
        !parsedDate.toIso8601String().startsWith(value)) {
      throw FormatException(
        'Image review reviewedAt must use YYYY-MM-DD: $value',
      );
    }
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Image review $key must be a non-empty string.');
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Image review $key must be a string.');
    }
    return value.trim();
  }
}
