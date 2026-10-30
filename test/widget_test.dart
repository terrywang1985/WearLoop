import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/main.dart';
import 'package:wearloop/models.dart';
import 'package:wearloop/screens/home_shell.dart';
import 'package:wearloop/store.dart';
import 'package:wearloop/theme.dart';

Future<WardrobeStore> mountApp(
  WidgetTester tester,
  Size size, {
  bool empty = false,
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final store = WardrobeStore(storageFactory: preferences.WearLoopStorage.open);
  await store.load();
  if (empty) store.clearAll();
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: store,
      child: dark
          ? MaterialApp(
              theme: buildTheme(Brightness.dark),
              home: const HomeShell(),
            )
          : const WearLoopApp(locale: Locale('zh')),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  for (final size in [
    const Size(320, 760),
    const Size(400, 860),
    const Size(768, 1024),
    const Size(1440, 1000),
  ]) {
    testWidgets('四个主页面适应 ${size.width.toInt()}px', (tester) async {
      await mountApp(tester, size);
      expect(find.text('今天穿什么？'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final tab in ['衣橱', '搭配', '统计']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$tab at ${size.width}px',
        );
      }
      expect(find.text('衣橱洞察'), findsWidgets);
    });
  }

  testWidgets('空衣橱和深色主题下所有页面可用', (tester) async {
    await mountApp(tester, const Size(360, 800), empty: true, dark: true);
    expect(find.text('添加第一件衣服'), findsOneWidget);
    for (final tab in ['衣橱', '搭配', '统计']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'empty $tab');
    }
    expect(find.text('喜欢，会在穿着中留下痕迹'), findsOneWidget);
  });

  testWidgets('衣橱搜索支持品牌，清空后恢复完整结果', (tester) async {
    final store = await mountApp(tester, const Size(400, 860));
    await tester.tap(find.text('衣橱'));
    await tester.pumpAndSettle();
    final search = find.byType(TextField);
    await tester.enterText(search, 'UNIQLO');
    await tester.pumpAndSettle();
    expect(find.text('白色基础T恤'), findsOneWidget);
    expect(find.text('直筒牛仔裤'), findsNothing);
    await tester.enterText(search, '不存在的衣服');
    await tester.pumpAndSettle();
    expect(find.text('白色基础T恤'), findsNothing);
    expect(store.items.length, 14);
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(find.text('黑色百褶半裙'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('本周日期可直接打开该日记录', (tester) async {
    await mountApp(tester, const Size(400, 860));
    final target = find.byKey(ValueKey('wear-day-${fmtDate(DateTime.now())}'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.text('记录穿搭'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
