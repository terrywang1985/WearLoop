import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/l10n/app_localizations.dart';
import 'package:wearloop/l10n/locale_controller.dart';
import 'package:wearloop/main.dart';
import 'package:wearloop/screens/home_shell.dart';
import 'package:wearloop/screens/item_detail_screen.dart';
import 'package:wearloop/screens/outfit_detail_screen.dart';
import 'package:wearloop/screens/settings_screen.dart';
import 'package:wearloop/screens/share_screen.dart';
import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:wearloop/store.dart';

Future<WardrobeStore> _openApp(
  WidgetTester tester,
  String code, {
  double width = 360,
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final store = WardrobeStore(storageFactory: preferences.WearLoopStorage.open);
  await store.load();
  await tester.binding.setSurfaceSize(Size(width, 840));
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() async {
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: store,
      child: WearLoopApp(locale: Locale(code)),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void _expectClean(WidgetTester tester, String stage) {
  expect(tester.takeException(), isNull, reason: stage);
}

Future<void> _scrollPage(WidgetTester tester, String stage) async {
  final vertical = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
  );
  if (vertical.evaluate().isNotEmpty) {
    await tester.drag(vertical.first, const Offset(0, -1200));
    await tester.pumpAndSettle();
  }
  _expectClean(tester, stage);
}

Future<void> _checkMainPages(WidgetTester tester, String code) async {
  final locale = Locale(code);
  final strings = await AppLocalizations.load(locale);
  expect(find.text(strings.tr('今天穿什么？')), findsOneWidget);
  final actual = tester.element(find.byType(HomeShell));
  expect(Localizations.localeOf(actual).languageCode, code);
  expect(
    Directionality.of(actual),
    {'ar', 'ur'}.contains(code) ? TextDirection.rtl : TextDirection.ltr,
  );
  _expectClean(tester, '$code Today');
  await _scrollPage(tester, '$code Today scrolled');
  for (var index = 1; index < 4; index++) {
    await tester.tap(find.byType(NavigationDestination).at(index));
    await tester.pumpAndSettle();
    _expectClean(tester, '$code tab $index');
    await _scrollPage(tester, '$code tab $index scrolled');
  }
  expect(find.text(strings.tr('衣橱洞察')), findsWidgets);
}

void main() {
  for (final locale in supportedAppLocales) {
    final code = locale.languageCode;
    testWidgets('$code main screens fit 360px', (tester) async {
      await _openApp(tester, code);
      await _checkMainPages(tester, code);
    });

    testWidgets('$code settings and outfit share fit 360px', (tester) async {
      final store = await _openApp(tester, code);
      final strings = await AppLocalizations.load(locale);
      final navigator = Navigator.of(tester.element(find.byType(HomeShell)));
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text(strings.tr('语言')), findsOneWidget);
      _expectClean(tester, '$code Settings');
      await _scrollPage(tester, '$code Settings scrolled');
      navigator.pop();
      await tester.pumpAndSettle();

      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ItemDetailScreen(itemId: store.items.first.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      _expectClean(tester, '$code Item details');
      await _scrollPage(tester, '$code Item details scrolled');
      navigator.pop();
      await tester.pumpAndSettle();

      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => OutfitDetailScreen(outfitId: store.outfits.first.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutfitDetailScreen), findsOneWidget);
      _expectClean(tester, '$code Outfit details');
      final share = find.text(strings.tr('生成穿搭分享卡'));
      // The overview is one tall ListView child; drag like a user rather than
      // relying on ensureVisible to align the whole oversized child.
      for (
        var attempt = 0;
        attempt < 8 && share.hitTestable().evaluate().isEmpty;
        attempt++
      ) {
        final scrollable = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        );
        await tester.drag(scrollable.first, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
      expect(share.hitTestable(), findsOneWidget);
      await tester.tap(share);
      await tester.pumpAndSettle();
      expect(find.byType(ShareScreen), findsOneWidget);
      expect(find.text(strings.tr('复制文字')), findsOneWidget);
      expect(find.text(strings.tr('分享图片')), findsOneWidget);
      _expectClean(tester, '$code Share');
      await _scrollPage(tester, '$code Share scrolled');
    });
  }

  for (final code in ['ar', 'ur', 'de', 'fr', 'hi', 'bn']) {
    testWidgets('$code main screens fit 320px with larger text', (
      tester,
    ) async {
      await _openApp(tester, code, width: 320, textScale: 1.2);
      await _checkMainPages(tester, code);
    });
  }
}
