"""Maintain Android language declarations and bundled iOS permission strings.

Run from the repository root or any directory. Does not change permissions,
signing settings, or app data. iOS still requires a macOS/Xcode build to validate
native compilation and permission dialogs on a device.
"""
from hashlib import sha1
from pathlib import Path
import json
import plistlib
import re

ROOT = Path(__file__).resolve().parents[1]
PERMISSIONS = {
    'en': (
        'Take photos of your clothes to add them to your WearLoop wardrobe.',
        'Choose clothing photos to add to your WearLoop wardrobe.',
    ),
    'zh-Hans': ('拍摄衣物照片，添加到你的 WearLoop 衣橱。', '选择衣物照片，添加到你的 WearLoop 衣橱。'),
    'ja': ('服の写真を撮影して、WearLoopのワードローブに追加します。', '服の写真を選択して、WearLoopのワードローブに追加します。'),
    'ko': ('옷을 촬영하여 WearLoop 옷장에 추가합니다.', '사진 보관함에서 옷 사진을 선택하여 WearLoop 옷장에 추가합니다.'),
    'es': ('Fotografía tus prendas para añadirlas a tu armario de WearLoop.', 'Selecciona fotos de prendas para añadirlas a tu armario de WearLoop.'),
    'fr': ('Prenez vos vêtements en photo pour les ajouter à votre garde-robe WearLoop.', 'Choisissez des photos de vêtements à ajouter à votre garde-robe WearLoop.'),
    'de': ('Fotografiere deine Kleidung, um sie zu deinem WearLoop-Kleiderschrank hinzuzufügen.', 'Wähle Kleidungsfotos aus, um sie zu deinem WearLoop-Kleiderschrank hinzuzufügen.'),
    'vi': ('Chụp ảnh quần áo để thêm vào tủ đồ WearLoop của bạn.', 'Chọn ảnh quần áo để thêm vào tủ đồ WearLoop của bạn.'),
    'hi': ('अपने कपड़ों की तस्वीरें लेकर उन्हें अपनी WearLoop अलमारी में जोड़ें।', 'अपनी WearLoop अलमारी में जोड़ने के लिए कपड़ों की तस्वीरें चुनें।'),
    'ar': ('التقط صورًا لملابسك لإضافتها إلى خزانتك في WearLoop.', 'اختر صور الملابس لإضافتها إلى خزانتك في WearLoop.'),
    'bn': ('জামাকাপড়ের ছবি তুলে আপনার WearLoop আলমারিতে যোগ করুন।', 'আপনার WearLoop আলমারিতে যোগ করতে পোশাকের ছবি বেছে নিন।'),
    'pt': ('Fotografe suas roupas para adicioná-las ao seu guarda-roupa WearLoop.', 'Escolha fotos de roupas para adicioná-las ao seu guarda-roupa WearLoop.'),
    'ru': ('Сфотографируйте одежду, чтобы добавить её в гардероб WearLoop.', 'Выберите фотографии одежды, чтобы добавить её в гардероб WearLoop.'),
    'ur': ('اپنے کپڑوں کی تصاویر لے کر انہیں WearLoop کی الماری میں شامل کریں۔', 'WearLoop کی الماری میں شامل کرنے کے لیے کپڑوں کی تصاویر چنیں۔'),
    'id': ('Foto pakaian Anda untuk menambahkannya ke lemari WearLoop.', 'Pilih foto pakaian untuk ditambahkan ke lemari WearLoop.'),
}
KEYS = ('NSCameraUsageDescription', 'NSPhotoLibraryUsageDescription')
LOCALES = ['zh' if region == 'zh-Hans' else region for region in PERMISSIONS]


def write(relative, value):
    target = ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(value, encoding='utf-8')


def object_id(name):
    return sha1(('WearLoop.localization.' + name).encode()).hexdigest()[:24].upper()


