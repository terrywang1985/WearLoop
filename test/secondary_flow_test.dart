import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/models.dart';
import 'package:wearloop/screens/history_screen.dart';
import 'package:wearloop/screens/item_detail_screen.dart';
import 'package:wearloop/screens/item_edit_screen.dart';
import 'package:wearloop/screens/log_wear_screen.dart';
import 'package:wearloop/screens/outfit_detail_screen.dart';
import 'package:wearloop/screens/outfit_edit_screen.dart';
import 'package:wearloop/screens/settings_screen.dart';
import 'package:wearloop/screens/share_screen.dart';
import 'package:wearloop/store.dart';
import 'package:wearloop/theme.dart';

ClothingItem item(String id, {double? price}) => ClothingItem(
  id: id,
  name: '单品 $id',
  category: Category.top,
  color: kPresetColors.first,
  price: price,
  createdAt: DateTime.now(),
);

Future<WardrobeStore> emptyStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = WardrobeStore(storageFactory: preferences.WearLoopStorage.open);
  await store.load();
  store.clearAll();
  return store;
}

Future<void> openScreen(
  WidgetTester tester,
  WardrobeStore store,
  Widget screen, {
  Size size = const Size(400, 860),
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        theme: buildTheme(brightness),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => screen),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('大量单品的历史记录在窄屏中收起额外缩略图', (tester) async {
    final store = await emptyStore();
    for (var i = 0; i < 14; i++) {
      store.upsertItem(item('$i'));
    }
    store.logWear(DateTime.now(), store.items.map((item) => item.id).toList());
    await openScreen(
      tester,
      store,
      const HistoryScreen(),
      size: const Size(320, 760),
    );
    expect(find.text('自由搭配'), findsOneWidget);
    expect(find.textContaining('14 件单品'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('编辑单品保留价格小数精度并拒绝负价格', (tester) async {
    final store = await emptyStore();
    final clothing = item('a', price: 199.99);
    store.upsertItem(clothing);
    await openScreen(tester, store, ItemEditScreen(item: clothing));
    final priceField = find.byType(TextFormField);
    await tester.scrollUntilVisible(
      priceField,
      240,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('199.99'), findsOneWidget);
    await tester.enterText(priceField, '-3');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入有效的非负价格'), findsOneWidget);
    expect(store.itemById('a')!.price, 199.99);
    await tester.enterText(priceField, '199.99');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(store.itemById('a')!.price, 199.99);
    expect(find.text('打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搭配编辑保留备注和收藏状态', (tester) async {
    final store = await emptyStore();
    store.upsertItem(item('a'));
    final outfit = Outfit(
      id: 'look',
      name: '周一通勤',
      itemIds: ['a'],
      note: '把衬衫下摆收进裤腰',
      favorite: true,
      createdAt: DateTime.now(),
    );
    store.upsertOutfit(outfit);
    await openScreen(
      tester,
      store,
      OutfitEditScreen(outfit: outfit),
      size: const Size(320, 860),
    );
    expect(find.text(outfit.note), findsOneWidget);
    await tester.tap(find.text('保存搭配 · 1 件单品'));
    await tester.pumpAndSettle();
    expect(store.outfitById('look')!.note, outfit.note);
    expect(store.outfitById('look')!.favorite, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('给今日搭配添加其他单品后清除原搭配归属', (tester) async {
    final store = await emptyStore();
    store.upsertItem(item('a'));
    store.upsertItem(item('b'));
    store.upsertOutfit(
      Outfit(
        id: 'look',
        name: '基础搭配',
        itemIds: ['a'],
        createdAt: DateTime.now(),
      ),
    );
    store.logWear(DateTime.now(), ['a'], outfitId: 'look');
    await openScreen(tester, store, const ItemDetailScreen(itemId: 'b'));
    await tester.ensureVisible(find.text('今天穿了它'));
    await tester.tap(find.text('今天穿了它'));
    await tester.pumpAndSettle();
    expect(store.todayLog!.itemIds.toSet(), {'a', 'b'});
    expect(store.todayLog!.outfitId, isNull);
    expect(store.outfitWearCount('look'), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('移动历史记录日期会移除原日期记录', (tester) async {
    final store = await emptyStore();
    store.upsertItem(item('a'));
    final yesterday = dateOnly(DateTime.now())
        .subtract(const Duration(days: 1));
    store.logWear(yesterday, ['a']);
    final existing = store.logOn(yesterday)!;
    await openScreen(tester, store, LogWearScreen(existing: existing));
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().day}').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存穿搭'));
    await tester.pumpAndSettle();
    expect(store.logOn(yesterday), isNull);
    expect(store.todayLog!.itemIds, ['a']);
    expect(store.logs.length, 1);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      final appearance = brightness == Brightness.dark ? '深色' : '浅色';
      testWidgets('${width.toInt()}px $appearance搭配详情可打开并滚动分享卡', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final store = WardrobeStore(
          storageFactory: preferences.WearLoopStorage.open,
        );
        await store.load();
        final outfit = store.outfits.first;
        await openScreen(
          tester,
          store,
          OutfitDetailScreen(outfitId: outfit.id),
          size: Size(width, 860),
          brightness: brightness,
        );
        expect(find.text(outfit.name), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('生成穿搭分享卡'));
        await tester.tap(find.text('生成穿搭分享卡'));
        await tester.pumpAndSettle();
        expect(find.byType(ShareScreen), findsOneWidget);
        expect(find.text('复制文字'), findsOneWidget);
        expect(find.text('分享图片'), findsOneWidget);
        // The export keeps a light paper background in either app appearance.
        expect(
          Theme.of(tester.element(find.text('我的穿搭手记'))).brightness,
          Brightness.light,
        );
        await tester.ensureVisible(find.text('穿得更多，浪费更少。'));
        await tester.pumpAndSettle();
        expect(find.text('让好衣服，反复出场。'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${width.toInt()}px $appearance设置可调整阈值并取消清空', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final store = WardrobeStore(
          storageFactory: preferences.WearLoopStorage.open,
        );
        await store.load();
        final itemCount = store.items.length;
        await openScreen(
          tester,
          store,
          const SettingsScreen(),
          size: Size(width, 860),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        final pageScrollable = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('60 天'),
          200,
          scrollable: pageScrollable,
        );
        await tester.tap(find.text('60 天'));
        await tester.pumpAndSettle();
        expect(store.forgottenDays, 60);
        await tester.scrollUntilVisible(
          find.text('清空全部数据'),
          200,
          scrollable: pageScrollable,
        );
        await tester.tap(find.text('清空全部数据'));
        await tester.pumpAndSettle();
        expect(find.text('清空全部数据？'), findsOneWidget);
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(store.items.length, itemCount);
        await tester.scrollUntilVisible(
          find.text('关于 WearLoop'),
          200,
          scrollable: pageScrollable,
        );
        expect(find.text('关于 WearLoop'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
