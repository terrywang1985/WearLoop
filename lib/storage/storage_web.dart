import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'storage_contract.dart';

class WearLoopStorage implements WardrobeStorage {
  WearLoopStorage._(this._prefs);

  final SharedPreferences _prefs;

  static const _kItems = 'wl_items';
  static const _kOutfits = 'wl_outfits';
  static const _kLogs = 'wl_logs';
  static const _kForgottenDays = 'wl_forgotten_days';
  static const _kSeeded = 'wl_seeded';

  static Future<WearLoopStorage> open() async =>
      WearLoopStorage._(await SharedPreferences.getInstance());

  @override
  Future<StorageSnapshot> load() async {
    if (_prefs.getBool(_kSeeded) != true) {
      return const StorageSnapshot(
        initialized: false,
        items: [],
        outfits: [],
        logs: [],
        forgottenDays: 30,
      );
    }

    List<Map<String, dynamic>> read(String key) {
      final raw = _prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return StorageSnapshot(
      initialized: true,
      items: read(_kItems).map(ClothingItem.fromJson).toList(),
      outfits: read(_kOutfits).map(Outfit.fromJson).toList(),
      logs: read(_kLogs).map(WearLog.fromJson).toList(),
      forgottenDays: _prefs.getInt(_kForgottenDays) ?? 30,
    );
  }

  @override
  Future<void> saveSnapshot({
    required List<ClothingItem> items,
    required List<Outfit> outfits,
    required List<WearLog> logs,
    required int forgottenDays,
  }) async {
    await _prefs.setString(
      _kItems,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    await _prefs.setString(
      _kOutfits,
      jsonEncode(outfits.map((e) => e.toJson()).toList()),
    );
    await _prefs.setString(
      _kLogs,
      jsonEncode(logs.map((e) => e.toJson()).toList()),
    );
    await _prefs.setInt(_kForgottenDays, forgottenDays);
    await _prefs.setBool(_kSeeded, true);
  }

  @override
  Future<String?> saveImage(Uint8List bytes, String itemId) async => null;

  @override
  Future<void> deleteImage(String? path) async {}

  @override
  Future<void> clearImages() async {}
}