def openstep_parse(source):
    """Small structural parser for the project's OpenStep dictionaries/arrays."""
    token_pattern = re.compile(r'"(?:\\.|[^"\\])*"|/\*[\s\S]*?\*/|//[^\n]*|[{}()=;,]|[^\s{}()=;,]+')
    tokens = [t for t in token_pattern.findall(source) if not t.startswith(('/*', '//'))]
    position = 0

    def value():
        nonlocal position
        token = tokens[position]
        position += 1
        if token == '{':
            result = {}
            while tokens[position] != '}':
                key = value()
                assert tokens[position] == '='
                position += 1
                result[key] = value()
                assert tokens[position] == ';'
                position += 1
            position += 1
            return result
        if token == '(':
            result = []
            while tokens[position] != ')':
                result.append(value())
                if tokens[position] == ',':
                    position += 1
            position += 1
            return result
        if token.startswith('"'):
            return json.loads(token)
        return token

    result = value()
    assert position == len(tokens), 'Unparsed Xcode project tokens'
    return result


def generate():
    xml = '<?xml version="1.0" encoding="utf-8"?>\n<locale-config xmlns:android="http://schemas.android.com/apk/res/android">\n'
    xml += ''.join(f'    <locale android:name="{locale}" />\n' for locale in LOCALES)
    xml += '</locale-config>\n'
    write('android/app/src/main/res/xml/locales_config.xml', xml)
    manifest_path = ROOT / 'android/app/src/main/AndroidManifest.xml'
    manifest = manifest_path.read_text(encoding='utf-8-sig')
    if 'android:localeConfig=' not in manifest:
        manifest = manifest.replace('<application\n', '<application\n        android:localeConfig="@xml/locales_config"\n', 1)
    if 'android:supportsRtl=' not in manifest:
        manifest = manifest.replace('<application\n', '<application\n        android:supportsRtl="true"\n', 1)
    manifest_path.write_text(manifest, encoding='utf-8')

    for region, translations in PERMISSIONS.items():
        content = '// WearLoop system permission explanations.\n'
        for key, translation in zip(KEYS, translations):
            content += f'{json.dumps(key)} = {json.dumps(translation, ensure_ascii=False)};\n'
        write(f'ios/Runner/{region}.lproj/InfoPlist.strings', content)

    plist_path = ROOT / 'ios/Runner/Info.plist'
    plist = plist_path.read_text(encoding='utf-8-sig')
    for key, fallback in zip(KEYS, PERMISSIONS['en']):
        plist, count = re.subn(r'(<key>' + key + r'</key>\s*<string>).*?(</string>)', lambda match: match[1] + fallback + match[2], plist, count=1, flags=re.S)
        assert count == 1, f'Missing privacy purpose key: {key}'
    locales_array = '\t<key>CFBundleLocalizations</key>\n\t<array>\n'
    locales_array += ''.join(f'\t\t<string>{region}</string>\n' for region in PERMISSIONS)
    locales_array += '\t</array>\n'
    if '<key>CFBundleLocalizations</key>' in plist:
        plist = re.sub(r'\t<key>CFBundleLocalizations</key>\s*<array>.*?</array>\n', locales_array, plist, count=1, flags=re.S)
    else:
        plist = plist.replace('\t<key>CFBundleDisplayName</key>', locales_array + '\t<key>CFBundleDisplayName</key>', 1)
    plist_path.write_text(plist, encoding='utf-8')

    group_id = object_id('InfoPlist.strings.variant')
    build_id = object_id('InfoPlist.strings.build')
    file_ids = {region: object_id('InfoPlist.strings.' + region) for region in PERMISSIONS}
    project_path = ROOT / 'ios/Runner.xcodeproj/project.pbxproj'
    project = project_path.read_text(encoding='utf-8-sig')
    if group_id not in project:
        build_file = f'\t\t{build_id} /* InfoPlist.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {group_id} /* InfoPlist.strings */; }};\n'
        project = project.replace('/* End PBXBuildFile section */', build_file + '/* End PBXBuildFile section */', 1)
        references = ''.join(
            f'\t\t{file_id} /* {region} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.strings; name = "{region}"; path = "{region}.lproj/InfoPlist.strings"; sourceTree = "<group>"; }};\n'
            for region, file_id in file_ids.items()
        )
        project = project.replace('/* End PBXFileReference section */', references + '/* End PBXFileReference section */', 1)
        variant = f'\t\t{group_id} /* InfoPlist.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n'
        variant += ''.join(f'\t\t\t\t{file_id} /* {region} */,\n' for region, file_id in file_ids.items())
        variant += '\t\t\t);\n\t\t\tname = InfoPlist.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
        project = project.replace('/* End PBXVariantGroup section */', variant + '/* End PBXVariantGroup section */', 1)
        project = project.replace('\t\t\t\t97C147021CF9000F007C117D /* Info.plist */,', f'\t\t\t\t{group_id} /* InfoPlist.strings */,\n\t\t\t\t97C147021CF9000F007C117D /* Info.plist */,', 1)
        runner_resources = '\t\t97C146EC1CF9000F007C117D /* Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n'
        assert runner_resources in project
        project = project.replace(runner_resources, runner_resources + f'\t\t\t\t{build_id} /* InfoPlist.strings in Resources */,\n', 1)
    known_regions = '\t\t\tknownRegions = (\n\t\t\t\tBase,\n'
    known_regions += ''.join(f'\t\t\t\t"{region}",\n' for region in PERMISSIONS)
    known_regions += '\t\t\t);'
    project, count = re.subn(r'\t\t\tknownRegions = \(.*?\n\t\t\t\);', known_regions, project, count=1, flags=re.S)
    assert count == 1, 'Missing Xcode knownRegions'
    project_path.write_text(project, encoding='utf-8')
    validate(group_id, build_id, file_ids)


