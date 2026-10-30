import 'models.dart';

/// Bundled AI product photos are only a visual fallback for the exact demo
/// wardrobe. A personal photo always takes priority; new personal items use
/// their own photo or the category illustration.
String? demoAssetFor(ClothingItem item) {
  final saved = item.demoAsset;
  if (saved != null &&
      _demo.values.any(
        (entry) => 'assets/clothing/${entry.$4}.webp' == saved,
      )) {
    return saved;
  }
  final demo = _demo[item.name];
  if (demo == null ||
      item.category != demo.$1 ||
      item.color.toARGB32() != demo.$2 ||
      item.price != demo.$3 ||
      item.brand != demo.$5) {
    return null;
  }
  return 'assets/clothing/${demo.$4}.webp';
}

const _demo = <String, (Category, int, double, String, String)>{
  '白色基础T恤': (Category.top, 0xFFFFFFFF, 99, 'white-tee', 'UNIQLO'),
  '海军条纹衫': (Category.top, 0xFF2B3A67, 259, 'striped-top', ''),
  '浅蓝牛津衬衫': (Category.top, 0xFF5B8DEF, 299, 'oxford-shirt', ''),
  '燕麦色针织衫': (Category.top, 0xFFD9C3A5, 459, 'knit', ''),
  '直筒牛仔裤': (Category.bottom, 0xFF2B3A67, 399, 'jeans', "Levi's"),
  '卡其休闲裤': (Category.bottom, 0xFFD9C3A5, 299, 'chinos', ''),
  '黑色百褶半裙': (Category.bottom, 0xFF1F1F1F, 329, 'pleated-skirt', ''),
  '碎花连衣裙': (Category.dress, 0xFFF2A7B5, 529, 'dress', ''),
  '卡其风衣': (Category.outerwear, 0xFF8B5E3C, 899, 'trench', ''),
  '灰色西装外套': (Category.outerwear, 0xFF9E9E9E, 799, 'blazer', ''),
  '白色板鞋': (Category.shoes, 0xFFFFFFFF, 599, 'sneakers', ''),
  '黑色乐福鞋': (Category.shoes, 0xFF1F1F1F, 699, 'loafers', ''),
  '帆布托特包': (Category.bag, 0xFFD9C3A5, 159, 'tote', ''),
  '酒红羊毛围巾': (Category.accessory, 0xFFC0392B, 259, 'scarf', ''),
};
