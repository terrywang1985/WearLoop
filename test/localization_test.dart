import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/l10n/app_localizations.dart';
import 'package:wearloop/l10n/locale_controller.dart';
import 'package:wearloop/main.dart';
import 'package:wearloop/models.dart';
import 'package:wearloop/store.dart';
import 'package:wearloop/storage/storage_web.dart' as preferences;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('15种语言资源完整，占位符和复数消息有效', () async {
    final english = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/l10n/en.json')) as Map,
    );
    final tokens = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\}');
    Set<String> placeholders(String message) =>
        tokens.allMatches(message).map((m) => m[1]!).toSet();
    expect(supportedAppLocales.length, 15);
    for (final locale in supportedAppLocales) {
      final l10n = await AppLocalizations.load(locale);
      expect(
        l10n.messages.keys.toSet(),
        english.keys.toSet(),
        reason: locale.languageCode,
      );
      for (final entry in l10n.messages.entries) {
        final forms = entry.value is Map
            ? (entry.value as Map).values
            : [entry.value];
        for (final message in forms) {
          expect((message as String).trim(), isNotEmpty);
          expect(
            placeholders(message),
            placeholders(entry.key),
            reason: '${locale.languageCode}: ${entry.key}',
          );
        }
      }
    }
  });

  test('阿拉伯语和俄语使用各自的 CLDR 复数规则', () {
    const forms = {
      'zero': 'zero',
      'one': 'one',
      'two': 'two',
      'few': 'few',
      'many': 'many',
      'other': 'other',
    };
    const arabic = AppLocalizations(Locale('ar'), {'x': forms});
    const russian = AppLocalizations(Locale('ru'), {'x': forms});
    for (final entry in {
      0: 'zero',
      1: 'one',
      2: 'two',
      3: 'few',
      11: 'many',
      100: 'other',
    }.entries) {
      expect(arabic.tr('x', {'count': entry.key}), entry.value);
    }
    for (final entry in {
      1: 'one',
      2: 'few',
      5: 'many',
      21: 'one',
      22: 'few',
      25: 'many',
    }.entries) {
      expect(russian.tr('x', {'count': entry.key}), entry.value);
    }
  });

  test('本地化小数输入可往返且币种保持 CNY', () async {
    for (final code in [
      'en',
      'zh',
      'fr',
      'de',
      'ar',
      'ur',
      'hi',
      'bn',
      'pt',
      'ru',
    ]) {
      final l10n = await AppLocalizations.load(Locale(code));
      expect(l10n.parseDecimal(l10n.editNumber(199.99)), 199.99, reason: code);
      expect(l10n.money(199.99), isNot(contains('USD')));
    }
    const french = AppLocalizations(Locale('fr'), {});
    const arabic = AppLocalizations(Locale('ar'), {});
    const hindi = AppLocalizations(Locale('hi'), {});
    const bengali = AppLocalizations(Locale('bn'), {});
    expect(french.parseDecimal('199,99'), 199.99);
    expect(arabic.parseDecimal('١٩٩٫٩٩'), 199.99);
    expect(hindi.parseDecimal('१९९.९९'), 199.99);
    expect(bengali.parseDecimal('১৯৯.৯৯'), 199.99);
    expect(french.parseDecimal('abc'), isNull);
  });

  test('语言选择持久化并可恢复跟随系统', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController();
    await controller.setLocale(const Locale('ja'));
    final restored = LocaleController();
    await restored.load();
    expect(restored.locale, const Locale('ja'));
    await restored.setLocale(null);
    final follow = LocaleController();
    await follow.load();
    expect(follow.locale, isNull);
    expect(
      resolveAppLocale([const Locale('pt', 'BR')], supportedAppLocales),
      const Locale('pt'),
    );
    expect(
      resolveAppLocale([const Locale('xx')], supportedAppLocales),
      const Locale('en'),
    );
    controller.dispose();
    restored.dispose();
    follow.dispose();
  });

  testWidgets('设置切换语言实时生效并保留个人数据', (tester) async {
    SharedPreferences.setMockInitialValues({'wl_locale': 'zh'});
    final store = WardrobeStore(
      storageFactory: preferences.WearLoopStorage.open,
    );
    await store.load();
    store.upsertItem(
      ClothingItem(
        id: 'personal',
        name: 'My favorite 衬衫',
        category: Category.top,
        color: Colors.blue,
        notes: 'Personal note',
        createdAt: DateTime.now(),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: store, child: const WearLoopApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    final language = find.text('语言');
    await tester.ensureVisible(language);
    await tester.tap(language);
    await tester.pumpAndSettle();
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();
    final japanese = await AppLocalizations.load(const Locale('ja'));
    expect(find.text(japanese.tr('设置')), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString(
        LocaleController.preferenceKey,
      ),
      'ja',
    );
    expect(store.items.length, 15);
    expect(store.itemById('personal')!.name, 'My favorite 衬衫');
    expect(store.itemById('personal')!.notes, 'Personal note');
    expect(tester.takeException(), isNull);
  });
}