def validate(group_id=None, build_id=None, file_ids=None):
    group_id = group_id or object_id('InfoPlist.strings.variant')
    build_id = build_id or object_id('InfoPlist.strings.build')
    file_ids = file_ids or {region: object_id('InfoPlist.strings.' + region) for region in PERMISSIONS}
    with (ROOT / 'ios/Runner/Info.plist').open('rb') as file:
        plist = plistlib.load(file)
    assert plist['CFBundleLocalizations'] == list(PERMISSIONS)
    assert all(plist[key] == fallback for key, fallback in zip(KEYS, PERMISSIONS['en']))
    project = openstep_parse((ROOT / 'ios/Runner.xcodeproj/project.pbxproj').read_text(encoding='utf-8'))
    objects = project['objects']
    assert objects[group_id]['isa'] == 'PBXVariantGroup'
    assert objects[group_id]['children'] == list(file_ids.values())
    assert objects[build_id]['fileRef'] == group_id
    assert build_id in objects['97C146EC1CF9000F007C117D']['files']
    assert group_id in objects['97C146F01CF9000F007C117D']['children']
    regions = objects['97C146E61CF9000F007C117D']['knownRegions']
    assert all(region in regions for region in PERMISSIONS)
    for region, file_id in file_ids.items():
        resource = ROOT / 'ios/Runner' / objects[file_id]['path']
        assert resource.exists(), resource
        content = resource.read_text(encoding='utf-8')
        pairs = re.findall(r'"(NS\w+Description)"\s*=\s*("(?:\\.|[^"\\])*");', content)
        assert {key for key, value in pairs} == set(KEYS), region
        assert tuple(json.loads(value) for key, value in pairs) == PERMISSIONS[region], region
    def check_ids(value):
        if isinstance(value, dict):
            for child in value.values(): check_ids(child)
        elif isinstance(value, list):
            for child in value: check_ids(child)
        elif re.fullmatch(r'[A-F0-9]{24}', value):
            assert value in objects, f'Unresolved PBX object: {value}'
    check_ids(project)
    import xml.etree.ElementTree as ET
    android = ET.parse(ROOT / 'android/app/src/main/res/xml/locales_config.xml').getroot()
    assert [child.attrib['{http://schemas.android.com/apk/res/android}name'] for child in android] == LOCALES
    manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml').getroot()
    assert manifest.find('application').attrib['{http://schemas.android.com/apk/res/android}localeConfig'] == '@xml/locales_config'
    print(f'Android: {len(LOCALES)} locales. iOS: {len(file_ids)} localized resources attached to Runner Resources, every PBX reference resolved.')


if __name__ == '__main__':
    generate()
