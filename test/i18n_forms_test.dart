import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/l10n/app_localizations.dart';
import 'package:wearloop/l10n/locale_controller.dart';
import 'package:wearloop/screens/item_edit_screen.dart';
import 'package:wearloop/screens/outfit_edit_screen.dart';
import 'package:wearloop/screens/log_wear_screen.dart';
import 'package:wearloop/screens/smart_import_screen.dart';
import 'package:wearloop/store.dart';
import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:wearloop/theme.dart';

Future<WardrobeStore> setup(
  WidgetTester tester,
  Locale locale,
  Widget Function(WardrobeStore) screen,
) async {
  SharedPreferences.setMockInitialValues({});
  final store = WardrobeStore(storageFactory: preferences.WearLoopStorage.open);
  await store.load();
  await tester.binding.setSurfaceSize(const Size(320, 840));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        locale: locale,
        supportedLocales: supportedAppLocales,
        theme: buildTheme(Brightness.light),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => screen(store)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  for (final locale in supportedAppLocales) {
    testWidgets('${locale.languageCode} editors and record picker fit 320px', (
      tester,
    ) async {
      final pages = <Widget Function(WardrobeStore)>[
        (s) => ItemEditScreen(item: s.items.first),
        (s) => OutfitEditScreen(outfit: s.outfits.first),
        (_) => const LogWearScreen(),
        (_) => const SmartImportScreen(),
      ];
      for (var index = 0; index < pages.length; index++) {
        await setup(tester, locale, pages[index]);
        expect(
          tester.takeException(),
          isNull,
          reason: '${locale.languageCode} form$index',
        );
        final vertical = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        if (vertical.evaluate().isNotEmpty) {
          await tester.drag(vertical.first, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${locale.languageCode} scrolled form$index',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets(
    'editing translated sample item preserves canonical name and decimal price',
    (tester) async {
      const locale = Locale('fr');
      final strings = await AppLocalizations.load(locale);
      final store = await setup(
        tester,
        locale,
        (s) => ItemEditScreen(item: s.items.first),
      );
      final item = store.items.first;
      final original = item.name;
      expect(find.text(strings.tr(original)), findsOneWidget);
      final price = find.byType(TextFormField);
      final mainScroll = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(price, 250, scrollable: mainScroll);
      await tester.enterText(price, '199,99');
      await tester.tap(find.text(strings.tr('保存')));
      await tester.pumpAndSettle();
      expect(store.itemById(item.id)!.name, original);
      expect(store.itemById(item.id)!.price, 199.99);
      expect(find.text('open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing translated sample outfit preserves stored name and notes',
    (tester) async {
      const locale = Locale('ar');
      final strings = await AppLocalizations.load(locale);
      final store = await setup(
        tester,
        locale,
        (s) => OutfitEditScreen(outfit: s.outfits.first),
      );
      final outfit = store.outfits.first;
      final original = outfit.name;
      expect(find.text(strings.tr(original)), findsOneWidget);
      await tester.tap(
        find.text(
          strings.tr('保存搭配 · {count} 件单品', {'count': outfit.itemIds.length}),
        ),
      );
      await tester.pumpAndSettle();
      expect(store.outfitById(outfit.id)!.name, original);
      expect(store.outfitById(outfit.id)!.note, outfit.note);
      expect(find.text('open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
