/// Stable SHA-256 fingerprints for reviewed question/card pairs.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

class ContentFingerprint {
  const ContentFingerprint._();

  static String forPair({
    required Map<String, dynamic> question,
    required Map<String, dynamic> card,
  }) {
    final canonical = <String, dynamic>{
      'question': <String, dynamic>{
        'id': question['id'],
        'category': question['category'],
        'difficulty': question['difficulty'],
        'question': question['question'],
        'choices': question['choices'],
        'answerIndex': question['answerIndex'],
        'explanation': question['explanation'],
        'relatedCardId': question['relatedCardId'],
      },
      'card': <String, dynamic>{
        'id': card['id'],
        'title': card['title'],
        'category': card['category'],
        'shortText': card['shortText'],
        'detailText': card['detailText'],
        'imageAsset': card['imageAsset'],
        'rarity': card['rarity'],
      },
    };
    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  static bool isSha256(String? value) {
    return value != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
  }
}
