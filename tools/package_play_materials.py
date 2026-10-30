"""Package localized Play materials only, never application or signing secrets."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "google-play"
DEST = ROOT.parent / "WearLoop-google-play-materials-2026-10-29.zip"
DIRECTORIES = ("listings", "screenshots", "graphics", "contact-sheets", "privacy-site")
DOCUMENTS = ("RELEASE_STATUS.md", "SCREENSHOTS.md", "PRIVACY_POLICY.md", "TECHNICAL_AUDIT.md", "graphics-manifest.json")
ALLOWED = {".png", ".jpg", ".txt", ".json", ".md", ".html"}


def main():
    manifest = json.loads((SOURCE / "graphics-manifest.json").read_text(encoding="utf-8"))
    if (manifest["locales"], manifest["screenshots"], manifest["featureGraphics"]) != (15, 60, 15):
        raise ValueError("A complete fifteen-language graphics set is required.")
    for entry in manifest["files"]:
        item = SOURCE / entry["path"]
        if not item.resolve().is_relative_to(SOURCE.resolve()):
            raise ValueError("Invalid asset path")
        if hashlib.sha256(item.read_bytes()).hexdigest() != entry["sha256"]:
            raise ValueError(f"Asset has changed since validation: {item}")

    files = []
    for folder in DIRECTORIES:
        files.extend(p for p in (SOURCE / folder).rglob("*") if p.is_file() and p.suffix in ALLOWED)
    files.extend(SOURCE / name for name in DOCUMENTS)
    icon = ROOT / "docs" / "store-assets" / "wearloop-icon-512.png"
    with zipfile.ZipFile(DEST, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(set(files)):
            relative = path.relative_to(SOURCE)
            # The unconfigured privacy site is clearly labeled as a draft.
            name = str(relative).replace("\\", "/")
            if name.startswith("privacy-site/"):
                name = name.replace("privacy-site/", "privacy-site-DRAFT-NOT-FOR-PUBLICATION/", 1)
            archive.write(path, name)
        archive.write(icon, "wearloop-icon-512.png")
        archive.writestr("READ-ME-FIRST.txt", (
            "WearLoop Google Play materials — 2026-10-29\n\n"
            "15 languages; 60 real Flutter UI captures; 15 localized feature graphics.\n"
            "The contact sheets are review aids, not store phone screenshots.\n"
            "The policy website is an explicitly unconfigured DRAFT.\n"
            "This archive contains no app binary, model, keystore or password.\n"
            "No WearLoop Console application has been created or submitted.\n"
            "Read RELEASE_STATUS.md for the owner inputs needed before submission.\n"
        ))
    result = {"path": str(DEST), "bytes": DEST.stat().st_size,
              "sha256": hashlib.sha256(DEST.read_bytes()).hexdigest(),
              "locales": 15, "screenshots": 60, "featureGraphics": 15,
              "containsApplicationBinary": False, "submittedToGooglePlay": False}
    (SOURCE / "materials-package.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
