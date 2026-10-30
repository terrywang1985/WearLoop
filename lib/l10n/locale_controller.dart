import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedAppLocales = [
  Locale('en'),
  Locale('zh'),
  Locale('ja'),
  Locale('ko'),
  Locale('es'),
  Locale('fr'),
  Locale('de'),
  Locale('vi'),
  Locale('hi'),
  Locale('ar'),
  Locale('bn'),
  Locale('pt'),
  Locale('ru'),
  Locale('ur'),
  Locale('id'),
];

const languageNames = <String, String>{
  'zh': '中文',
  'ja': '日本語',
  'ko': '한국어',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'vi': 'Tiếng Việt',
  'hi': 'हिन्दी',
  'ar': 'العربية',
  'bn': 'বাংলা',
  'pt': 'Português',
  'ru': 'Русский',
  'ur': 'اردو',
  'id': 'Bahasa Indonesia',
};

Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final candidate in preferred ?? const <Locale>[]) {
    final code = candidate.languageCode == 'in' ? 'id' : candidate.languageCode;
    for (final locale in supported) {
      if (locale.languageCode == code) return locale;
    }
  }
  return const Locale('en');
}

class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initialLocale}) : _locale = initialLocale;
  static const preferenceKey = 'wl_locale';
  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(preferenceKey);
    if (languageNames.containsKey(code)) _locale = Locale(code!);
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale != null && !languageNames.containsKey(locale.languageCode)) {
      return;
    }
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(preferenceKey);
    } else {
      await prefs.setString(preferenceKey, locale.languageCode);
    }
  }
}

class AppLocaleScope extends InheritedNotifier<LocaleController> {
  const AppLocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);
  static LocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleScope>()?.notifier;
}
