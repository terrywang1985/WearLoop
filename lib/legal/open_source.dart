import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const wearLoopCopyright = 'Copyright (C) 2026 WearLoop contributors';
const defaultWearLoopSourceUrl = 'https://github.com/terrywang1985/WearLoop';

class OpenSourceConfiguration {
  const OpenSourceConfiguration({this.sourceUrl = defaultWearLoopSourceUrl});

  static const current = OpenSourceConfiguration(
    sourceUrl: String.fromEnvironment(
      'WEARLOOP_SOURCE_URL',
      defaultValue: defaultWearLoopSourceUrl,
    ),
  );

  final String sourceUrl;

  /// Only display a public HTTPS location, never URL credentials or tokens.
  Uri? get publicSource {
    final uri = Uri.tryParse(sourceUrl.trim());
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.path.isNotEmpty &&
            uri.userInfo.isEmpty &&
            !uri.hasQuery &&
            !uri.hasFragment
        ? uri
        : null;
  }
}

class OpenSourceCopy {
  const OpenSourceCopy._(this.language, this._text);

  static const titles = {
    'en': 'Open source and licenses',
    'zh': '开源与许可证',
    'ja': 'オープンソースとライセンス',
    'ko': '오픈 소스 및 라이선스',
    'es': 'Código abierto y licencias',
    'fr': 'Logiciel libre et licences',
    'de': 'Open Source und Lizenzen',
    'vi': 'Mã nguồn mở và giấy phép',
    'hi': 'ओपन सोर्स और लाइसेंस',
    'ar': 'المصدر المفتوح والتراخيص',
    'bn': 'ওপেন সোর্স ও লাইসেন্স',
    'pt': 'Código aberto e licenças',
    'ru': 'Открытый код и лицензии',
    'ur': 'اوپن سورس اور لائسنس',
    'id': 'Sumber terbuka dan lisensi',
  };

  static const requiredFields = [
    'title',
    'summary',
    'warranty',
    'sourceHeading',
    'copySource',
    'copied',
    'sourceUnavailable',
    'fullLicense',
    'licenseNote',
    'notices',
    'loading',
    'error',
    'retry',
  ];

  static String languageFor(Locale locale) {
    final code = locale.languageCode == 'in' ? 'id' : locale.languageCode;
    return titles.containsKey(code) ? code : 'en';
  }

  static String titleFor(Locale locale) => titles[languageFor(locale)]!;

  static Future<OpenSourceCopy> load(Locale locale) async {
    final language = languageFor(locale);
    final catalog = jsonDecode(
      await rootBundle.loadString('assets/legal/open-source.json'),
    ) as Map<String, dynamic>;
    final raw = catalog[language];
    if (raw is! Map) throw const FormatException('Missing legal language');
    final texts = <String, String>{};
    for (final key in requiredFields) {
      final value = raw[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing legal text: $language/$key');
      }
      texts[key] = value;
    }
    if (texts['title'] != titles[language]) {
      throw const FormatException('Legal title does not match its language');
    }
    return OpenSourceCopy._(language, texts);
  }

  final String language;
  final Map<String, String> _text;

  String text(String key) => _text[key]!;
}
