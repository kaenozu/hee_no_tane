/// Higher-precision risk extraction and review-CSV image annotations.
library;

import 'dart:convert';

import 'package:hee_no_tane_app/content_review/content_review_workflow.dart';

const enhancedContentReviewColumns = contentReviewColumns;

const contentImageFitValues = <String>{
  'unchecked',
  'approved',
  'fit',
  'generic_placeholder',
  'replace_required',
};

class ContentRiskRecord {
  final String questionId;
  final String cardId;
  final String category;
  final List<String> reasons;
  final List<String> duplicateQuestionIds;
  final String question;
  final String answer;
  final String explanation;
  final String cardTitle;
  final String cardDetail;

  const ContentRiskRecord({
    required this.questionId,
    required this.cardId,
    required this.category,
    required this.reasons,
    required this.duplicateQuestionIds,
    required this.question,
    required this.answer,
    required this.explanation,
    required this.cardTitle,
    required this.cardDetail,
  });
}

class _RiskCandidate {
  final String questionId;
  final String cardId;
  final String category;
  final String question;
  final String answer;
  final String explanation;
  final String cardTitle;
  final String cardDetail;
  final String text;
  final List<String> reasons;
  final Set<String> questionPairs;
  final Set<String> evidencePairs;
  final Set<String> duplicateQuestionIds = <String>{};

  _RiskCandidate({
    required this.questionId,
    required this.cardId,
    required this.category,
    required this.question,
    required this.answer,
    required this.explanation,
    required this.cardTitle,
    required this.cardDetail,
    required this.text,
    required this.reasons,
    required this.questionPairs,
    required this.evidencePairs,
  });
}

class ContentRiskClassifier {
  const ContentRiskClassifier();

  String enhanceReviewCsv({
    required String baseCsv,
    required String cardsJson,
  }) {
    final table = _parseCsv(baseCsv);
    if (table.isEmpty || !_sameStrings(table.first, contentReviewColumns)) {
      throw const ContentReviewException(
        'base review CSV header does not match contentReviewColumns',
      );
    }
    return _encodeCsv(table);
  }

  String stripReviewCsv({
    required String reviewCsv,
    required String cardsJson,
  }) {
    final table = _parseCsv(reviewCsv);
    if (table.isEmpty || !_sameStrings(table.first, contentReviewColumns)) {
      throw const ContentReviewException(
        'review CSV header does not match contentReviewColumns',
      );
    }
    final cards = _decodeCollection(cardsJson, 'cards');
    final cardsById = _byId(cards, 'cards');
    final cardIdIndex = contentReviewColumns.indexOf('cardId');
    final imageAssetIndex = contentReviewColumns.indexOf('imageAsset');
    final imageStatusIndex = contentReviewColumns.indexOf('imageReviewStatus');
    for (var index = 1; index < table.length; index++) {
      final row = table[index];
      if (row.every((value) => value.isEmpty)) continue;
      if (row.length != contentReviewColumns.length) {
        throw ContentReviewException(
          'review CSV row ${index + 1} has ${row.length} columns; '
          'expected ${contentReviewColumns.length}',
        );
      }
      final cardId = row[cardIdIndex];
      final card = cardsById[cardId];
      if (card == null) {
        throw ContentReviewException('unknown cardId in review CSV: $cardId');
      }
      final expectedAsset = card['imageAsset'] is String
          ? card['imageAsset'] as String
          : '';
      if (row[imageAssetIndex] != expectedAsset) {
        throw ContentReviewException(
          '$cardId changed immutable CSV field imageAsset',
        );
      }
      final status = row[imageStatusIndex].trim();
      if (!contentImageFitValues.contains(status)) {
        throw ContentReviewException(
          '$cardId has invalid imageReviewStatus: $status',
        );
      }
    }
    return _encodeCsv(table);
  }

