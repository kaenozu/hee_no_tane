import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';

const _verifiedAt = '2026-07-29';

const _sources = <String, Map<String, String>>{
  'q_daily_life_010': {
    'sourceNote': '東京消防庁「火事があると電話局が困る」',
    'title': '火事があると電話局が困る',
    'publisher': '東京消防庁',
    'url': 'https://www.tfd.metro.tokyo.lg.jp/learning/elib/qa/qa_68.html',
    'level': 'primary',
    'evidence': '本文の、当初112番だったが誤接続が多く、1927年10月1日から119番へ変更した説明を確認。',
  },
  'q_food_005': {
    'sourceNote': '農林水産省「いちごのあれこれ豆知識」',
    'title': 'いちごのあれこれ豆知識',
    'publisher': '農林水産省',
    'url': 'https://www.maff.go.jp/j/pr/aff/1912/spe1_02.html',
    'level': 'primary',
    'evidence': 'いちご表面の粒が果実で、食用の赤い部分は花床が膨らんだ偽果である説明を確認。',
  },
  'q_food_006': {
    'sourceNote': 'HistoryExtra「Did The Earl Of Sandwich Invent The Sandwich?」',
    'title': 'Did The Earl Of Sandwich Invent The Sandwich?',
    'publisher': 'HistoryExtra',
    'url': 'https://www.historyextra.com/period/georgian/did-earl-sandwich-invent-sandwich/',
    'level': 'secondary',
    'evidence': 'John Montaguが第4代サンドイッチ伯爵で名称の由来であること、カード遊びの逸話は確証が乏しいことを確認。',
  },
  'q_food_009': {
    'sourceNote': 'ACS Chemical Biology「Enzyme That Makes You Cry」',
    'title': 'Enzyme That Makes You Cry–Crystal Structure of Lachrymatory Factor Synthase from Allium cepa',
    'publisher': 'ACS Chemical Biology',
    'url': 'https://pubs.acs.org/doi/10.1021/acschembio.7b00336',
    'level': 'primary',
    'evidence': 'タマネギ組織の破壊後に揮発性の催涙因子が形成され、眼を刺激する説明を確認。',
  },
  'q_history_007': {
    'sourceNote': '理科年表オフィシャルサイト「日本の標準時」',
    'title': '日本の標準時',
    'publisher': '国立天文台・理科年表オフィシャルサイト',
    'url': 'https://official.rikanenpyo.jp/posts/6495',
    'level': 'primary',
    'evidence': '1896年に台湾・澎湖列島・八重山・宮古列島へ西部標準時を採用し、1937年9月末に廃止した説明を確認。',
  },
  'q_language_002': {
    'sourceNote': 'コトバンク「二足の草鞋を履く」',
    'title': '二足の草鞋を履く',
    'publisher': '小学館「デジタル大辞泉」／コトバンク',
    'url': 'https://kotobank.jp/word/%E4%BA%8C%E8%B6%B3%E3%81%AE%E8%8D%89%E9%9E%8B%E3%82%92%E5%B1%A5%E3%81%8F-591957',
    'level': 'secondary',
    'evidence': '江戸時代に博徒が捕吏を兼ねることを指したという語義説明を確認。',
  },
  'q_language_005': {
    'sourceNote': 'コトバンク「大詰」',
    'title': '大詰',
    'publisher': '小学館「デジタル大辞泉」／コトバンク',
    'url': 'https://kotobank.jp/word/%E5%A4%A7%E8%A9%B0-39404',
    'level': 'secondary',
    'evidence': '歌舞伎などの多幕物における最後の幕から、物事の最終段階を意味する説明を確認。',
  },
  'q_language_009': {
    'sourceNote': 'コトバンク仏和辞典「sabotage」',
    'title': 'sabotage',
    'publisher': '小学館「プログレッシブ仏和辞典」／コトバンク',
    'url': 'https://kotobank.jp/frjaword/sabotage',
    'level': 'secondary',
    'evidence': '日本語「サボる」の語源がフランス語sabotageである説明を確認。',
  },
  'q_language_010': {
    'sourceNote': 'goo辞書「パン」',
    'title': 'パン',
    'publisher': '小学館「デジタル大辞泉」／goo辞書',
    'url': 'https://dictionary.goo.ne.jp/word/%E3%83%91%E3%83%B3/',
    'level': 'secondary',
    'evidence': '日本語のパンがポルトガル語pãoに由来するという語源表示を確認。',
  },
  'q_living_things_008': {
    'sourceNote': 'Smithsonian Magazine「Ten Wild Facts About Octopuses」',
    'title': 'Ten Wild Facts About Octopuses: They Have Three Hearts, Big Brains and Blue Blood',
    'publisher': 'Smithsonian Magazine',
    'url': 'https://www.smithsonianmag.com/science-nature/ten-wild-facts-about-octopuses-they-have-three-hearts-big-brains-and-blue-blood-7625828/',
    'level': 'secondary',
    'evidence': 'タコに3つの心臓があり、2つがえら、1つが全身へ血液を送る説明を確認。',
  },
  'q_living_things_009': {
    'sourceNote': 'Smithsonian Magazine「Ten Wild Facts About Octopuses」',
    'title': 'Ten Wild Facts About Octopuses: They Have Three Hearts, Big Brains and Blue Blood',
    'publisher': 'Smithsonian Magazine',
    'url': 'https://www.smithsonianmag.com/science-nature/ten-wild-facts-about-octopuses-they-have-three-hearts-big-brains-and-blue-blood-7625828/',
    'level': 'secondary',
    'evidence': '銅を含むヘモシアニンが酸素を運び、タコの血が青く見える説明を確認。',
  },
  'q_living_things_012': {
    'sourceNote': 'MSD Veterinary Manual「Nutrition of Rabbits」',
    'title': 'Nutrition of Rabbits',
    'publisher': 'MSD Veterinary Manual',
    'url': 'https://www.msdvetmanual.com/exotic-and-laboratory-animals/rabbits/nutrition-of-rabbits',
    'level': 'secondary',
    'evidence': 'ウサギが盲腸便を再摂取し、微生物由来タンパク質やビタミンなどを得る説明を確認。',
  },
  'q_living_things_013': {
    'sourceNote': 'Audubon「Hummingbird Flight Is Like Nothing Else in the Bird World」',
    'title': 'Hummingbird Flight Is Like Nothing Else in the Bird World',
    'publisher': 'National Audubon Society',
    'url': 'https://www.audubon.org/news/hummingbird-flight-nothing-else-bird-world',
    'level': 'secondary',
    'evidence': 'ハチドリがホバリングし、前後・上下・逆さ方向へ飛行できる説明を確認。',
  },
  'q_living_things_015': {
    'sourceNote': 'San Diego Zoo「Camel」',
    'title': 'Camel',
    'publisher': 'San Diego Zoo Wildlife Alliance',
    'url': 'https://animals.sandiegozoo.org/animals/camel',
    'level': 'secondary',
    'evidence': 'ラクダのこぶが水ではなく脂肪を蓄え、食物不足時のエネルギー源になる説明を確認。',
  },
  'q_living_things_016': {
    'sourceNote': 'National Park Service「Synchronous Fireflies at Congaree」',
    'title': 'Synchronous Fireflies at Congaree',
    'publisher': 'U.S. National Park Service',
    'url': 'https://www.nps.gov/cong/learn/nature/synchronous-fireflies-at-congaree.htm',
    'level': 'primary',
    'evidence': 'ルシフェリンと酵素ルシフェラーゼが酸素・ATPなどと反応して発光する説明を確認。',
  },
  'q_nature_geography_009': {
    'sourceNote': '気象庁「雷の発生しやすい時期や時間帯」',
    'title': '雷の発生しやすい時期や時間帯',
    'publisher': '気象庁',
    'url': 'https://www.jma.go.jp/jma/kishou/know/toppuu/thunder1-3.html',
    'level': 'primary',
    'evidence': '夏は日射で地表付近が暖まり上昇気流と積乱雲が発達し、午後に雷が多い説明を確認。',
  },
  'q_sci_001': {
    'sourceNote': 'NOAA NESDIS「Peeling Back the Layers of the Atmosphere」',
    'title': 'Peeling Back the Layers of the Atmosphere',
    'publisher': 'NOAA NESDIS',
    'url': 'https://www.nesdis.noaa.gov/news/peeling-back-the-layers-of-the-atmosphere',
    'level': 'primary',
    'evidence': '乾燥空気の体積比が窒素78.09%、酸素20.95%である表を確認。',
  },
  'q_sci_002': {
    'sourceNote': 'NASA Glenn「How Fast is the Speed of Light?」',
    'title': 'How Fast is the Speed of Light?',
    'publisher': 'NASA Glenn Research Center',
    'url': 'https://www.grc.nasa.gov/WWW/k-12/Numbers/Math/Mathematical_Thinking/how_fast_is_the_speed.htm',
    'level': 'primary',
    'evidence': '光が1秒で地球を約7.5周できるという速度比較を確認。',
  },
  'q_sci_004': {
    'sourceNote': 'NOAA Ocean Exploration「How much of the ocean has been explored?」',
    'title': 'How much of the ocean has been explored?',
    'publisher': 'NOAA Ocean Exploration',
    'url': 'https://oceanexplorer.noaa.gov/ocean-fact/explored/',
    'level': 'primary',
    'evidence': '海洋が地球表面のおよそ70%を覆う説明を確認。',
  },
  'q_science_001': {
    'sourceNote': 'GIA「ダイヤモンドについて」',
    'title': 'ダイヤモンドについて',
    'publisher': 'Gemological Institute of America',
    'url': 'https://www.gia.edu/jp/diamond-description',
    'level': 'secondary',
    'evidence': 'ダイヤモンドとグラファイトはいずれも炭素からなるが結晶構造が異なる説明を確認。',
  },
  'q_science_002': {
    'sourceNote': 'NASA GSFC「SeaWiFS: Atmospheric Correction」',
    'title': 'SeaWiFS: Atmospheric Correction',
    'publisher': 'NASA Goddard Space Flight Center',
    'url': 'https://oceancolor.gsfc.nasa.gov/SeaWiFS/TEACHERS/CORRECTIONS/',
    'level': 'primary',
    'evidence': '空気分子によるレイリー散乱が青空と赤い夕焼けの原因である説明を確認。',
  },
  'q_science_009': {
    'sourceNote': 'GPS.gov「GPS and Telling Time」',
    'title': 'GPS and Telling Time',
    'publisher': 'National Coordination Office for Space-Based PNT',
    'url': 'https://www.gps.gov/gps-and-telling-time',
    'level': 'primary',
    'evidence': '各GPS衛星が複数の原子時計を搭載し、精密な時刻情報を信号へ提供する説明を確認。',
  },
  'q_science_010': {
    'sourceNote': 'NASA Glenn「Bernoulli and Newton」',
    'title': 'Bernoulli and Newton',
    'publisher': 'NASA Glenn Research Center',
    'url': 'https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/bernoulli-and-newton/',
    'level': 'primary',
    'evidence': '翼まわりの圧力差と空気流の向きの変化が揚力に関与する説明を確認。',
  },
};

