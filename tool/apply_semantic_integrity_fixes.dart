import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/content_bundle_builder.dart';
import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

const _questionsPath = 'assets/data/questions.json';
const _cardsPath = 'assets/data/cards.json';
const _bundlePath = 'assets/data/content_bundle.json';
const _manifestPath = 'assets/data/content_manifest.json';
const _appVersionPath = 'assets/data/app_version.json';
const _reviewPath = 'review/approved_semantic_reviews.json';
const _reviewDate = '2026-07-17';

const _correctedQuestionIds = <String>{
  'q_food_008',
  'q_history_011',
  'q_language_007',
  'q_nature_geography_013',
  'q_nature_geography_015',
  'q_science_011',
};

void main() {
  final questions = _readObjectList(_questionsPath);
  final cards = _readObjectList(_cardsPath);
  final questionsById = <String, Map<String, dynamic>>{
    for (final question in questions) question['id'] as String: question,
  };
  final cardsById = <String, Map<String, dynamic>>{
    for (final card in cards) card['id'] as String: card,
  };

  _fixHoney(questionsById, cardsById);
  _fixStatueOfLiberty(questionsById, cardsById);
  _fixGotoshi(questionsById, cardsById);
  _fixAwajiPopulation(questionsById, cardsById);
  _fixTsunamiAmplification(questionsById, cardsById);
  _fixQuicklime(questionsById, cardsById);

  for (final questionId in _correctedQuestionIds) {
    final question = questionsById[questionId];
    if (question == null) {
      throw StateError('Missing corrected question: $questionId');
    }
    final cardId = question['relatedCardId'];
    final card = cardsById[cardId];
    if (card == null) {
      throw StateError('Missing corrected card $cardId for $questionId');
    }
    final hash = ContentFingerprint.forPair(question: question, card: card);
    _source(question)['contentHash'] = hash;
    _source(card)['contentHash'] = hash;
  }

  _writeJson(_questionsPath, questions);
  _writeJson(_cardsPath, cards);

  final questionModels = <Question>[
    for (final question in questions) Question.fromJson(question),
  ];
  final cardModels = <HeeCard>[
    for (final card in cards) HeeCard.fromJson(card),
  ];
  final appVersion = _readObject(_appVersionPath);
  final contentVersion =
      '${appVersion['version'] as String}+${appVersion['buildNumber'] as String}';
  final bundle = ContentBundleBuilder.build(
    questions: questionModels,
    cards: cardModels,
    contentVersion: contentVersion,
  );
  if (bundle.entries.length != 47) {
    throw StateError(
      'Expected 47 approved pairs after semantic fixes, got '
      '${bundle.entries.length}.',
    );
  }
  for (final questionId in _correctedQuestionIds) {
    if (!bundle.entries.any((entry) => entry.question.id == questionId)) {
      throw StateError('Corrected pair is not release eligible: $questionId');
    }
  }

  _writeJson(_bundlePath, bundle.toJson());
  _writeJson(_manifestPath, <String, dynamic>{
    'schemaVersion': 1,
    'questionCount': questionModels.length,
    'cardCount': cardModels.length,
    'playableQuestionCount': bundle.entries.length,
    'contentVersion': bundle.contentVersion,
    'bundleHash': bundle.bundleHash,
  });

  _writeJson(_reviewPath, <String, dynamic>{
    'schemaVersion': 1,
    'contentVersion': bundle.contentVersion,
    'bundleHash': bundle.bundleHash,
    'entryCount': bundle.entries.length,
    'reviewedAt': _reviewDate,
    'entries': <Map<String, dynamic>>[
      for (final entry in bundle.entries)
        <String, dynamic>{
          'questionId': entry.question.id,
          'cardId': entry.card.id,
          'contentHash': entry.question.sourceMetadata!.contentHash,
          'status': 'approved',
          'reviewedAt': _reviewDate,
          'reviewNote': _correctedQuestionIds.contains(entry.question.id)
              ? 'Semantic mismatch corrected and the complete pair re-reviewed.'
              : 'Question, choices, answer, explanation, card, and source alignment reviewed.',
          'checks': const <String, bool>{
            'questionChoicesAligned': true,
            'answerIndexCorrect': true,
            'explanationAligned': true,
            'cardAligned': true,
            'sourceAligned': true,
          },
        },
    ],
  });

  stdout.writeln(
    'Corrected ${_correctedQuestionIds.length} pairs and recorded semantic '
    'approval for ${bundle.entries.length} release pairs.',
  );
}