  List<ContentRiskRecord> risks({
    required String questionsJson,
    required String cardsJson,
  }) {
    final questions = _decodeCollection(questionsJson, 'questions');
    final cards = _decodeCollection(cardsJson, 'cards');
    final cardsById = _byId(cards, 'cards');
    final candidates = <_RiskCandidate>[];

    for (final question in questions) {
      final questionId = _requiredString(question, 'id', 'question');
      final cardId = _requiredString(question, 'relatedCardId', questionId);
      final card = cardsById[cardId];
      if (card == null) continue;
      final choices = _stringList(question['choices'], '$questionId.choices');
      final answerIndex = question['answerIndex'];
      if (answerIndex is! int ||
          answerIndex < 0 ||
          answerIndex >= choices.length) {
        continue;
      }
      final category = _requiredString(question, 'category', questionId);
      final questionText = _requiredString(question, 'question', questionId);
      final answer = choices[answerIndex];
      final explanation = _requiredString(question, 'explanation', questionId);
      final cardTitle = _requiredString(card, 'title', cardId);
      final cardDetail = _requiredString(card, 'detailText', cardId);
      final text = [
        questionText,
        ...choices,
        explanation,
        cardTitle,
        card['shortText'],
        cardDetail,
      ].whereType<String>().join(' ');
      final evidenceText = '$questionText $explanation $cardTitle $cardDetail';
      candidates.add(
        _RiskCandidate(
          questionId: questionId,
          cardId: cardId,
          category: category,
          question: questionText,
          answer: answer,
          explanation: explanation,
          cardTitle: cardTitle,
          cardDetail: cardDetail,
          text: text,
          reasons: _riskReasons(text, category),
          questionPairs: _characterPairs(_normalizeFactText(questionText)),
          evidencePairs: _characterPairs(_normalizeFactText(evidenceText)),
        ),
      );
    }

    for (var left = 0; left < candidates.length; left++) {
      for (var right = left + 1; right < candidates.length; right++) {
        final first = candidates[left];
        final second = candidates[right];
        if (!_isDuplicateFact(first, second)) continue;
        first.duplicateQuestionIds.add(second.questionId);
        second.duplicateQuestionIds.add(first.questionId);
      }
    }

    return List.unmodifiable([
      for (final candidate in candidates)
        if (candidate.reasons.isNotEmpty ||
            candidate.duplicateQuestionIds.isNotEmpty)
          ContentRiskRecord(
            questionId: candidate.questionId,
            cardId: candidate.cardId,
            category: candidate.category,
            reasons: List.unmodifiable([
              ...candidate.reasons,
              if (candidate.duplicateQuestionIds.isNotEmpty) 'duplicate_fact',
            ]),
            duplicateQuestionIds: List.unmodifiable(
              candidate.duplicateQuestionIds.toList()..sort(),
            ),
            question: candidate.question,
            answer: candidate.answer,
            explanation: candidate.explanation,
            cardTitle: candidate.cardTitle,
            cardDetail: candidate.cardDetail,
          ),
    ]);
  }

  String riskCsv({required String questionsJson, required String cardsJson}) {
    final rows = <List<String>>[
      const [
        'questionId',
        'cardId',
        'category',
        'riskReasons',
        'duplicateQuestionIds',
        'question',
        'answer',
        'explanation',
        'cardTitle',
        'cardDetail',
      ],
      for (final risk in risks(
        questionsJson: questionsJson,
        cardsJson: cardsJson,
      ))
        [
          risk.questionId,
          risk.cardId,
          risk.category,
          risk.reasons.join('|'),
          risk.duplicateQuestionIds.join('|'),
          risk.question,
          risk.answer,
          risk.explanation,
          risk.cardTitle,
          risk.cardDetail,
        ],
    ];
    return _encodeCsv(rows);
  }

  List<String> _riskReasons(String text, String category) {
    final reasons = <String>[];
    if (RegExp(r'[0-9０-９]|[%％]|約\s*[一二三四五六七八九十百千万億兆]').hasMatch(text)) {
      reasons.add('numeric');
    }

    final hasRanking = RegExp(
      r'最も|いちばん|一番|世界一|日本一|最大|最小|最多|最少|'
      r'ランキング|第[0-9０-９]+位',
    ).hasMatch(text);
    final hasDynamicRankingContext = RegExp(
      r'現在|現時点|最新|今年|昨年|今季|生産量|人口|売上|市場占有率|'
      r'シェア|価格|時価|順位',
    ).hasMatch(text);
    if (hasRanking) {
      reasons.add(
        hasDynamicRankingContext ? 'dynamic_ranking' : 'stable_comparison',
      );
    }

    final hasCurrentLanguage = RegExp(
      r'現在|現時点|現職|今の|いまの|最新|今年|今季',
    ).hasMatch(text);
    final hasRole = RegExp(
      r'首相|大統領|知事|市長|社長|CEO|会長|議長|長官|大臣|'
      r'代表取締役|監督',
      caseSensitive: false,
    ).hasMatch(text);
    if (hasCurrentLanguage && hasRole) {
      reasons.add('current_role');
    } else if (hasCurrentLanguage) {
      reasons.add('current_fact');
    }

    final hasHumanHealth = RegExp(
      r'病気|医療|治療|薬|症状|健康|診断|予防|患者|服用|副作用|'
      r'がん|癌|感染症|ワクチン|血圧|血糖',
    ).hasMatch(text);
    if (hasHumanHealth && category != 'living_things') {
      reasons.add('human_health');
    }
    if (RegExp(
      r'心臓|血液|脳|肺|肝臓|腎臓|胃|腸|神経|骨|筋肉|'
      r'消化器|循環器|解剖|器官|細胞|遺伝子|栄養',
    ).hasMatch(text)) {
      reasons.add('biological_anatomy');
    }
    if (RegExp(r'法律|法令|違法|罰金|刑罰|権利|義務|裁判|契約|税制|税金').hasMatch(text)) {
      reasons.add('legal');
    }
    if (RegExp(
      r'投資|株式|為替|金利|ローン|保険|年金|資産運用|'
      r'買うべき|売るべき|儲かる|利益を得る',
    ).hasMatch(text)) {
      reasons.add('financial_advice');
    }
    if (RegExp(r'価格|値段|相場|時価|製造コスト|製造原価|原価|費用|いくら').hasMatch(text)) {
      reasons.add('dynamic_price');
    }
    if (RegExp(r'紙幣|硬貨|貨幣|通貨|コイン').hasMatch(text) &&
        RegExp(r'歴史|発行|制定|採用|肖像|図柄|デザイン|年|時代|最初|初').hasMatch(text)) {
      reasons.add('currency_history');
    }
    return reasons;
  }

