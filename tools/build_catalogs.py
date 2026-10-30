import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
merged = {}
for name in ('catalog-core.json', 'catalog-secondary.json', 'catalog-root.json'):
    path = root / 'lib/l10n' / name
    merged.update(json.loads(path.read_text(encoding='utf-8-sig')))
merged = dict(sorted(merged.items()))
output = root / 'assets/l10n'
output.mkdir(parents=True, exist_ok=True)
(output/'en.json').write_text(json.dumps(merged, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
zh={key:key for key in merged}
zh.update(json.loads((root/'lib/l10n/catalog-zh-overrides.json').read_text(encoding='utf-8-sig')))
(output/'zh.json').write_text(json.dumps(zh, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
indexed = [{'id':i,'source':key,'en':value} for i,(key,value) in enumerate(merged.items())]
(root/'lib/l10n/messages-index.json').write_text(json.dumps(indexed, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(f'{len(merged)} messages merged')
