from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
index=json.loads((root/'lib/l10n/messages-index.json').read_text(encoding='utf-8-sig'))
for lang in ['id','ar','ur']:
    source=root/'tools/translations'/f'{lang}.tsv'
    if not source.exists(): continue
    rows={int(line.split('\t',1)[0]):line.split('\t',1)[1].replace('\\n','\n') for line in source.read_text(encoding='utf-8-sig').splitlines() if line.strip()}
    assert set(rows)==set(range(len(index))), (lang,'Missing ids',set(range(len(index)))-set(rows))
    result={x['source']: ({'other':rows[x['id']]} if lang=='id' and isinstance(x['en'],dict) else rows[x['id']]) for x in index}
    overrides=root/'tools/translations'/f'{lang}-plurals.json'
    if overrides.exists():
        for id,value in json.loads(overrides.read_text(encoding='utf-8-sig')).items(): result[index[int(id)]['source']]=value
    for x in index:
        wanted=set(re.findall(r'\{\w+\}',x['source']))
        translated=result[x['source']]
        forms=translated.values() if isinstance(translated,dict) else [translated]
        for value in forms:
            assert set(re.findall(r'\{\w+\}',value))==wanted, (lang,x['id'],wanted,value)
        assert not any('\u4e00'<=c<='\u9fff' for value in forms for c in value),(lang,x['id'],'Chinese remains')
    target=root/'assets/l10n'/f'{lang}.json'
    target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(lang,len(result),'keys and placeholders verified')
