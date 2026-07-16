import 'package:hee_no_tane_app/content_validation/content_release_policy.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

class ContentBundleBuilder {
  const ContentBundleBuilder._();

  static ContentBundle build({
    required List<Question> questions,
    required List<HeeCard> cards,
    required String contentVersion,
  }) {
    _requireUniqueIds(
      values: questions.map((question) => question.id),
      label: 'question',
    );
    _requireUniqueIds(
      values: cards.map((card) => card.id),
      label: 'card',
    );

    final cardsById = <String, HeeCard>{
      for (final card in cards) card.id: card,
    };
    final entries = <ContentBundleEntry>[];
    for (final question in questions) {
      final card = cardsById[question.relatedCardId];
      if (card != null && ContentReleasePolicy.isPlayablePair(question, card)) {
        entries.add(ContentBundleEntry(question: question, card: card));
      }
    }

    if (entries.isEmpty) {
      throw const FormatException(
        'No approved question/card pairs are available for the bundle.',
      );
    }

    return ContentBundle.create(
      contentVersion: contentVersion,
      entries: entries,
    );
  }

  static void _requireUniqueIds({
    required Iterable<String> values,
    required String label,
  }) {
    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(value)) {
        throw FormatException('Duplicate $label id in content source: $value.');
      }
    }
  }
}
