"""Synchronize the existing detector-label catalog entries with ONNX metadata.

Keeps the catalog key set size stable by replacing three obsolete labels, and
corrects the existing rivet translation. It does not alter any model behavior.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LABELS = {
    # ribbon, rivet, ruffle, sequin, tassel (ONNX class IDs 41..45)
    "zh": ["饰带", "铆钉", "荷叶边", "亮片", "穗饰"],
    "en": ["Ribbon", "Rivet", "Ruffle", "Sequin", "Tassel"],
    "ja": ["リボン", "リベット", "フリル", "スパンコール", "タッセル"],
    "ko": ["리본", "리벳", "러플", "스팽글", "태슬"],
    "es": ["Cinta", "Remache", "Volante", "Lentejuela", "Borla"],
    "fr": ["Ruban", "Rivet", "Volant", "Sequin", "Gland de passementerie"],
    "de": ["Zierband", "Niete", "Rüsche", "Paillette", "Quaste"],
    "vi": ["Dải ruy băng", "Đinh tán", "Diềm bèo", "Kim sa", "Tua trang trí"],
    "hi": ["रिबन", "रिवेट", "फ्रिल", "सिक्विन", "फुंदना"],
    "ar": ["شريط زينة", "برشام", "كشكش", "ترتر", "شرّابة"],
    "bn": ["ফিতা", "রিভেট", "ফ্রিল", "চুমকি", "ঝুলন্ত ঝালর"],
    "pt": ["Fita", "Rebite", "Babado", "Lantejoula", "Borla"],
    "ru": ["Лента", "Заклёпка", "Оборка", "Пайетка", "Кисточка"],
    "ur": ["ربن", "ریویٹ", "جھالر دار کنارہ", "چمکی", "لٹکن"],
    "id": ["Pita", "Paku keling", "Rimpel", "Payet", "Rumbai gantung"],
}
REPLACED = {"褶裥": "饰带", "开衩": "亮片", "装饰片": "穗饰"}
KEYS = LABELS["zh"]


def update(path, values):
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    for old, new in REPLACED.items():
        data.pop(old, None)
    data.update(zip(KEYS, values))
    path.write_text(json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    for locale, values in LABELS.items():
        update(ROOT / f"assets/l10n/{locale}.json", values)
    update(ROOT / "lib/l10n/catalog-secondary.json", LABELS["en"])
    # This file is an index of the current English catalog, not a translation source.
    english = json.loads((ROOT / "assets/l10n/en.json").read_text(encoding="utf-8-sig"))
    index = [{"id": index, "source": key, "en": value} for index, (key, value) in enumerate(english.items())]
    (ROOT / "lib/l10n/messages-index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Updated 5 detector labels in {len(LABELS)} locales; other messages preserved.")
