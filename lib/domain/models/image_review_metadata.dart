/// Persisted visual-fit review metadata for bundled card images.
library;

class ImageReviewMetadata {
  static const allowedStatuses = <String>{
    'approved',
    'generic_placeholder',
    'replace_required',
    'unchecked',
  };

  final String status;
  final String reviewedAt;
  final String note;

  const ImageReviewMetadata({
    required this.status,
    required this.reviewedAt,
    required this.note,
  });

  const ImageReviewMetadata.unchecked()
    : status = 'unchecked',
      reviewedAt = '',
      note = '';

  factory ImageReviewMetadata.fromJson(Map<String, dynamic> json) {
    final status = _requiredString(json, 'status');
    final reviewedAtValue = json['reviewedAt'];
    final reviewedAt = reviewedAtValue is String ? reviewedAtValue.trim() : '';
    final note = _optionalString(json, 'note') ?? '';
    if (!allowedStatuses.contains(status)) {
      throw FormatException('Unknown image review status: $status');
    }
    if (status == 'unchecked') {
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
      status == 'approved' || status == 'generic_placeholder';

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
