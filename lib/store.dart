import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'models.dart';
import 'storage/storage.dart';
import 'storage/storage_contract.dart';

/// 全局状态 + 本地持久化。所有数据都保存在设备本地（离线可用）。
class WardrobeStore extends ChangeNotifier {
  WardrobeStore({
    Future<WardrobeStorage> Function()? storageFactory,
    DateTime Function()? clock,
  }) : _storageFactory = storageFactory ?? WearLoopStorage.open,
       _clock = clock ?? DateTime.now;
  final Future<WardrobeStorage> Function() _storageFactory;
  final DateTime Function() _clock;

  /// Keeps calendar queries consistent and allows deterministic preview data.
  DateTime get now => _clock();
  late WardrobeStorage _storage;
  final List<ClothingItem> items = [];
  final List<Outfit> outfits = [];
  final List<WearLog> logs = []; // 按日期倒序
  int forgottenDays = 30;

  final Map<String, int> _wearCount = {};
  final Map<String, DateTime> _lastWorn = {};
  int _idSeq = 0;

  String newId() =>
      '${now.microsecondsSinceEpoch.toRadixString(36)}${(_idSeq++).toRadixString(36)}';

  Future<void> load() async {
    _storage = await _storageFactory();
    final snapshot = await _storage.load();
    if (!snapshot.initialized) {
      seedDemoData();
      await _save();
    } else {
      items.addAll(snapshot.items);
      outfits.addAll(snapshot.outfits);
      logs.addAll(snapshot.logs);
      forgottenDays = snapshot.forgottenDays;
    }
    _recompute();
  }

  Future<void> _save() => _storage.saveSnapshot(
    items: items,
    outfits: outfits,
    logs: logs,
    forgottenDays: forgottenDays,
  );

  Future<({String? imagePath, String? imageBase64})> saveImageBytes(
    Uint8List bytes,
    String itemId,
  ) async {
    if (kIsWeb) {
      return (imagePath: null, imageBase64: base64Encode(bytes));
    }
    final path = await _storage.saveImage(bytes, itemId);
    return (imagePath: path, imageBase64: null);
  }

  void _changed() {
    _recompute();
    notifyListeners();
    unawaited(_save());
  }

  void _recompute() {
    logs.sort((a, b) => b.date.compareTo(a.date));
    _wearCount.clear();
    _lastWorn.clear();
    for (final log in logs) {
      for (final id in log.itemIds) {
        _wearCount[id] = (_wearCount[id] ?? 0) + 1;
        final prev = _lastWorn[id];
        if (prev == null || log.date.isAfter(prev)) _lastWorn[id] = log.date;
      }
    }
  }

  // ---------- 查询 ----------

