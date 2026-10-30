import 'package:flutter/material.dart';

/// 衣物分类
enum Category {
  top('上衣', Icons.checkroom, '👕'),
  bottom('下装', Icons.view_week_outlined, '👖'),
  pants('裤子', Icons.view_week_outlined, '👖'),
  shorts('短裤', Icons.view_week_outlined, '🩳'),
  skirt('裙子', Icons.woman, '👗'),
  dress('连衣裙', Icons.woman, '👗'),
  outerwear('外套', Icons.dry_cleaning, '🧥'),
  shoes('鞋子', Icons.directions_walk, '👟'),
  bag('包包', Icons.shopping_bag, '👜'),
  accessory('配饰', Icons.watch, '🧣');

  const Category(this.label, this.icon, this.emoji);
  final String label;
  final IconData icon;
  final String emoji;
}

enum Season {
  spring('春'),
  summer('夏'),
  autumn('秋'),
  winter('冬');

  const Season(this.label);
  final String label;
}

/// 常用颜色预设
const List<Color> kPresetColors = [
  Color(0xFF1F1F1F),
  Color(0xFFFFFFFF),
  Color(0xFF9E9E9E),
  Color(0xFF2B3A67),
  Color(0xFF5B8DEF),
  Color(0xFFD9C3A5),
  Color(0xFF8B5E3C),
  Color(0xFF4F7A55),
  Color(0xFFC0392B),
  Color(0xFFF2A7B5),
  Color(0xFFF4D35E),
  Color(0xFF7E57C2),
];

class ClothingItem {
  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    this.seasons = const {},
    this.brand = '',
    this.price,
    this.purchaseDate,
    this.imageBase64,
    this.imagePath,
    this.demoAsset,
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  String name;
  Category category;
  Color color;
  Set<Season> seasons;
  String brand;
  double? price;
  DateTime? purchaseDate;
  String? imageBase64;
  String? imagePath;
  String? demoAsset;
  String notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'color': color.toARGB32(),
    'seasons': seasons.map((s) => s.name).toList(),
    'brand': brand,
    'price': price,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'image': imageBase64,
    'imagePath': imagePath,
    'demoAsset': demoAsset,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ClothingItem.fromJson(Map<String, dynamic> j) => ClothingItem(
    id: j['id'],
    name: j['name'],
    category: Category.values.byName(j['category']),
    color: Color(j['color']),
    seasons: {
      for (final s in (j['seasons'] as List? ?? [])) Season.values.byName(s),
    },
    brand: j['brand'] ?? '',
    price: (j['price'] as num?)?.toDouble(),
    purchaseDate: j['purchaseDate'] == null
        ? null
        : DateTime.parse(j['purchaseDate']),
    imageBase64: j['image'],
    imagePath: j['imagePath'],
    demoAsset: j['demoAsset'],
    notes: j['notes'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
  );
}

/// 预设搭配场景标签
const List<String> kOutfitTags = ['通勤', '周末', '约会', '运动', '旅行', '正式', '居家'];

class Outfit {
  Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    this.tags = const {},
    this.favorite = false,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  String name;
  List<String> itemIds;
  Set<String> tags;
  bool favorite;
  String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'itemIds': itemIds,
    'tags': tags.toList(),
    'favorite': favorite,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Outfit.fromJson(Map<String, dynamic> j) => Outfit(
    id: j['id'],
    name: j['name'],
    itemIds: List<String>.from(j['itemIds']),
    tags: Set<String>.from(j['tags'] ?? []),
    favorite: j['favorite'] ?? false,
    note: j['note'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
  );
}

/// 一次穿着记录：某一天穿了哪些衣服（可来自某套搭配）
class WearLog {
  WearLog({
    required this.id,
    required this.date,
    required this.itemIds,
    this.outfitId,
  });

  final String id;
  final DateTime date; // 只保留年月日
  List<String> itemIds;
  String? outfitId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'itemIds': itemIds,
    'outfitId': outfitId,
  };

  factory WearLog.fromJson(Map<String, dynamic> j) => WearLog(
    id: j['id'],
    date: DateTime.parse(j['date']),
    itemIds: List<String>.from(j['itemIds']),
    outfitId: j['outfitId'],
  );
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtMoney(double v) =>
    v == v.roundToDouble() ? '¥${v.toInt()}' : '¥${v.toStringAsFixed(1)}';
