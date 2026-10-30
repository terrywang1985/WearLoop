import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/demo_assets.dart';
import 'package:wearloop/models.dart';
import 'package:wearloop/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('全部示例衣物均有可离线加载的商品图', () async {
    SharedPreferences.setMockInitialValues({});
    final store = WardrobeStore(
      storageFactory: preferences.WearLoopStorage.open,
    );
    await store.load();
    final assets = <String>{};
    for (final item in store.items) {
      final asset = demoAssetFor(item);
      expect(asset, isNotNull, reason: item.name);
      assets.add(asset!);
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }
    expect(assets.length, 14);
  });

  test('修改示例名称或价格后可通过持久化的图片引用保留照片', () async {
    SharedPreferences.setMockInitialValues({});
    final store = WardrobeStore(
      storageFactory: preferences.WearLoopStorage.open,
    );
    await store.load();
    final item = store.items.first;
    item.demoAsset = demoAssetFor(item);
    item.name = '我的基础白T';
    item.price = 88.88;
    final saved = ClothingItem.fromJson(item.toJson());
    expect(demoAssetFor(saved), item.demoAsset);
    expect(saved.price, 88.88);
  });

  test('个人衣物不冒用示例照片，旧版数据可兼容读取', () {
    final item = ClothingItem(
      id: 'personal',
      name: '我的针织衫',
      category: Category.top,
      color: kPresetColors.first,
      createdAt: DateTime.now(),
    );
    expect(demoAssetFor(item), isNull);
    final oldJson = item.toJson()..remove('demoAsset');
    expect(ClothingItem.fromJson(oldJson).demoAsset, isNull);
    item.demoAsset = 'assets/unknown.webp';
    expect(demoAssetFor(item), isNull);
  });
}