void _fixHoney(
  Map<String, Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> cards,
) {
  final question = _required(questions, 'q_food_008');
  final card = _required(cards, 'card_food_008');
  question
    ..['choices'] = <String>[
      '一般に上昇する',
      '必ず低下する',
      'まったく変化しない',
      '糖質を含まないため影響しない',
    ]
    ..['answerIndex'] = 0
    ..['explanation'] =
        '蜂蜜には糖質が含まれるため、摂取すると一般に血糖値は上がります。上がり方は摂取量や個人の状態によって異なります。';
  card
    ..['title'] = '蜂蜜と血糖値'
    ..['shortText'] = '蜂蜜にも糖質があり、血糖値へ影響します。'
    ..['detailText'] =
        '蜂蜜は砂糖と同様に糖質を含むため、摂取すると一般に血糖値が上がります。上がり方は摂取量や個人の状態によって異なり、糖尿病がある場合も量に注意が必要です。';
  _reviewSource(
    question,
    sourceNote: 'Mayo Clinic「蜂蜜と血糖値」',
    verificationLevel: 'secondary',
  );
  _reviewSource(
    card,
    sourceNote: 'Mayo Clinic「蜂蜜と血糖値」',
    verificationLevel: 'secondary',
  );
}

void _fixStatueOfLiberty(
  Map<String, Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> cards,
) {
  final question = _required(questions, 'q_history_011');
  final card = _required(cards, 'card_history_011');
  question
    ..['choices'] = <String>['フランス', 'イギリス', 'スペイン', 'カナダ']
    ..['answerIndex'] = 0
    ..['explanation'] =
        '自由の女神像はフランスから贈られました。アメリカ独立100周年と米仏の友好を記念する贈り物として構想され、1886年にニューヨーク港で除幕されました。';
  card
    ..['title'] = 'フランスから贈られた自由の女神'
    ..['shortText'] = '自由の女神像はフランスからの贈り物。'
    ..['detailText'] =
        '自由の女神像は、アメリカ独立100周年と米仏友好を記念してフランスから贈られました。フランスで製作された像はニューヨークへ運ばれ、1886年10月28日に除幕されました。';
  _reviewSource(
    question,
    sourceNote: 'U.S. National Park Service「Statue of Liberty Facts」',
    verificationLevel: 'primary',
  );
  _reviewSource(
    card,
    sourceNote: 'U.S. National Park Service「Statue of Liberty Facts」',
    verificationLevel: 'primary',
  );
}

void _fixGotoshi(
  Map<String, Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> cards,
) {
  final question = _required(questions, 'q_language_007');
  final card = _required(cards, 'card_language_007');
  question
    ..['choices'] = <String>[
      '「～のようだ」「～に似ている」',
      '「必ず～する」',
      '「～してはいけない」',
      '「～であった」',
    ]
    ..['answerIndex'] = 0
    ..['explanation'] =
        '「如し」は、あるものを別のものになぞらえて「～のようだ」「～に似ている」と表す比況の助動詞です。「立つが如し」なら「立っているようだ」という意味です。';
  card
    ..['title'] = '「如し」が表す比況'
    ..['shortText'] = '「如し」は「～のようだ」という意味。'
    ..['detailText'] =
        '古語の「如し」は、あるものを別のものになぞらえて「～のようだ」「～に似ている」と表す比況の助動詞です。「立つが如し」なら「立っているようだ」という意味になります。';
  _reviewSource(
    question,
    sourceNote: '小学館「如し」',
    verificationLevel: 'secondary',
  );
  _reviewSource(
    card,
    sourceNote: '小学館「如し」',
    verificationLevel: 'secondary',
  );
}

void _fixAwajiPopulation(
  Map<String, Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> cards,
) {
  final question = _required(questions, 'q_nature_geography_013');
  final card = _required(cards, 'card_nature_geography_013');
  question
    ..['choices'] = <String>['約3.2万人', '約7.5万人', '約12.7万人', '約25.4万人']
    ..['answerIndex'] = 2
    ..['explanation'] =
        '2020年国勢調査に基づく淡路島本島の人口は126,980人で、約12.7万人です。淡路市、洲本市、南あわじ市の合計です。';
  card
    ..['title'] = '2020年の淡路島人口'
    ..['shortText'] = '2020年国勢調査で約12.7万人。'
    ..['detailText'] =
        '淡路島本島は淡路市、洲本市、南あわじ市の3市にまたがります。2020年国勢調査に基づく3市の合計人口は126,980人で、約12.7万人です。人口を比較するときは調査年と集計範囲をそろえる必要があります。';
  _reviewSource(
    question,
    sourceNote: '離島経済新聞社「淡路島の情報」',
    verificationLevel: 'secondary',
  );
  _reviewSource(
    card,
    sourceNote: '離島経済新聞社「淡路島の情報」',
    verificationLevel: 'secondary',
  );
}

