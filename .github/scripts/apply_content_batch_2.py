#!/usr/bin/env python3
import base64
import json
import re
import subprocess
import zlib
from pathlib import Path

parts = [
    Path(f'.github/scripts/content_batch_2.payload.{index}').read_text(encoding='utf-8')
    for index in range(1, 5)
]
payload = json.loads(zlib.decompress(base64.b64decode(''.join(parts))))


def patch_json(path, updates):
    target = Path(path)
    items = json.loads(target.read_text(encoding='utf-8'))
    seen = set()
    for index, item in enumerate(items):
        item_id = item.get('id')
        if item_id in updates:
            items[index] = updates[item_id]
            seen.add(item_id)
    missing = set(updates) - seen
    if missing:
        raise SystemExit(f'missing IDs in {path}: {sorted(missing)}')
    target.write_text(
        json.dumps(items, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )


patch_json('assets/data/questions.json', payload['q_updates'])
patch_json('assets/data/cards.json', payload['c_updates'])

for path, content in payload['docs'].items():
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding='utf-8')

Path('review/content_triage_batch_2.csv').write_text(
    payload['triage_csv'], encoding='utf-8'
)
Path('review/content_corrections_batch_2.csv').write_text(
    payload['corrections_csv'], encoding='utf-8'
)
Path('docs/19_コンテンツ修正バッチ2.md').write_text(
    payload['summary'], encoding='utf-8'
)

workflow = Path('.github/workflows/flutter-ci.yml')
workflow_text = workflow.read_text(encoding='utf-8')
workflow_text = re.sub(
    r'\n# BEGIN CONTENT BATCH 2 PERMISSIONS.*?# END CONTENT BATCH 2 PERMISSIONS\n',
    '\n',
    workflow_text,
    flags=re.S,
)
workflow_text = re.sub(
    r'\n  # BEGIN CONTENT BATCH 2 JOB.*?  # END CONTENT BATCH 2 JOB\n',
    '\n',
    workflow_text,
    flags=re.S,
)
workflow.write_text(workflow_text, encoding='utf-8')

Path('.github/scripts/apply_content_batch_2.py').unlink()
for index in range(1, 5):
    Path(f'.github/scripts/content_batch_2.payload.{index}').unlink()

subprocess.run(['git', 'config', 'user.name', 'github-actions[bot]'], check=True)
subprocess.run(
    [
        'git',
        'config',
        'user.email',
        '41898282+github-actions[bot]@users.noreply.github.com',
    ],
    check=True,
)
subprocess.run(['git', 'add', '-A'], check=True)
subprocess.run(
    ['git', 'commit', '-m', 'Correct six high-risk content pairs'],
    check=True,
)
subprocess.run(['git', 'push', 'origin', 'HEAD'], check=True)
