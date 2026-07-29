import 'dart:convert';
import 'dart:io';

const targetQuestionIds = <String>{
  'q_daily_life_010',
  'q_food_005',
  'q_food_006',
  'q_food_009',
  'q_history_007',
  'q_language_002',
  'q_language_005',
  'q_language_009',
  'q_language_010',
  'q_living_things_008',
  'q_living_things_009',
  'q_living_things_012',
  'q_living_things_013',
  'q_living_things_015',
  'q_living_things_016',
  'q_nature_geography_009',
  'q_sci_001',
  'q_sci_002',
  'q_sci_004',
  'q_science_001',
  'q_science_002',
  'q_science_009',
  'q_science_010',
};

void main() {
  final questions = (jsonDecode(
    File('assets/data/questions.json').readAsStringSync(),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  final cards = (jsonDecode(
    File('assets/data/cards.json').readAsStringSync(),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  final cardsById = <String, Map<String, dynamic>>{
    for (final card in cards) card['id'] as String: card,
  };

  final result = <Map<String, dynamic>>[];
  for (final question in questions) {
    final id = question['id'] as String;
    if (!targetQuestionIds.contains(id)) continue;
    final cardId = question['relatedCardId'] as String;
    final card = cardsById[cardId];
    if (card == null) throw StateError('Missing card $cardId for $id');
    result.add({
      'question': question,
      'card': card,
    });
  }
  result.sort((a, b) {
    final left = (a['question'] as Map<String, dynamic>)['id'] as String;
    final right = (b['question'] as Map<String, dynamic>)['id'] as String;
    return left.compareTo(right);
  });

  final found = <String>{
    for (final pair in result)
      (pair['question'] as Map<String, dynamic>)['id'] as String,
  };
  final missing = targetQuestionIds.difference(found);
  if (missing.isNotEmpty) {
    throw StateError('Missing target question ids: ${missing.join(', ')}');
  }

  File('agent_source_audit_inventory.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(result),
  );
  File('.github/workflows/agent-extract-source-audit.yml').deleteSync();
  File('tool/agent_extract_23_source_audit.dart').deleteSync();
}