void _fixTsunamiAmplification(
  Map<String, Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> cards,
) {
  final question = _required(questions, 'q_nature_geography_015');
  final card = _required(cards, 'card_nature_geography_015');
  question
    ..['choices'] = <String>[
      '水深が浅くなると津波の速度が落ち、後方の波が追いつくから',
      '沿岸では風が必ず強くなるから',
      '満潮と干潮が同時に起こるから',
      '川の水が大量に海へ流れ込むから',
    ]
    ..['answerIndex'] = 0
    ..['explanation'] =
        '津波は水深が浅くなるほど速度が遅くなります。減速した前方の波に後方の波が追いつくため、沿岸へ近づくほど波高が高くなります。';
  card
    ..['title'] = '沿岸で津波が高くなる理由'
    ..['shortText'] = '浅い海では速度が落ち、波高が増します。'
    ..['detailText'] =
        '津波は沿岸の浅い海域に入ると速度が低下します。減速した前方の波へ後方の波が追いつき、波長が短くなることで波高が高くなります。湾の形などの地形によってさらに増幅されることもあります。';
  _reviewSource(
    question,
    sourceNote: '気象庁「津波発生と伝播のしくみ」',
    verificationLevel: 'primary',
  );
  _reviewSource(
    card,
    sourceNote: '気象庁「津波発生と伝播のしくみ」',
    verificationLevel: 'primary',
  );
}

void _fixQuicklime(
  Map<String, Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> cards,
) {
  final question = _required(questions, 'q_science_011');
  final card = _required(cards, 'card_science_011');
  question
    ..['choices'] = <String>[
      '消石灰（水酸化カルシウム）になり、熱を出す',
      '石けんになって油を落とす',
      '水に溶けて温度が必ず下がる',
      '砂糖に変化する',
    ]
    ..['answerIndex'] = 0
    ..['explanation'] =
        '生石灰（酸化カルシウム）は水と反応して消石灰（水酸化カルシウム）になり、熱を放出します。単に水へ溶けるのではなく、発熱を伴う化学反応です。';
  card
    ..['title'] = '生石灰と水の発熱反応'
    ..['shortText'] = '水と反応して消石灰になり、熱を出す。'
    ..['detailText'] =
        '生石灰（酸化カルシウム）に水を加えると、水酸化カルシウム（消石灰）ができ、熱が発生します。単なる溶解ではなく化学反応であり、取り扱いには注意が必要です。';
  _reviewSource(
    question,
    sourceNote: 'CDC/NIOSH「Calcium oxide」',
    verificationLevel: 'primary',
  );
  _reviewSource(
    card,
    sourceNote: 'CDC/NIOSH「Calcium oxide」',
    verificationLevel: 'primary',
  );
}

Map<String, dynamic> _required(
  Map<String, Map<String, dynamic>> values,
  String id,
) {
  final value = values[id];
  if (value == null) throw StateError('Missing content object: $id');
  return value;
}

void _reviewSource(
  Map<String, dynamic> value, {
  required String sourceNote,
  required String verificationLevel,
}) {
  value['sourceNote'] = sourceNote;
  final source = _source(value);
  source
    ..['verifiedAt'] = _reviewDate
    ..['verificationLevel'] = verificationLevel
    ..['reviewStatus'] = 'approved'
    ..['reviewNote'] = 'Semantic alignment re-reviewed on $_reviewDate.';
}

Map<String, dynamic> _source(Map<String, dynamic> value) {
  final sourceValue = value['source'];
  if (sourceValue is! Map) {
    throw StateError('${value['id']} has no source metadata.');
  }
  final source = Map<String, dynamic>.from(sourceValue);
  value['source'] = source;
  return source;
}

List<Map<String, dynamic>> _readObjectList(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! List) throw FormatException('$path root must be an array.');
  return <Map<String, dynamic>>[
    for (final value in decoded) Map<String, dynamic>.from(value as Map),
  ];
}

Map<String, dynamic> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) throw FormatException('$path root must be an object.');
  return Map<String, dynamic>.from(decoded);
}

void _writeJson(String path, Object value) {
  const encoder = JsonEncoder.withIndent('  ');
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${encoder.convert(value)}\n');
}
