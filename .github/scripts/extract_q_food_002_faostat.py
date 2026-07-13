from __future__ import annotations

import csv
import hashlib
import io
import json
from pathlib import Path
from urllib.request import Request, urlopen
import zipfile

STABLE_HEAD = "a10175d12458ed4cc487fb0c657b90fd0dd9d8b6"
DATA_URL = "https://bulks-faostat.fao.org/production/Production_Crops_Livestock_E_All_Data_%28Normalized%29.zip"
DATASET_URL = "https://bulks-faostat.fao.org/production/datasets_E.json"
RESEARCH_PATH = Path("review/content_research_q_food_002.md")
SCRIPT_PATH = Path(".github/scripts/extract_q_food_002_faostat.py")
WORKFLOW_PATH = Path(".github/workflows/extract-q-food-002-faostat.yml")

request = Request(DATA_URL, headers={"User-Agent": "hee-no-tane-content-audit/1.0"})
with urlopen(request, timeout=180) as response:
    archive_bytes = response.read()

archive_sha256 = hashlib.sha256(archive_bytes).hexdigest()
archive = zipfile.ZipFile(io.BytesIO(archive_bytes))
names = archive.namelist()
csv_names = [name for name in names if name.lower().endswith(".csv")]
main_candidates = [
    name for name in csv_names
    if "all_data" in name.lower() and "normalized" in name.lower() and "flag" not in name.lower()
]
if len(main_candidates) != 1:
    raise RuntimeError(f"expected one normalized main CSV, found {main_candidates!r}; all names={names!r}")
main_name = main_candidates[0]

flag_candidates = [name for name in csv_names if "flag" in name.lower()]
flag_map: dict[str, str] = {}
flag_file_name = ""
for candidate in flag_candidates:
    with archive.open(candidate) as raw:
        reader = csv.DictReader(io.TextIOWrapper(raw, encoding="utf-8-sig", newline=""))
        fields = reader.fieldnames or []
        flag_field = next((field for field in fields if field.strip().lower() == "flag"), None)
        description_field = next(
            (field for field in fields if "description" in field.strip().lower()),
            None,
        )
        if flag_field and description_field:
            for row in reader:
                flag = (row.get(flag_field) or "").strip()
                description = (row.get(description_field) or "").strip()
                if flag:
                    flag_map[flag] = description
            flag_file_name = candidate
            break

rows_by_year: dict[int, list[dict[str, str]]] = {}
with archive.open(main_name) as raw:
    reader = csv.DictReader(io.TextIOWrapper(raw, encoding="utf-8-sig", newline=""))
    fieldnames = reader.fieldnames or []
    required = {"Area", "Item", "Element", "Year", "Unit", "Value", "Flag"}
    missing = required.difference(fieldnames)
    if missing:
        raise RuntimeError(f"missing required columns {sorted(missing)}; fields={fieldnames!r}")
    for row in reader:
        if row.get("Item") != "Apples" or row.get("Element") != "Production quantity":
            continue
        year = int(row["Year"])
        rows_by_year.setdefault(year, []).append(row)

if not rows_by_year:
    raise RuntimeError("no Apples / Production quantity rows found")

