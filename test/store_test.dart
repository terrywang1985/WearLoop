import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/models.dart';
import 'package:wearloop/store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('首次启动载入示例数据，并能识别被遗忘的衣服', () async {
    final store = WardrobeStore(
      storageFactory: preferences.WearLoopStorage.open,
    );
    await store.load();
    expect(store.items, isNotEmpty);
    expect(store.outfits, isNotEmpty);
    expect(store.forgottenItems, isNotEmpty);
    expect(store.revivalOutfits, isNotEmpty);
  });

  test('记录穿着会更新次数和单次成本，同一天只保留一条', () async {
    final store = WardrobeStore(
      storageFactory: preferences.WearLoopStorage.open,
    );
    await store.load();
    store.clearAll();
    final item = ClothingItem(
      id: 'a',
      name: 'T恤',
      category: Category.top,
      color: kPresetColors.first,
      price: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    );
    store.upsertItem(item);
    expect(store.forgottenItems.map((e) => e.id), contains('a'));

    store.logWear(DateTime.now(), ['a']);
    store.logWear(DateTime.now(), ['a']);
    store.logWear(DateTime.now().subtract(const Duration(days: 1)), ['a']);
    expect(store.wearCount('a'), 2);
    expect(store.costPerWear(item), 50);
    expect(store.streak, 2);
    expect(store.forgottenItems, isEmpty);

    store.deleteItem('a');
    expect(store.logs, isEmpty);
  });

  test('数据可以持久化并重新读取', () async {
    final s1 = WardrobeStore(storageFactory: preferences.WearLoopStorage.open);
    await s1.load();
    final n = s1.items.length;
    final s2 = WardrobeStore(storageFactory: preferences.WearLoopStorage.open);
    await s2.load();
    expect(s2.items.length, n);
    expect(s2.logs.length, s1.logs.length);
  });
}
