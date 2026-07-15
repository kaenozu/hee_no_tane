#!/usr/bin/env python3
"""Apply and validate the known duplicate-content cleanup."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
QUESTIONS = ROOT / "assets/data/questions.json"
CARDS = ROOT / "assets/data/cards.json"
MANIFEST = ROOT / "assets/data/content_manifest.json"
REPORT = ROOT / "review/content_review_batch_3.md"
REAL_DATA_TEST = ROOT / "test/content_review/content_risk_classifier_real_data_test.dart"

SOURCE_METADATA: dict[str, dict[str, str]] = {
    "q_food_011": {
        "sourceTitle": "The capsaicin receptor: a heat-activated ion channel in the pain pathway",
        "sourcePublisher": "Nature",
        "sourceUrl": "https://www.nature.com/articles/389816a0",
        "verifiedAt": "2026-07-15",
        "verificationLevel": "primary",
        "reviewStatus": "approved",
        "reviewNote": (
            "Caterina et al. cloned the capsaicin receptor and showed that it is "
            "a heat-activated ion channel; the receptor is now designated TRPV1."
        ),
    },
    "q_bio_003": {
        "sourceTitle": (
            "The cuttlefish Sepia officinalis (Sepiidae, Cephalopoda) constructs "
            "cuttlebone from a liquid-crystal precursor"
        ),
        "sourcePublisher": "Scientific Reports",
        "sourceUrl": "https://www.nature.com/articles/srep11513",
        "verifiedAt": "2026-07-15",
        "verificationLevel": "primary",
        "reviewStatus": "approved",
        "reviewNote": (
            "The original research article identifies cuttlebone as the "
            "sophisticated buoyancy device of cuttlefish."
        ),
    },
    "q_living_things_006": {
        "sourceTitle": "Vampire squid: detritivores in the oxygen minimum zone",
        "sourcePublisher": "Proceedings of the Royal Society B",
        "sourceUrl": "https://royalsocietypublishing.org/doi/10.1098/rspb.2012.1357",
        "verifiedAt": "2026-07-15",
        "verificationLevel": "primary",
        "reviewStatus": "approved",
        "reviewNote": (
            "Hoving and Robison documented vampire squid collecting detrital "
            "material with retractile filaments and consuming it with mucus."
        ),
    },
    "q_lang_003": {
        "sourceTitle": "ヘボン式ローマ字綴方表",
        "sourcePublisher": "外務省",
        "sourceUrl": "https://www.mofa.go.jp/mofaj/toko/passport/download/romaji.html",
        "verifiedAt": "2026-07-15",
        "verificationLevel": "primary",
        "reviewStatus": "approved",
        "reviewNote": "外務省の旅券用ヘボン式ローマ字綴方表は、ひらがなの「し」をSHIと示している。",
    },
}

QUESTION_UPDATES: dict[str, dict[str, Any]] = {
    "q_food_011": {
        "difficulty": "normal",
        "question": "唐辛子の辛味成分カプサイシンが活性化する受容体は？",
        "choices": ["TRPV1", "インスリン受容体", "メラトニン受容体", "アセチルコリン受容体"],
        "answerIndex": 0,
        "explanation": (
            "1997年のNature論文は、カプサイシンに反応する受容体をクローニングし、"
            "熱でも活性化するイオンチャネルとして報告しました。現在、この受容体はTRPV1と呼ばれます。"
        ),
        "sourceNote": "Caterinaほか（1997）Nature",
    },
    "q_bio_003": {
        "difficulty": "normal",
        "question": "コウイカの体内にある「甲（カトルボーン）」の主な役割は？",
        "choices": ["浮力を調節する", "獲物を切る", "墨を作る", "音を出す"],
        "answerIndex": 0,
        "explanation": (
            "コウイカの甲は多数の小部屋を持つ軽い内部構造で、研究論文では高度な浮力装置と説明されています。"
            "体内で浮き沈みを調節する役割があります。"
        ),
        "sourceNote": "Checaほか（2015）Scientific Reports",
    },
    "q_living_things_006": {
        "difficulty": "normal",
        "question": "深海にすむコウモリダコが主に集めて食べるものは？",
        "choices": ["沈降する有機物（マリンスノー）", "生きた大型魚", "海底の岩石", "海藻だけ"],
        "answerIndex": 0,
        "explanation": (
            "コウモリダコは長い感覚糸で、死んだ生物の破片や糞粒など、海中を沈む有機物を集めます。"
            "それらを粘液でまとめて食べるデトリタス食者です。"
        ),
        "sourceNote": "Hoving・Robison（2012）Proceedings B",
    },
    "q_lang_003": {
        "difficulty": "easy",
        "question": "外務省のヘボン式ローマ字綴方表で、ひらがなの「し」はどう書く？",
        "choices": ["SHI", "SI", "CHI", "JI"],
        "answerIndex": 0,
        "explanation": (
            "外務省の旅券用ヘボン式ローマ字綴方表では、ひらがなの「し」はSHIと表記されます。"
            "訓令式などで使われるSIとは異なります。"
        ),
        "sourceNote": "外務省「ヘボン式ローマ字綴方表」",
    },
    "q_food_006": {
        "explanation": (
            "「sandwich」という料理名は、第4代サンドイッチ伯爵ジョン・モンタギューの爵位名に由来します。"
            "料理名は個人名ではなく、爵位名の「Sandwich」から広まりました。"
        ),
        "sourceNote": "Oxford English Dictionary「sandwich」",
    },
}

CARD_UPDATES: dict[str, dict[str, Any]] = {
    "card_food_011": {
        "title": "辛さと熱を感じるTRPV1",
        "shortText": "カプサイシンはTRPV1を活性化する。",
        "detailText": (
            "1997年の原著論文は、カプサイシン受容体を熱でも活性化するイオンチャネルとして報告した。"
            "この受容体は現在TRPV1と呼ばれる。"
        ),
        "sourceNote": "Caterinaほか（1997）Nature",
    },
    "card_bio_003": {
        "title": "コウイカの浮力装置",
        "shortText": "体内の甲が浮力を調節する。",
        "detailText": (
            "コウイカの甲（カトルボーン）は多数の小部屋を持つ軽量な内部構造で、"
            "研究論文では高度な浮力装置と説明されている。"
        ),
        "sourceNote": "Checaほか（2015）Scientific Reports",
    },
    "card_living_things_006": {
        "title": "コウモリダコの食事",
        "shortText": "沈降する有機物を集めて食べる。",
        "detailText": (
            "コウモリダコは長い感覚糸で、死んだ生物の破片や糞粒などのデトリタスを集め、"
            "粘液でまとめて食べる。"
        ),
        "sourceNote": "Hoving・Robison（2012）Proceedings B",
    },
    "card_lang_003": {
        "title": "ヘボン式の「し」",
        "shortText": "外務省の表記はSHI。",
        "detailText": (
            "外務省の旅券用ヘボン式ローマ字綴方表では、ひらがなの「し」をSHIと表記する。"
            "SIとする方式とは綴りが異なる。"
        ),
        "sourceNote": "外務省「ヘボン式ローマ字綴方表」",
    },
    "card_food_006": {
        "title": "サンドイッチ伯爵と料理名",
        "shortText": "料理名は第4代伯爵の爵位名に由来。",
        "detailText": (
            "「sandwich」という料理名は、第4代サンドイッチ伯爵ジョン・モンタギューの爵位名に由来する。"
            "カード遊びに関する逸話は、直接資料で確認できないため扱わない。"
        ),
        "sourceNote": "Oxford English Dictionary「sandwich」",
    },
}

REAL_DATA_TEST_CONTENT = r'''import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_review/content_risk_classifier.dart';

void main() {
  const classifier = ContentRiskClassifier();
  late Map<String, ContentRiskRecord> risksByQuestionId;

  setUpAll(() {
    final risks = classifier.risks(
      questionsJson: _projectFile(
        'assets/data/questions.json',
      ).readAsStringSync(),
      cardsJson: _projectFile('assets/data/cards.json').readAsStringSync(),
    );
    risksByQuestionId = {
      for (final risk in risks) risk.questionId: risk,
    };
  });

  List<String> duplicateIds(String questionId) =>
      risksByQuestionId[questionId]?.duplicateQuestionIds ?? const <String>[];

  Set<String> duplicateEdges() {
    final edges = <String>{};
    for (final entry in risksByQuestionId.entries) {
      for (final duplicateId in entry.value.duplicateQuestionIds) {
        final ids = <String>[entry.key, duplicateId]..sort();
        edges.add('${ids.first}|${ids.last}');
      }
    }
    return edges;
  }

  test('known duplicate groups are resolved in project data', () {
    const cleanedIds = <String>[
      'q_bio_003',
      'q_living_things_006',
      'q_living_things_008',
      'q_food_005',
      'q_food_011',
      'q_food_006',
      'q_lang_003',
    ];

    for (final id in cleanedIds) {
      expect(
        duplicateIds(id),
        isEmpty,
        reason: '$id must not remain connected to a duplicate fact',
      );
    }
  });

  test('real project data has no duplicate fact edges after cleanup', () {
    expect(duplicateEdges(), isEmpty);
  });
}

File _projectFile(String relativePath) {
  final startDirectories = <Directory>{
    Directory.current.absolute,
    if (Platform.script.scheme == 'file')
      File.fromUri(Platform.script).parent.absolute,
  };
  final searchedPaths = <String>[];

  for (final startDirectory in startDirectories) {
    var directory = startDirectory;
    while (true) {
      final candidate = File('${directory.path}/$relativePath');
      searchedPaths.add(candidate.path);
      if (candidate.existsSync()) return candidate;

      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
  }

  throw StateError(
    'Unable to locate $relativePath. Searched: ${searchedPaths.join(', ')}',
  );
}
'''

REPORT_SECTION = """