  bool _isDuplicateFact(_RiskCandidate first, _RiskCandidate second) {
    final questionSimilarity = _similarity(
      first.questionPairs,
      second.questionPairs,
    );
    final evidenceSimilarity = _similarity(
      first.evidencePairs,
      second.evidencePairs,
    );

    // Correct answers are intentionally excluded from duplicate evidence. Generic
    // answers such as an era, number, or title can be shared by unrelated facts.
    return (questionSimilarity >= 0.50 && evidenceSimilarity >= 0.25) ||
        (questionSimilarity >= 0.40 && evidenceSimilarity >= 0.38);
  }

  double _similarity(Set<String> left, Set<String> right) {
    if (left.isEmpty || right.isEmpty) return 0;
    final overlap = left.intersection(right).length;
    return (2 * overlap) / (left.length + right.length);
  }

  Set<String> _characterPairs(String value) {
    if (value.isEmpty) return const <String>{};
    if (value.length == 1) return <String>{value};
    return <String>{
      for (var index = 0; index < value.length - 1; index++)
        value.substring(index, index + 2),
    };
  }

  String _normalizeFactText(String value) {
    var normalized = value.toLowerCase().replaceAll(
      RegExp(r'[\s、。！？!?…・「」『』（）()【】\[\]／/：:；;,.ー\-]'),
      '',
    );
    for (final filler in const ['一般に', 'だいたい', 'でしょうか', 'と言われている', 'といわれている']) {
      normalized = normalized.replaceAll(filler, '');
    }
    return normalized;
  }

  List<Map<String, dynamic>> _decodeCollection(String source, String label) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw ContentReviewException('$label JSON is invalid: ${error.message}');
    }
    if (decoded is! List) {
      throw ContentReviewException('$label JSON root must be an array');
    }
    return [
      for (var index = 0; index < decoded.length; index++)
        if (decoded[index] is Map)
          Map<String, dynamic>.from(decoded[index] as Map)
        else
          throw ContentReviewException('$label[$index] must be an object'),
    ];
  }

  Map<String, Map<String, dynamic>> _byId(
    List<Map<String, dynamic>> items,
    String label,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final id = _requiredString(item, 'id', label);
      if (result.containsKey(id)) {
        throw ContentReviewException('duplicate ID in $label: $id');
      }
      result[id] = item;
    }
    return result;
  }

  String _requiredString(
    Map<String, dynamic> item,
    String field,
    String label,
  ) {
    final value = item[field];
    if (value is! String || value.isEmpty) {
      throw ContentReviewException('$label.$field must be a non-empty string');
    }
    return value;
  }

  List<String> _stringList(Object? value, String label) {
    if (value is! List || value.any((item) => item is! String)) {
      throw ContentReviewException('$label must be a string array');
    }
    return List<String>.from(value);
  }

  String _encodeCsv(List<List<String>> rows) {
    return '${rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n')}\r\n';
  }

  String _escapeCsv(String value) {
    if (!value.contains(RegExp(r'[,"\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  List<List<String>> _parseCsv(String input) {
    var source = input;
    if (source.startsWith('\ufeff')) source = source.substring(1);
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var inQuotes = false;
    var quoteClosed = false;

    void finishField() {
      row.add(field.toString());
      field = StringBuffer();
      quoteClosed = false;
    }

    void finishRow() {
      finishField();
      rows.add(row);
      row = <String>[];
    }

    for (var index = 0; index < source.length; index++) {
      final char = source[index];
      if (inQuotes) {
        if (char == '"') {
          if (index + 1 < source.length && source[index + 1] == '"') {
            field.write('"');
            index++;
          } else {
            inQuotes = false;
            quoteClosed = true;
          }
        } else {
          field.write(char);
        }
        continue;
      }
      if (quoteClosed && char != ',' && char != '\r' && char != '\n') {
        throw ContentReviewException(
          'unexpected character after closing quote at offset $index',
        );
      }
      if (char == '"') {
        if (field.isNotEmpty) {
          throw ContentReviewException(
            'unexpected quote in unquoted field at offset $index',
          );
        }
        inQuotes = true;
      } else if (char == ',') {
        finishField();
      } else if (char == '\n') {
        finishRow();
      } else if (char == '\r') {
        if (index + 1 < source.length && source[index + 1] == '\n') index++;
        finishRow();
      } else {
        field.write(char);
      }
    }
    if (inQuotes) {
      throw const ContentReviewException(
        'CSV contains an unclosed quoted field',
      );
    }
    if (field.isNotEmpty || row.isNotEmpty || quoteClosed) finishRow();
    if (rows.isNotEmpty && rows.last.every((value) => value.isEmpty)) {
      rows.removeLast();
    }
    return rows;
  }

  bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
