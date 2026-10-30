"""Encode generated PNG originals as mobile-sized WebP, preserving transparency.

No background removal or visual editing is performed here. Alpha is generated
by imagegen; originals remain under assets/clothing/generated and Codex.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'clothing'
NAMES = ['white-tee', 'striped-top', 'oxford-shirt', 'knit', 'jeans', 'chinos',
         'pleated-skirt', 'dress', 'trench', 'blazer', 'sneakers', 'loafers',
         'tote', 'scarf']

for name in NAMES:
    source = ROOT / 'generated' / f'{name}.png'
    with Image.open(source) as original:
        image = original.convert('RGBA')
        assert image.getchannel('A').getextrema() == (0, 255), f'Missing transparency: {name}'
        image.thumbnail((640, 640), Image.Resampling.LANCZOS)
        target = ROOT / f'{name}.webp'
        image.save(target, 'WEBP', quality=90, method=6)
        with Image.open(target) as saved:
            assert saved.mode == 'RGBA' and saved.getchannel('A').getextrema() == (0, 255)
        print(f'{name}: {image.width}x{image.height}, {target.stat().st_size:,} bytes, alpha verified')
