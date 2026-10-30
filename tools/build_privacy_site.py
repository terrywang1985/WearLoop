"""Render the same 15 localized policy assets as static, non-editable HTML.

This script never deploys. A production render requires a real public contact.
"""
from pathlib import Path
import argparse
import html
import json
import re
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {
    "en":"English", "zh":"中文", "ja":"日本語", "ko":"한국어",
    "es":"Español", "fr":"Français", "de":"Deutsch", "vi":"Tiếng Việt",
    "hi":"हिन्दी", "ar":"العربية", "bn":"বাংলা", "pt":"Português",
    "ru":"Русский", "ur":"اردو", "id":"Bahasa Indonesia",
}
SECTION_IDS = ["local_data","photos","recognition","sharing","developer","backup","deletion","contact","online_policy"]
LABELS = ["title","back","updated","summary","contactLabel","contactPending","onlineLabel","loading","error","retry"]

STYLE = """
:root { color-scheme:light dark; --bg:#f7f8f2; --surface:#fff; --ink:#263c30; --muted:#506251; --line:#d4ddcf; --accent:#496650; }
* { box-sizing:border-box; }
body { margin:0; background:var(--bg); color:var(--ink); font:17px/1.8 system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif; }
main { max-width:860px; margin:auto; padding:32px 24px 72px; overflow-wrap:anywhere; }
header { padding:24px 0; border-bottom:1px solid var(--line); }
.brand { margin:0; color:var(--accent); font-size:1.2rem; font-weight:750; letter-spacing:.02em; }
h1 { font-size:clamp(1.7rem,5vw,2.6rem); line-height:1.35; margin:16px 0 10px; }
h2 { font-size:1.15rem; line-height:1.5; margin:30px 0 8px; }
p { margin:0 0 18px; }
.date { color:var(--muted); font-size:.9rem; }
nav { display:flex; flex-wrap:wrap; gap:7px; margin:24px 0; }
nav a { padding:4px 11px; border:1px solid var(--line); border-radius:14px; text-decoration:none; font-size:.85rem; }
a { color:var(--accent); text-underline-offset:3px; }
nav a[aria-current=page] { background:var(--accent); color:var(--surface); }
.summary { font-size:1.1rem; }
.contact { border-top:1px solid var(--line); margin-top:32px; padding-top:10px; }
@media (prefers-color-scheme:dark) { :root { --bg:#101b14; --surface:#15231a; --ink:#e7eddf; --muted:#b7c7b3; --line:#3b5040; --accent:#bbd3b4; } nav a[aria-current=page] { color:#17271c; } }
@media (max-width:400px) { main {padding-inline:18px;} body{font-size:16px;} }
"""

def validate_assets():
    output = {}
    for language in LANGUAGES:
        path = ROOT / "assets" / "privacy" / f"{language}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("appName")!="WearLoop" or data.get("languageCode")!=language or data.get("updatedDate")!="2026-10-29":
            raise ValueError(f"Invalid identity/version: {path}")
        if any(not isinstance(data.get(key),str) or not data[key].strip() for key in LABELS):
            raise ValueError(f"Missing localized policy label: {path}")
        sections=data.get("sections",[])
        if [s.get("id") for s in sections]!=SECTION_IDS:
            raise ValueError(f"Incomplete policy sections: {path}")
        if any(not s.get("title") or not s.get("body") for s in sections):
            raise ValueError(f"Empty policy section: {path}")
        serialized=json.dumps(data,ensure_ascii=False)
        if "\ufffd" in serialized or "TODO" in serialized:
            raise ValueError(f"Invalid or placeholder content: {path}")
        output[language]=data
    return output

def valid_contact(value):
    if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+",value):
        return False
    domain=value.rsplit("@",1)[1].lower()
    return domain not in {"example.com","example.org","example.net"} and not domain.endswith((".invalid",".test",".example"))

def page(language,data,email,public_url,draft):
    esc=html.escape
    direction="rtl" if language in {"ar","ur"} else "ltr"
    nav="\n".join(f'<a href="{code}.html" lang="{code}" dir="auto"'+(' aria-current="page"' if code==language else '')+f'>{esc(label)}</a>' for code,label in LANGUAGES.items())
    sections="\n".join(f'<section id="{esc(section["id"])}"><h2>{esc(section["title"])}</h2><p>{esc(section["body"])}</p></section>' for section in data["sections"])
    contact=(f'<a href="mailto:{esc(email,quote=True)}" dir="ltr">{esc(email)}</a>' if email else esc(data["contactPending"]))
    canonical=(f'<link rel="canonical" href="{esc(public_url.rstrip("/")+"/"+language+".html",quote=True)}">' if public_url else '')
    robots='<meta name="robots" content="noindex,nofollow">' if draft else ''
    return f'''<!doctype html>
<html lang="{language}" dir="{direction}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
<meta name="description" content="{esc(data['summary'],quote=True)}">
{robots}{canonical}
<title>WearLoop — {esc(data['title'])}</title>
<style>{STYLE}</style>
</head>
<body><main>
<header><p class="brand" dir="ltr">WearLoop</p><h1>{esc(data['title'])}</h1><p class="date">{esc(data['updated'])}</p></header>
<nav aria-label="Languages">{nav}</nav>
<p class="summary">{esc(data['summary'])}</p>
{sections}
<section class="contact"><h2>{esc(data['contactLabel'])}</h2><p>{contact}</p></section>
</main></body></html>
'''

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--support-email",default="")
    parser.add_argument("--privacy-url",default="",help="HTTPS base URL, once the deployment address is known")
    parser.add_argument("--allow-draft",action="store_true",help="Render noindex review pages without a configured contact")
    parser.add_argument("--validate-only",action="store_true")
    parser.add_argument("--output",type=Path,default=ROOT/"docs"/"google-play"/"privacy-site")
    args=parser.parse_args()
    assets=validate_assets()
    if args.validate_only:
        print(f"PASS: {len(assets)} policies, 9 complete sections and 10 localized labels each")
        return
    email=args.support_email.strip()
    if not valid_contact(email) and not args.allow_draft:
        parser.error("A real public --support-email is required. Use --allow-draft only for local review.")
    if email and not valid_contact(email):
        parser.error("Invalid or placeholder contact email")
    if args.privacy_url:
        uri=urlsplit(args.privacy_url)
        if uri.scheme!="https" or not uri.netloc or uri.username or uri.password or uri.query or uri.fragment:
            parser.error("--privacy-url must be a public HTTPS base URL without user information, query or fragment")
    dest=args.output.resolve()
    dest.mkdir(parents=True,exist_ok=True)
    for language,data in assets.items():
        (dest/f"{language}.html").write_text(page(language,data,email,args.privacy_url,args.allow_draft),encoding="utf-8")
    (dest/"index.html").write_text(page("en",assets["en"],email,args.privacy_url,args.allow_draft),encoding="utf-8")
    metadata={"appName":"WearLoop","policyDate":"2026-10-29","languages":list(LANGUAGES),"draft":args.allow_draft,"contactConfigured":bool(email),"supportEmail":email or None,"publicBaseUrl":args.privacy_url or None,"containsAnalytics":False,"containsJavaScript":False}
    (dest/"build-info.json").write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"Wrote {len(assets)+1} static policy pages to {dest}; draft={args.allow_draft}")

if __name__=="__main__":
    main()
