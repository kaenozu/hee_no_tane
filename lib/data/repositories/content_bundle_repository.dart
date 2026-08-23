import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/content_validation/content_release_policy.dart';
import 'package:hee_no_tane_app/content_validation/rc1_content_policy.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

class ContentBundleLoadException implements Exception {
  final String message;
  final Object? cause;

  const ContentBundleLoadException(this.message, {this.cause});

  @override
  String toString() => 'ContentBundleLoadException: $message (cause: $cause)';
}

class ContentBundleRepository {
  static const String defaultAssetPath = 'assets/data/content_bundle.json';

  final AssetBundle _assetBundle;
  final String assetPath;

  ContentBundleRepository({
    AssetBundle? assetBundle,
    this.assetPath = defaultAssetPath,
  }) : _assetBundle = assetBundle ?? rootBundle;

  Future<ContentBundle> load() async {
    try {
      final raw = await _assetBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Content bundle root must be an object.');
      }

      final approvedBundle = ContentBundle.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      // Validate the complete source bundle's structure and IDs before the
      // RC1 policy removes any entries. Exclusions must only bypass
      // playability validation, not source-integrity validation.
      _validateStructure(approvedBundle);

      final releaseBundle = Rc1ContentPolicy.apply(approvedBundle);
      _validateEntries(releaseBundle);
      return releaseBundle;
    } catch (error) {
      throw ContentBundleLoadException('公開用コンテンツの読み込みに失敗しました。', cause: error);
    }
  }

  void _validateStructure(ContentBundle bundle) {
    final questionIds = <String>{};
    final cardIds = <String>{};
    for (final entry in bundle.entries) {
      if (!questionIds.add(entry.question.id)) {
        throw FormatException(
          'Content bundle has duplicate question id: ${entry.question.id}.',
        );
      }
      if (!cardIds.add(entry.card.id)) {
        throw FormatException(
          'Content bundle has duplicate card id: ${entry.card.id}.',
        );
      }
    }
  }

  void _validateEntries(ContentBundle bundle) {
    _validateStructure(bundle);
    for (final entry in bundle.entries) {
      if (!ContentReleasePolicy.isPlayablePair(entry.question, entry.card)) {
        throw FormatException(
          'Content bundle contains a non-playable pair: ${entry.question.id}.',
        );
      }
    }
  }
}