## Known duplicate cleanup — 2026-07-15

| Group | Keep | Replace | Delete / scope reduction |
| --- | --- | --- | --- |
| Strawberry fruit structure | `q_food_005` | `q_food_011` → capsaicin receptor TRPV1 | Original strawberry claim removed from `q_food_011` |
| Octopus hearts | `q_living_things_008` | `q_bio_003` → cuttlebone buoyancy; `q_living_things_006` → vampire squid detritivory | Two duplicate octopus-heart claims removed |
| Sandwich name origin | `q_food_006` | `q_lang_003` → Hepburn `SHI` spelling | Card-playing anecdote removed from maintained question/card copy |

The four replacement claims were checked against directly accessible original research or an official government table. The generated risk CSV must contain no duplicate edge for these groups.
"""


def _load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _by_id(items: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    return {str(item["id"]): item for item in items}


def prepare() -> None:
    questions: list[dict[str, Any]] = _load(QUESTIONS)
    cards: list[dict[str, Any]] = _load(CARDS)
    questions_by_id = _by_id(questions)
    cards_by_id = _by_id(cards)

    for question_id, updates in QUESTION_UPDATES.items():
        question = questions_by_id[question_id]
        question.update(updates)
        question.pop("source", None)
        question["verified"] = False

    for card_id, updates in CARD_UPDATES.items():
        card = cards_by_id[card_id]
        card.update(updates)
        card.pop("source", None)

    _write_json(QUESTIONS, questions)
    _write_json(CARDS, cards)
    REAL_DATA_TEST.write_text(REAL_DATA_TEST_CONTENT, encoding="utf-8")

    report = REPORT.read_text(encoding="utf-8")
    marker = "## Known duplicate cleanup — 2026-07-15"
    if marker not in report:
        REPORT.write_text(report.rstrip() + REPORT_SECTION + "\n", encoding="utf-8")


def approve_csv(csv_path: Path) -> None:
    with csv_path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        fieldnames = reader.fieldnames
        if fieldnames is None:
            raise RuntimeError("review CSV is missing a header")
        rows = list(reader)

    seen: set[str] = set()
    for row in rows:
        question_id = row["questionId"]
        metadata = SOURCE_METADATA.get(question_id)
        if metadata is None:
            continue
        row.update(metadata)
        seen.add(question_id)

    missing = set(SOURCE_METADATA) - seen
    if missing:
        raise RuntimeError(f"review CSV is missing replacement rows: {sorted(missing)}")

    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def update_manifest() -> None:
    questions: list[dict[str, Any]] = _load(QUESTIONS)
    manifest: dict[str, Any] = _load(MANIFEST)
    approved = sum(
        1
        for question in questions
        if question.get("verified") is True
        and isinstance(question.get("source"), dict)
        and question["source"].get("reviewStatus") == "approved"
    )
    manifest["playableQuestionCount"] = approved
    _write_json(MANIFEST, manifest)


def verify_risk(csv_path: Path) -> None:
    target_ids = {
        "q_food_005",
        "q_food_011",
        "q_bio_003",
        "q_living_things_006",
        "q_living_things_008",
        "q_lang_003",
        "q_food_006",
    }
    with csv_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    failures: list[str] = []
    for row in rows:
        question_id = row["questionId"]
        duplicates = {value for value in row["duplicateQuestionIds"].split("|") if value}
        if question_id in target_ids and duplicates:
            failures.append(f"{question_id}: {sorted(duplicates)}")
        if duplicates.intersection(target_ids):
            failures.append(f"{question_id} points to {sorted(duplicates.intersection(target_ids))}")

    if failures:
        raise RuntimeError("known duplicate edges remain: " + "; ".join(failures))

    questions: list[dict[str, Any]] = _load(QUESTIONS)
    by_id = _by_id(questions)
    if "イチゴの表面" in by_id["q_food_011"]["question"]:
        raise RuntimeError("q_food_011 still contains the strawberry duplicate")
    if "タコの心臓" in by_id["q_bio_003"]["question"]:
        raise RuntimeError("q_bio_003 still contains the octopus-heart duplicate")
    if "タコ" in by_id["q_living_things_006"]["question"]:
        raise RuntimeError("q_living_things_006 still contains the octopus-heart duplicate")
    if "サンドイッチ" in by_id["q_lang_003"]["question"]:
        raise RuntimeError("q_lang_003 still contains the sandwich duplicate")

    food_006_text = by_id["q_food_006"]["explanation"]
    if "トランプ" in food_006_text or "カード遊び" in food_006_text:
        raise RuntimeError("q_food_006 still contains the card-playing anecdote")


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("prepare")
    approve = subparsers.add_parser("approve-csv")
    approve.add_argument("path", type=Path)
    subparsers.add_parser("update-manifest")
    verify = subparsers.add_parser("verify-risk")
    verify.add_argument("path", type=Path)
    args = parser.parse_args()

    if args.command == "prepare":
        prepare()
    elif args.command == "approve-csv":
        approve_csv(args.path)
    elif args.command == "update-manifest":
        update_manifest()
    elif args.command == "verify-risk":
        verify_risk(args.path)


if __name__ == "__main__":
    main()