  ClothingItem? itemById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Outfit? outfitById(String? id) {
    if (id == null) return null;
    for (final o in outfits) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<ClothingItem> itemsOf(Outfit o) =>
      o.itemIds.map(itemById).whereType<ClothingItem>().toList();

  int wearCount(String itemId) => _wearCount[itemId] ?? 0;
  DateTime? lastWorn(String itemId) => _lastWorn[itemId];

  /// 距上次穿着的天数；从未穿过则从入橱日期算起
  int idleDays(ClothingItem item) {
    final ref = _lastWorn[item.id] ?? item.createdAt;
    return dateOnly(now).difference(dateOnly(ref)).inDays;
  }

  /// 单次穿着成本 = 价格 / 穿着次数
  double? costPerWear(ClothingItem item) {
    if (item.price == null) return null;
    final n = wearCount(item.id);
    return n == 0 ? item.price : item.price! / n;
  }

  /// 被遗忘的衣服：超过阈值天数没穿，按闲置天数倒序
  List<ClothingItem> get forgottenItems {
    final list = items.where((i) => idleDays(i) >= forgottenDays).toList();
    list.sort((a, b) => idleDays(b).compareTo(idleDays(a)));
    return list;
  }

  /// 推荐搭配：优先包含被遗忘衣服最多的搭配
  List<Outfit> get revivalOutfits {
    final forgotten = forgottenItems.map((e) => e.id).toSet();
    final scored =
        outfits
            .map((o) => (o, o.itemIds.where(forgotten.contains).length))
            .where((e) => e.$2 > 0)
            .toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  WearLog? logOn(DateTime day) {
    final d = dateOnly(day);
    for (final l in logs) {
      if (l.date == d) return l;
    }
    return null;
  }

  WearLog? get todayLog => logOn(now);

  /// 连续记录天数（今天没记录时从昨天往前算）
  int get streak {
    var day = dateOnly(now);
    if (logOn(day) == null) day = day.subtract(const Duration(days: 1));
    var n = 0;
    while (logOn(day) != null) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// 衣橱利用率：最近 30 天穿过的衣服占比
  double get utilization30 {
    if (items.isEmpty) return 0;
    final worn = items.where((i) {
      final lw = _lastWorn[i.id];
      return lw != null && now.difference(lw).inDays < 30;
    }).length;
    return worn / items.length;
  }

  int outfitWearCount(String outfitId) =>
      logs.where((l) => l.outfitId == outfitId).length;

  // ---------- 修改 ----------

  void upsertItem(ClothingItem item) {
    final i = items.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      final oldPath = items[i].imagePath;
      items[i] = item;
      if (oldPath != null && oldPath != item.imagePath) {
        unawaited(_storage.deleteImage(oldPath));
      }
    } else {
      items.insert(0, item);
    }
    _changed();
  }

  void addItems(Iterable<ClothingItem> newItems) {
    final list = newItems.toList();
    if (list.isEmpty) return;
    items.insertAll(0, list);
    _changed();
  }

  void deleteItem(String id) {
    final removed = itemById(id);
    items.removeWhere((e) => e.id == id);
    for (final o in outfits) {
      o.itemIds.remove(id);
    }
    for (final l in logs) {
      l.itemIds.remove(id);
    }
    logs.removeWhere((l) => l.itemIds.isEmpty);
    if (removed != null) {
      unawaited(_storage.deleteImage(removed.imagePath));
    }
    _changed();
  }

  void upsertOutfit(Outfit outfit) {
    final i = outfits.indexWhere((e) => e.id == outfit.id);
    i >= 0 ? outfits[i] = outfit : outfits.insert(0, outfit);
    _changed();
  }

  void deleteOutfit(String id) {
    outfits.removeWhere((e) => e.id == id);
    for (final l in logs) {
      if (l.outfitId == id) l.outfitId = null;
    }
    _changed();
  }

  void toggleFavorite(Outfit o) {
    o.favorite = !o.favorite;
    _changed();
  }

  /// 记录某天的穿着；同一天只保留一条（再次记录即覆盖）
  void logWear(DateTime day, List<String> itemIds, {String? outfitId}) {
    final d = dateOnly(day);
    logs.removeWhere((l) => l.date == d);
    if (itemIds.isNotEmpty) {
      logs.add(
        WearLog(id: newId(), date: d, itemIds: itemIds, outfitId: outfitId),
      );
    }
    _changed();
  }

  void deleteLog(String id) {
    logs.removeWhere((l) => l.id == id);
    _changed();
  }

  void setForgottenDays(int days) {
    forgottenDays = days;
    _changed();
  }

  void clearAll() {
    items.clear();
    outfits.clear();
    logs.clear();
    unawaited(_storage.clearImages());
    _changed();
  }

  void resetDemo() {
    items.clear();
    outfits.clear();
    logs.clear();
    unawaited(_storage.clearImages());
    seedDemoData();
    _changed();
  }

  // ---------- 示例数据 ----------

  void seedDemoData() {
    final now = this.now;
    final rnd = Random(7);
    ClothingItem mk(
      String name,
      Category c,
      int color,
      double price,
      Set<Season> seasons,
      int ageDays, {
      String brand = '',
    }) {
      final it = ClothingItem(
        id: newId(),
        name: name,
        category: c,
        color: Color(color),
        seasons: seasons,
        brand: brand,
        price: price,
        purchaseDate: now.subtract(Duration(days: ageDays)),
        createdAt: now.subtract(Duration(days: ageDays)),
      );
      items.add(it);
      return it;
    }

    const all = {Season.spring, Season.summer, Season.autumn, Season.winter};
    const sa = {Season.spring, Season.autumn};
    final whiteTee = mk(
      '白色基础T恤',
      Category.top,
      0xFFFFFFFF,
      99,
      all,
      300,
      brand: 'UNIQLO',
    );
    final stripe = mk('海军条纹衫', Category.top, 0xFF2B3A67, 259, sa, 260);
    final oxford = mk('浅蓝牛津衬衫', Category.top, 0xFF5B8DEF, 299, sa, 400);
    final knit = mk('燕麦色针织衫', Category.top, 0xFFD9C3A5, 459, {
      Season.autumn,
      Season.winter,
    }, 200);
    final jeans = mk(
      '直筒牛仔裤',
      Category.bottom,
      0xFF2B3A67,
      399,
      all,
      500,
      brand: "Levi's",
    );
    final chino = mk('卡其休闲裤', Category.bottom, 0xFFD9C3A5, 299, sa, 350);
    final skirt = mk('黑色百褶半裙', Category.bottom, 0xFF1F1F1F, 329, sa, 180);
    final dress = mk('碎花连衣裙', Category.dress, 0xFFF2A7B5, 529, {
      Season.summer,
    }, 420);
    final trench = mk('卡其风衣', Category.outerwear, 0xFF8B5E3C, 899, sa, 600);
    final blazer = mk('灰色西装外套', Category.outerwear, 0xFF9E9E9E, 799, sa, 330);
    final sneaker = mk('白色板鞋', Category.shoes, 0xFFFFFFFF, 599, all, 450);
    final loafer = mk('黑色乐福鞋', Category.shoes, 0xFF1F1F1F, 699, all, 380);
    final tote = mk('帆布托特包', Category.bag, 0xFFD9C3A5, 159, all, 240);
    final scarf = mk('酒红羊毛围巾', Category.accessory, 0xFFC0392B, 259, {
      Season.winter,
    }, 700);

    Outfit of(
      String name,
      List<ClothingItem> its,
      Set<String> tags, {
      bool fav = false,
    }) {
      final o = Outfit(
        id: newId(),
        name: name,
        itemIds: its.map((e) => e.id).toList(),
        tags: tags,
        favorite: fav,
        createdAt: now.subtract(const Duration(days: 100)),
      );
      outfits.add(o);
      return o;
    }

    final o1 = of('清爽通勤', [oxford, chino, loafer, tote], {'通勤'}, fav: true);
    final o2 = of('周末随性', [whiteTee, jeans, sneaker, tote], {'周末'}, fav: true);
    final o3 = of('法式条纹', [stripe, skirt, loafer], {'约会', '周末'});
    of('风衣季', [knit, jeans, trench, sneaker], {'通勤', '旅行'});
    of('正式会议', [whiteTee, blazer, chino, loafer], {'正式', '通勤'});
    of('夏日碎花', [dress, sneaker, tote], {'约会', '旅行'});
    of('暖冬', [knit, jeans, scarf, loafer], {'周末'});

    // 过去两个月的穿着记录：只集中在常穿的几件上，制造"被遗忘"的衣服
    final rotation = [o1, o2, o1, o2, o3];
    for (var d = 1; d <= 60; d++) {
      if (rnd.nextDouble() < 0.3) continue;
      final o = rotation[rnd.nextInt(rotation.length)];
      logs.add(
        WearLog(
          id: newId(),
          date: dateOnly(now.subtract(Duration(days: d))),
          itemIds: List.of(o.itemIds),
          outfitId: o.id,
        ),
      );
    }
    // 早期偶尔穿过的衣服
    logs.add(
      WearLog(
        id: newId(),
        date: dateOnly(now.subtract(const Duration(days: 75))),
        itemIds: [knit.id, jeans.id, trench.id, sneaker.id],
      ),
    );
    logs.add(
      WearLog(
        id: newId(),
        date: dateOnly(now.subtract(const Duration(days: 120))),
        itemIds: [dress.id, sneaker.id],
      ),
    );
    // 去重：同一天只留一条
    final seen = <DateTime>{};
    logs.retainWhere((l) => seen.add(l.date));
  }
}
