"""Make an explicit, secret-scanned source-only release copy for public Git."""
from pathlib import Path
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT.parent / 'public-release' / 'WearLoop'
DIRS = ['lib', 'assets', 'test', 'android', 'ios', 'web', 'third_party', 'tools']
FILES = ['README.md', 'DESIGN.md', 'LICENSE', 'NOTICE', 'THIRD_PARTY_NOTICES.md', 'MODEL_PROVENANCE.json', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', '.gitignore', '.metadata']
EXCLUDE = {'.git', '.gradle', '.kotlin', '.dart_tool', '.cxx', 'build', '__pycache__', 'Pods', '.symlinks', 'ephemeral', 'model_build', 'captures'}
BAD_NAMES = {'local.properties', 'key.properties', '.env', 'Generated.xcconfig', 'flutter_export_environment.sh'}
BAD_SUFFIXES = {'.jks', '.keystore', '.log', '.apk', '.aab', '.db', '.sqlite', '.pyc', '.p12', '.mobileprovision'}
SECRET = re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[A-Z0-9]{16}')

def main():
    selected = [ROOT / n for n in FILES if (ROOT/n).is_file()]
    for folder in DIRS:
        for p in (ROOT/folder).rglob('*'):
            rel=p.relative_to(ROOT)
            if not p.is_file() or p.is_symlink() or any(x in EXCLUDE for x in rel.parts): continue
            if p.name in BAD_NAMES or p.suffix.lower() in BAD_SUFFIXES or p.name.startswith('.env'): continue
            selected.append(p)
    records=[]
    for p in selected:
        raw=p.read_bytes()
        if p.suffix in {'.dart','.py','.ps1','.yaml','.yml','.json','.md','.txt','.kts','.properties','.xml','.plist','.xcconfig','.pbxproj'}:
            if SECRET.search(raw.decode('utf-8',errors='replace')):
                # This script contains detection patterns, not secret values.
                if p.resolve()!=Path(__file__).resolve(): raise ValueError(f'Potential credential: {p.relative_to(ROOT)}')
        target=DEST/p.relative_to(ROOT)
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(p,target)
        records.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)})
    (DEST/'SOURCE_MANIFEST.json').write_text(json.dumps({'license':'AGPL-3.0-only','files':records},indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'directory':str(DEST),'files':len(records),'bytes':sum(r['bytes'] for r in records),'credentialScan':'passed','excluded':'build outputs, signing credentials, local configuration, private databases, logs and unrelated model experiments'}))

if __name__=='__main__': main()
