"""Validate local Google Play listing files without modifying or uploading them."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "docs" / "google-play" / "listings"
LIMITS = {"title.txt":30,"short-description.txt":80,"full-description.txt":4000,"release-notes.txt":500}
EXPECTED = {"zh-CN":"zh","ja-JP":"ja","ko-KR":"ko","en-US":"en","es-ES":"es","fr-FR":"fr","de-DE":"de","vi":"vi","hi-IN":"hi","ar":"ar","bn-BD":"bn","pt-BR":"pt","ru-RU":"ru","ur":"ur","id":"id"}

def main():
    errors = []
    manifest = json.loads((DEST / "manifest.json").read_text(encoding="utf-8"))
    listings = manifest["listings"]
    actual = {item["playLocale"]:item["appLanguage"] for item in listings}
    if actual != EXPECTED or len(listings)!=len(EXPECTED):
        errors.append("Locale manifest must cover exactly the 15 supported app languages.")
    for item in listings:
        locale=item["playLocale"]
        if item["directory"] != locale:
            errors.append(f"{locale}: directory must match Play locale")
        for name, limit in LIMITS.items():
            path = DEST / locale / name
            if not path.is_file():
                errors.append(f"Missing {path}")
                continue
            raw=path.read_text(encoding="utf-8")
            value=raw.strip()
            counts={"codePoints":len(value),"utf16Units":len(value.encode("utf-16-le"))//2}
            if not value or max(counts.values())>limit:
                errors.append(f"{locale}/{name}: {counts}, limit {limit}")
            if counts != item["characterCounts"].get(name):
                errors.append(f"{locale}/{name}: manifest counts stale")
            if "\ufeff" in raw or "\ufffd" in raw or "<script" in raw or "TODO" in raw:
                errors.append(f"{locale}/{name}: invalid or placeholder text")
            if name=="full-description.txt" and "CNY" not in value:
                errors.append(f"{locale}/{name}: missing currency disclosure")
        print(f"{locale}: " + ", ".join(f"{name}={item['characterCounts'][name]['utf16Units']}/{limit}" for name,limit in LIMITS.items()))
    if errors:
        print("\n".join(errors),file=sys.stderr)
        return 1
    print(f"PASS: {len(listings)} locale mappings and {len(listings)*len(LIMITS)} listing fields.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