def by_area(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    return {row["Area"]: row for row in rows}

selected_year = None
selected_rows: list[dict[str, str]] = []
for year in sorted(rows_by_year, reverse=True):
    area_rows = by_area(rows_by_year[year])
    if "World" in area_rows and "China" in area_rows:
        selected_year = year
        selected_rows = rows_by_year[year]
        break
if selected_year is None:
    raise RuntimeError("no common year containing both World and China")

area_rows = by_area(selected_rows)
required_areas = ["World", "China", "China, mainland"]
missing_areas = [area for area in required_areas if area not in area_rows]
if missing_areas:
    raise RuntimeError(f"missing expected areas for {selected_year}: {missing_areas!r}")

world_value = float(area_rows["World"]["Value"])
china_value = float(area_rows["China"]["Value"])
mainland_value = float(area_rows["China, mainland"]["Value"])
china_share = china_value / world_value * 100
mainland_share = mainland_value / world_value * 100

def compact(row: dict[str, str]) -> dict[str, str]:
    preferred = [
        "Area Code (M49)", "Area Code", "Area", "Item Code (CPC)", "Item Code",
        "Item", "Element Code", "Element", "Year Code", "Year", "Unit", "Value",
        "Flag", "Note",
    ]
    return {key: row.get(key, "") for key in preferred if key in row}

exact_rows = [compact(area_rows[area]) for area in required_areas]
flags_used = sorted({row.get("Flag", "") for row in exact_rows if row.get("Flag", "")})
flag_descriptions = {flag: flag_map.get(flag, "") for flag in flags_used}

top_rows = sorted(
    selected_rows,
    key=lambda row: float(row["Value"] or 0),
    reverse=True,
)[:20]

def markdown_table(rows: list[dict[str, str]]) -> str:
    columns = ["Area", "Year", "Unit", "Value", "Flag", "Flag Description", "Note"]
    lines = ["| " + " | ".join(columns) + " |", "|" + "|".join(["---"] * len(columns)) + "|"]
    for row in rows:
        values = [
            row.get("Area", ""), row.get("Year", ""), row.get("Unit", ""),
            row.get("Value", ""), row.get("Flag", ""),
            flag_map.get(row.get("Flag", ""), ""), row.get("Note", ""),
        ]
        values = [value.replace("|", "\\|").replace("\n", " ") for value in values]
        lines.append("| " + " | ".join(values) + " |")
    return "\n".join(lines)

appendix = f"""

## 公式FAOSTATバルク原表の直接抽出（2026-07-13）

GitHub Actions上でFAOSTAT公式正規化バルクZIPを直接取得し、CSVを全行走査した。JSON本文はまだ変更していない。

- Dataset metadata: {DATASET_URL}
- Official ZIP: {DATA_URL}
- ZIP SHA-256: `{archive_sha256}`
- Main CSV: `{main_name}`
- Flag CSV: `{flag_file_name or '見つからず'}`
- Main CSV columns: `{json.dumps(fieldnames, ensure_ascii=False)}`
- ZIP内CSV: `{json.dumps(csv_names, ensure_ascii=False)}`

### 最新の共通年

`Apples` / `Production quantity`について、`World`と`China`の両方が存在する最新の共通年は **{selected_year}年** だった。

### 対象行

{markdown_table([area_rows[area] for area in required_areas])}

計算:

- `China / World × 100 = {china_share:.9f}%`
- `China, mainland / World × 100 = {mainland_share:.9f}%`

使用Flagの公式説明抽出: `{json.dumps(flag_descriptions, ensure_ascii=False)}`

### 値の大きい上位20行（地域集計を含む未分類一覧）

{markdown_table(top_rows)}

### この抽出だけでは確定しない事項

- 上位20行には世界・地域集計が含まれ得るため、国・地域だけの正式順位は別途Area分類を確認する必要がある。
- `China`と`China, mainland`は別Areaであり、問題本文で採用する集計範囲を明記する必要がある。
- 日本で食べられる、流通する、輸入されるリンゴの中国産割合は、この生産統計からは導けない。
"""

original = RESEARCH_PATH.read_text(encoding="utf-8")
marker = "## 公式FAOSTATバルク原表の直接抽出（2026-07-13）"
if marker in original:
    raise RuntimeError("official extraction appendix already exists")
RESEARCH_PATH.write_text(original.rstrip() + appendix + "\n", encoding="utf-8")

SCRIPT_PATH.unlink()
WORKFLOW_PATH.unlink()

print(json.dumps({
    "selected_year": selected_year,
    "world": compact(area_rows["World"]),
    "china": compact(area_rows["China"]),
    "china_mainland": compact(area_rows["China, mainland"]),
    "china_share": china_share,
    "flag_descriptions": flag_descriptions,
    "zip_sha256": archive_sha256,
}, ensure_ascii=False, indent=2))
print(f"prepared official FAOSTAT evidence from stable head {STABLE_HEAD}")