void main() {
  final questions = _readList('assets/data/questions.json');
  final cards = _readList('assets/data/cards.json');
  final questionsById = <String, Map<String, dynamic>>{
    for (final value in questions)
      (value as Map<String, dynamic>)['id'] as String: value,
  };
  final cardsById = <String, Map<String, dynamic>>{
    for (final value in cards)
      (value as Map<String, dynamic>)['id'] as String: value,
  };

  _applyCorrections(questionsById, cardsById);

  for (final entry in _sources.entries) {
    final question = questionsById[entry.key];
    if (question == null) throw StateError('Missing question ${entry.key}');
    final cardId = question['relatedCardId'] as String;
    final card = cardsById[cardId];
    if (card == null) throw StateError('Missing card $cardId');
    final pairHash = ContentFingerprint.forPair(question: question, card: card);
    final source = entry.value;
    final metadata = <String, dynamic>{
      'title': source['title'],
      'publisher': source['publisher'],
      'url': source['url'],
      'verifiedAt': _verifiedAt,
      'verificationLevel': source['level'],
      'reviewStatus': 'approved',
      'reviewNote': 'Direct evidence re-audit: ${source['evidence']}',
      'contentHash': pairHash,
    };
    question
      ..['sourceNote'] = source['sourceNote']
      ..['source'] = Map<String, dynamic>.from(metadata)
      ..['verified'] = true;
    card
      ..['sourceNote'] = source['sourceNote']
      ..['source'] = Map<String, dynamic>.from(metadata)
      ..['verified'] = true;
  }

  _writeJson('assets/data/questions.json', questions);
  _writeJson('assets/data/cards.json', cards);

  final generation = Process.runSync(
    Platform.resolvedExecutable,
    const ['run', 'tool/generate_content_bundle.dart'],
  );
  stdout.write(generation.stdout);
  stderr.write(generation.stderr);
  if (generation.exitCode != 0) {
    throw StateError('Content bundle generation failed.');
  }

  final bundle = _readObject('assets/data/content_bundle.json');
  final reviews = _readObject('review/approved_semantic_reviews.json');
  reviews
    ..['bundleHash'] = bundle['bundleHash']
    ..['entryCount'] = (bundle['entries'] as List<dynamic>).length
    ..['reviewedAt'] = _verifiedAt;
  final reviewEntries = (reviews['entries'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  for (final review in reviewEntries) {
    final questionId = review['questionId'];
    if (!_sources.containsKey(questionId)) continue;
    final question = questionsById[questionId];
    final card = cardsById[question!['relatedCardId']];
    review
      ..['contentHash'] = ContentFingerprint.forPair(
        question: question,
        card: card!,
      )
      ..['reviewedAt'] = _verifiedAt
      ..['reviewNote'] =
          'Question, choices, answer, explanation, card, and direct source evidence re-audited.';
  }
  _writeJson('review/approved_semantic_reviews.json', reviews);

  for (final path in <String>[
    'agent_source_audit_inventory.json',
    '.github/workflows/agent-upload-source-audit-inventory.yml',
    '.github/workflows/agent-apply-source-reaudit.yml',
    'tool/agent_apply_source_reaudit.dart',
  ]) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
}

void _applyCorrections(
  Map<String, Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> cards,
) {
  questions['q_food_006']!['explanation'] =
      '第4代サンドイッチ伯爵ジョン・モンタギューが名前の由来です。カード遊びを続けながら食べるために作らせたという逸話は有名ですが、確かな記録ではなく諸説あります。';
  cards['card_food_006']!
    ..['shortText'] = '第4代サンドイッチ伯爵にちなむ軽食。'
    ..['detailText'] =
        '名称は第4代サンドイッチ伯爵ジョン・モンタギューにちなみます。カード遊び中に考案したという逸話は広く知られていますが、確証はなく諸説あります。';
  questions['q_language_009']!['explanation'] =
      '「サボる」は、フランス語の「sabotage（サボタージュ）」を短くした「サボ」に、日本語の動詞化の接尾辞「る」を組み合わせた言葉です。';
  cards['card_language_009']!
    ..['shortText'] = 'フランス語由来の言葉'
    ..['detailText'] =
        '日常語の「サボる」は、フランス語sabotageに由来する「サボ」を日本語で動詞化した表現です。';
}

List<dynamic> _readList(String path) {
  final value = jsonDecode(File(path).readAsStringSync());
  if (value is! List) throw FormatException('$path root must be an array.');
  return value;
}

Map<String, dynamic> _readObject(String path) {
  final value = jsonDecode(File(path).readAsStringSync());
  if (value is! Map) throw FormatException('$path root must be an object.');
  return Map<String, dynamic>.from(value);
}

void _writeJson(String path, Object value) {
  File(path).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}
