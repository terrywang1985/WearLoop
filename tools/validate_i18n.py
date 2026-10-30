import ast,json,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
locales=['zh','ja','ko','en','es','fr','de','vi','hi','ar','bn','pt','ru','ur','id']
base=json.loads((root/'assets/l10n/en.json').read_text(encoding='utf-8-sig'))
placeholder=re.compile(r'\{([A-Za-z][A-Za-z0-9_]*)\}')
errors=[]
for code in locales:
 path=root/f'assets/l10n/{code}.json'
 if not path.exists():errors.append(f'{code}: missingcatalog');continue
 data=json.loads(path.read_text(encoding='utf-8-sig'))
 if data.keys()!=base.keys():errors.append(f'{code}: missing={base.keys()-data.keys()} extra={data.keys()-base.keys()}')
 for key,value in data.items():
  forms=value if isinstance(value,dict) else {'other':value}
  if 'other' not in forms:errors.append(f'{code}: pluralother missing: {key}')
  expected=set(placeholder.findall(key))
  for form,message in forms.items():
   if form not in {'zero','one','two','few','many','other'}:errors.append(f'{code}: invalidpluralform {form}')
   if not isinstance(message,str) or not message.strip():errors.append(f'{code}: emptytext {key}');continue
   if set(placeholder.findall(message))!=expected:errors.append(f'{code}/{key}/{form}: placeholders mismatch')
 print(code,len(data),'messages')
pattern=re.compile(r"\.tr\(\s*('(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")",re.S)
used=set()
for path in (root/'lib').rglob('*.dart'):
 if '/l10n/' in path.as_posix():continue
 for match in pattern.finditer(path.read_text(encoding='utf-8-sig')):
  key=ast.literal_eval(match[1]); used.add(key)
  if '$' in key:errors.append(f'{path.name}: Dartinterpolation inmessagekey {key}')
  if key not in base:errors.append(f'{path.name}: uncataloguedkey {key}')
print(len(used),'literal message keys inDart')
if errors:
 print('\n'.join(errors));raise SystemExit(1)
print('All15catalogs complete; keysets, CLDRforms andplaceholders verified.')
