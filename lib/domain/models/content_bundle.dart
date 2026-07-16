import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

class ContentBundleEntry {
  final Question question;
  final HeeCard card;

  const ContentBundleEntry({required this.question, required this.card});

  factory ContentBundleEntry.fromJson(Map<String, dynamic> json) {
    final questionValue = json['question'];
    final cardValue = json['card'];
    if (questionValue is! Map || cardValue is! Map) {
      throw const FormatException(
        'Content bundle entries must contain question and card objects.',
      );
    }

    return ContentBundleEntry(
      question: Question.fromJson(Map<String, dynamic>.from(questionValue)),
      card: HeeCard.fromJson(Map<String, dynamic>.from(cardValue)),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'question': question.toJson(),
    'card': card.toJson(),
  };
}

class ContentBundle {
  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final String contentVersion;
  final List<ContentBundleEntry> entries;
  final String bundleHash;

  ContentBundle._({
    required this.schemaVersion,
    required this.contentVersion,
    required List<ContentBundleEntry> entries,
    required this.bundleHash,
  }) : entries = List<ContentBundleEntry>.unmodifiable(entries);

  factory ContentBundle.create({
    required String contentVersion,
    required List<ContentBundleEntry> entries,
  }) {
    final normalizedVersion = contentVersion.trim();
    if (normalizedVersion.isEmpty) {
      throw const ArgumentError('contentVersion must not be empty.');
    }
    if (entries.isEmpty) {
      throw const ArgumentError('Content bundle must not be empty.');
    }

    final sortedEntries = List<ContentBundleEntry>.from(entries)
      ..sort((left, right) => left.question.id.compareTo(right.question.id));
    final bundle = ContentBundle._(
      schemaVersion: currentSchemaVersion,
      contentVersion: normalizedVersion,
      entries: sortedEntries,
      bundleHash: '',
    );

    return ContentBundle._(
      schemaVersion: bundle.schemaVersion,
      contentVersion: bundle.contentVersion,
      entries: bundle.entries,
      bundleHash: bundle.calculateHash(),
    );
  }

  factory ContentBundle.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported content bundle schema version: $schemaVersion.',
      );
    }

    final contentVersion = _requiredString(json, 'contentVersion');
    final entryCount = json['entryCount'];
    final entriesValue = json['entries'];
    if (entryCount is! int || entriesValue is! List) {
      throw const FormatException(
        'Content bundle entryCount and entries are invalid.',
      );
    }

    final entries = <ContentBundleEntry>[
      for (final entry in entriesValue)
        ContentBundleEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
    ];
    if (entryCount != entries.length) {
      throw FormatException(
        'Content bundle entryCount $entryCount does not match ${entries.length}.',
      );
    }
    if (entries.isEmpty) {
      throw const FormatException('Content bundle must not be empty.');
    }

    final bundleHash = _requiredString(json, 'bundleHash');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(bundleHash)) {
      throw const FormatException('Content bundle hash must be SHA-256.');
    }

    final bundle = ContentBundle._(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      entries: entries,
      bundleHash: bundleHash,
    );
    if (bundle.calculateHash() != bundle.bundleHash) {
      throw const FormatException('Content bundle hash does not match payload.');
    }

    return bundle;
  }

  List<Question> get questions => List<Question>.unmodifiable(
    entries.map((entry) => entry.question),
  );

  List<HeeCard> get cards => List<HeeCard>.unmodifiable(
    entries.map((entry) => entry.card),
  );

  Map<String, dynamic> payloadToJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'contentVersion': contentVersion,
    'entryCount': entries.length,
    'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...payloadToJson(),
    'bundleHash': bundleHash,
  };

  String calculateHash() => sha256
      .convert(utf8.encode(jsonEncode(payloadToJson())))
      .toString();

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Content bundle $key must be a non-empty string.');
    }
    return value.trim();
  }
}
