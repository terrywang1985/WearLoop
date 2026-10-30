"""Verify and package real app captures; only removes redundant alpha channels.

Requires Pillow and fontTools. Run after store_screenshots_test.dart.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import unicodedata

from PIL import Image, ImageDraw, ImageFont, ImageStat
from fontTools.ttLib import TTCollection, TTFont

APP = Path(__file__).resolve().parents[1]
ROOT = APP / 'docs/google-play'
SHOTS = ROOT / 'screenshots'
metadata = json.loads((SHOTS / 'capture-metadata.json').read_text('utf-8'))
locales = metadata['locales']
pages = metadata['pages']
rendered = json.loads((SHOTS / 'rendered-text.json').read_text('utf-8'))
assert set(rendered) == set(locales.values()), 'Run a complete 15-locale capture first'

sdk = Path(os.environ.get('WEARLOOP_FLUTTER_SDK', Path.home() / '.codex/runtimes/flutter-3.47.8'))
windows_fonts = Path(os.environ.get('WEARLOOP_SYSTEM_FONTS', Path(os.environ.get('WINDIR', 'C:/Windows')) / 'Fonts'))
engine_fonts = sdk / 'engine/src/flutter/txt/third_party/fonts'
font_paths = [
    engine_fonts / 'Roboto-Regular.ttf',
    engine_fonts / 'NotoNaskhArabic-Regular.ttf',
    windows_fonts / 'Nirmala.ttf',
    windows_fonts / 'Noto Sans SC (TrueType).otf',
    windows_fonts / 'malgun.ttf',
    windows_fonts / 'georgia.ttf',
]
coverage = set()
for path in font_paths:
    if path.suffix.lower() == '.ttc':
        collection = TTCollection(str(path), lazy=True)
        fonts = collection.fonts
    else:
        collection = None
        fonts = [TTFont(str(path), lazy=True)]
    for font in fonts:
        coverage.update(font.getBestCmap() or {})
        if collection is None:
            font.close()
    if collection:
        collection.close()

font_report = {}
files = []
for code, locale in locales.items():
    all_text = '\n'.join(t for texts in rendered[locale].values() for t in texts)
    missing = sorted({ord(c) for c in all_text
                      if unicodedata.category(c) not in {'Cc', 'Cf', 'Co', 'Zs', 'Zl', 'Zp'}
                      and ord(c) not in coverage})
    assert not missing, f'{locale}: missing text glyphs: {[hex(c) for c in missing]}'
    font_report[locale] = {'missingCodepoints': [], 'uniqueCodepoints': len(set(all_text))}
    targets = [(SHOTS / locale / f'{page}.png', (1080, 1920), 'phone-screenshot') for page in pages]
    targets.append((ROOT / 'graphics' / locale / 'feature-graphic.png', (1024, 500), 'feature-graphic'))
    for path, dimensions, kind in targets:
        with Image.open(path) as image:
            assert image.format == 'PNG', path
            assert image.size == dimensions, (path, image.size)
            if 'A' in image.getbands():
                assert image.getchannel('A').getextrema() == (255, 255), f'Transparent pixels: {path}'
            rgb = image.convert('RGB')
            assert sum(ImageStat.Stat(rgb.resize((100, 100))).var) > 20, f'Empty capture: {path}'
            # Pixel colors are preserved, only the unnecessary alpha channel is removed.
            rgb.save(path, 'PNG', optimize=True)
        raw = path.read_bytes()
        assert raw[24] == 8 and raw[25] == 2, f'Expected 24-bit RGB PNG, no alpha: {path}'
        assert len(raw) < 8 * 1024 * 1024, f'Image exceeds 8 MiB: {path}'
        files.append({'locale': locale, 'language': code, 'kind': kind,
                      'path': path.relative_to(ROOT).as_posix(),
                      'width': dimensions[0], 'height': dimensions[1],
                      'pngColorType': 2, 'color': 'RGB 24-bit, no alpha',
                      'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})

assert len(files) == 75
assert len({row['sha256'] for row in files}) == 75, 'Accidental duplicate locale/page image'
sheets = ROOT / 'contact-sheets'
sheets.mkdir(exist_ok=True)
label_font = ImageFont.truetype(str(engine_fonts / 'Roboto-Regular.ttf'), 19)
small_font = ImageFont.truetype(str(engine_fonts / 'Roboto-Regular.ttf'), 16)

for locale in locales.values():
    sheet = Image.new('RGB', (1080, 532), '#e8eddf')
    draw = ImageDraw.Draw(sheet)
    draw.text((16, 9), f'WearLoop - {locale} - 1080 x 1920 phone screenshots', fill='#263c30', font=label_font)
    for i, page in enumerate(pages):
        with Image.open(SHOTS / locale / f'{page}.png') as image:
            thumbnail = image.resize((270, 480), Image.Resampling.LANCZOS)
        sheet.paste(thumbnail, (i * 270, 40))
    sheet.save(sheets / f'{locale}.jpg', quality=91)

overview = Image.new('RGB', (1350, 1524), '#e8eddf')
overview_draw = ImageDraw.Draw(overview)
for i, locale in enumerate(locales.values()):
    x, y = i % 5 * 270, i // 5 * 508
    overview_draw.text((x + 10, y + 5), locale, fill='#263c30', font=label_font)
    with Image.open(SHOTS / locale / '01-today.png') as image:
        overview.paste(image.resize((270, 480), Image.Resampling.LANCZOS), (x, y + 28))
overview.save(sheets / 'all-locales-today.jpg', quality=93)

feature_sheet = Image.new('RGB', (1536, 1390), '#e8eddf')
feature_draw = ImageDraw.Draw(feature_sheet)
for i, locale in enumerate(locales.values()):
    x, y = i % 3 * 512, i // 3 * 278
    feature_draw.text((x + 10, y + 4), locale, fill='#263c30', font=small_font)
    with Image.open(ROOT / 'graphics' / locale / 'feature-graphic.png') as image:
        feature_sheet.paste(image.resize((512, 250), Image.Resampling.LANCZOS), (x, y + 28))
feature_sheet.save(sheets / 'all-locales-feature-graphics.jpg', quality=93)

report = {'screenshots': 60, 'featureGraphics': 15, 'locales': 15,
          'captureDate': metadata['captureDate'], 'files': files,
          'textGlyphCoverage': font_report,
          'verification': 'Dimensions, PNG RGB/no alpha, size, pixel variance, unique images, loaded font Unicode coverage; capture tests assert no Flutter exceptions or Ahem/default font spans.'}
(ROOT / 'graphics-manifest.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', 'utf-8')
print(f'PASS: {len(locales)} locales, 60 screenshots + 15 feature graphics, 24-bit RGB PNG; zero missing text glyphs.')

