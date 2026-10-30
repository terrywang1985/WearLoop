import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../demo_assets.dart';
import '../models.dart';
import '../store.dart';
import 'locale_controller.dart';

/// Message catalogs use the original copy as stable keys. Values are strings
/// or CLDR plural maps (zero/one/two/few/many/other), selected before insertion.
class AppLocalizations {
  const AppLocalizations(
    this.locale,
    this.messages, [
    this.fallback = const {},
  ]);
  final Locale locale;
  final Map<String, dynamic> messages;
  final Map<String, dynamic> fallback;
  static const delegate = _AppLocalizationsDelegate();
  static final _cache = <String, Map<String, dynamic>>{};

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('zh'), {});

  static Future<AppLocalizations> load(Locale locale) async {
    await initializeDateFormatting();
    Future<Map<String, dynamic>> read(String code) async {
      if (_cache[code] case final cached?) return cached;
      final map = Map<String, dynamic>.from(
        jsonDecode(await rootBundle.loadString('assets/l10n/$code.json'))
            as Map,
      );
      _cache[code] = map;
      return map;
    }

    return AppLocalizations(
      locale,
      await read(locale.languageCode),
      await read('en'),
    );
  }

  String tr(String key, [Map<String, Object?> params = const {}]) {
    final dynamic entry =
        messages[key] ??
        (locale.languageCode == 'zh' ? key : fallback[key]) ??
        key;
    String text;
    if (entry is Map) {
      final count = params['count'] ?? params['days'];
      final forms = Map<String, dynamic>.from(entry);
      final category = Intl.pluralLogic<String>(
        count is num ? count : 0,
        zero: 'zero',
        one: 'one',
        two: 'two',
        few: 'few',
        many: 'many',
        other: 'other',
        locale: locale.toLanguageTag(),
        useExplicitNumberCases: false,
      );
      text = (forms[category] ?? forms['other'] ?? key).toString();
    } else {
      text = entry.toString();
    }
    return text.replaceAllMapped(RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}'), (
      match,
    ) {
      final value = params[match[1]];
      if (value is DateTime) return date(value);
      if (value is num) return number(value);
      return value?.toString() ?? match[0]!;
    });
  }

  String number(num value) =>
      NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);
  String money(double value) => NumberFormat.currency(
    locale: locale.toLanguageTag(),
    name: 'CNY',
    decimalDigits: value == value.roundToDouble() ? 0 : 2,
  ).format(value);
  String editNumber(double value) {
    final symbols = NumberFormat.decimalPattern(locale.toLanguageTag()).symbols;
    var text = value.toString();
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    text = text.replaceAll('.', symbols.DECIMAL_SEP);
    final zero = symbols.ZERO_DIGIT.runes.first;
    return String.fromCharCodes(
      text.runes.map(
        (rune) => rune >= 0x30 && rune <= 0x39 ? rune - 0x30 + zero : rune,
      ),
    );
  }

  double? parseDecimal(String input) {
    var text = input.trim().replaceAll(
      RegExp(r'[\u200e\u200f\u061c\u2066-\u2069]'),
      '',
    );
    text = String.fromCharCodes(
      text.runes.map((rune) {
        for (final zero in [0x0660, 0x06f0, 0x0966, 0x09e6]) {
          if (rune >= zero && rune <= zero + 9) return rune - zero + 0x30;
        }
        return rune;
      }),
    );
    final symbols = NumberFormat.decimalPattern(locale.toLanguageTag()).symbols;
    text = text
        .replaceAll(symbols.GROUP_SEP, '')
        .replaceAll(RegExp(r'[\s\u00a0\u202f]'), '');
    text = text
        .replaceAll(symbols.DECIMAL_SEP, '.')
        .replaceAll('٫', '.')
        .replaceAll('٬', '');
    if (!RegExp(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$')
        .hasMatch(text)) {
      return null;
    }
    return double.tryParse(text);
  }

  String date(DateTime value) {
    initializeDateFormatting();
    return DateFormat.yMMMd(locale.toLanguageTag()).format(value);
  }

  String month(DateTime value) {
    initializeDateFormatting();
    return DateFormat.yMMMM(locale.toLanguageTag()).format(value);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => supportedAppLocales.any(
    (entry) => entry.languageCode == locale.languageCode,
  );
  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key, [Map<String, Object?> params = const {}]) =>
      l10n.tr(key, params);
  String categoryLabel(Category category) => tr(category.label);
  String seasonLabel(Season season) => tr(season.label);
  String tagLabel(String tag) => tr(tag);
  String number(num value) => l10n.number(value);
  String money(double value) => l10n.money(value);
  String editNumber(double value) => l10n.editNumber(value);
  double? parseDecimal(String value) => l10n.parseDecimal(value);
  String date(DateTime value) => l10n.date(value);
  String month(DateTime value) => l10n.month(value);
  String itemName(ClothingItem item) =>
      demoAssetFor(item) != null && _sampleItems.contains(item.name)
      ? tr(item.name)
      : item.name;
  String outfitName(Outfit outfit) {
    final signature = _sampleOutfits[outfit.name];
    if (signature == null) return outfit.name;
    final store = read<WardrobeStore>();
    final items = store.itemsOf(outfit);
    return items.length == signature.length &&
            items.every(
              (item) =>
                  signature.contains(item.name) && demoAssetFor(item) != null,
            )
        ? tr(outfit.name)
        : outfit.name;
  }
}

const _sampleItems = {
  '白色基础T恤',
  '海军条纹衫',
  '浅蓝牛津衬衫',
  '燕麦色针织衫',
  '直筒牛仔裤',
  '卡其休闲裤',
  '黑色百褶半裙',
  '碎花连衣裙',
  '卡其风衣',
  '灰色西装外套',
  '白色板鞋',
  '黑色乐福鞋',
  '帆布托特包',
  '酒红羊毛围巾',
};
const _sampleOutfits = <String, Set<String>>{
  '清爽通勤': {'浅蓝牛津衬衫', '卡其休闲裤', '黑色乐福鞋', '帆布托特包'},
  '周末随性': {'白色基础T恤', '直筒牛仔裤', '白色板鞋', '帆布托特包'},
  '法式条纹': {'海军条纹衫', '黑色百褶半裙', '黑色乐福鞋'},
  '风衣季': {'燕麦色针织衫', '直筒牛仔裤', '卡其风衣', '白色板鞋'},
  '正式会议': {'白色基础T恤', '灰色西装外套', '卡其休闲裤', '黑色乐福鞋'},
  '夏日碎花': {'碎花连衣裙', '白色板鞋', '帆布托特包'},
  '暖冬': {'燕麦色针织衫', '直筒牛仔裤', '酒红羊毛围巾', '黑色乐福鞋'},
};
