import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models.dart';
import 'storage_contract.dart';

class WearLoopStorage implements WardrobeStorage {
  WearLoopStorage._(this._db, this._imageDir);

  final Database _db;
  final Directory _imageDir;

  static const _legacyItems = 'wl_items';
  static const _legacyOutfits = 'wl_outfits';
  static const _legacyLogs = 'wl_logs';
  static const _legacyForgottenDays = 'wl_forgotten_days';
  static const _legacySeeded = 'wl_seeded';

  static Future<WearLoopStorage> open() async {
    final dbRoot = await getDatabasesPath();
    final dbPath = '$dbRoot${Platform.pathSeparator}wearloop.db';
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE items (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE outfits (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE logs (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      },
    );

    final external = await getExternalStorageDirectory();
    final support = await getApplicationSupportDirectory();
    final root = external ?? support;
    final imageDir = Directory(
      '${root.path}${Platform.pathSeparator}wearloop${Platform.pathSeparator}images',
    );
    await imageDir.create(recursive: true);
    return WearLoopStorage._(db, imageDir);
  }

  @override
  Future<StorageSnapshot> load() async {
    final initialized = await _setting('initialized') == '1';
    if (initialized) return _loadDatabase();

    final migrated = await _migrateLegacy();
    if (migrated != null) return migrated;

    return const StorageSnapshot(
      initialized: false,
      items: [],
      outfits: [],
      logs: [],
      forgottenDays: 30,
    );
  }

  Future<StorageSnapshot> _loadDatabase() async {
    List<T> decodeRows<T>(
      List<Map<String, Object?>> rows,
      T Function(Map<String, dynamic>) decode,
    ) => rows
        .map(
          (row) => decode(
            Map<String, dynamic>.from(
              jsonDecode(row['payload']! as String) as Map,
            ),
          ),
        )
        .toList();

    final items = decodeRows(await _db.query('items'), ClothingItem.fromJson);
    final outfits = decodeRows(await _db.query('outfits'), Outfit.fromJson);
    final logs = decodeRows(await _db.query('logs'), WearLog.fromJson);
    final forgottenDays =
        int.tryParse(await _setting('forgottenDays') ?? '') ?? 30;

    return StorageSnapshot(
      initialized: true,
      items: items,
      outfits: outfits,
      logs: logs,
      forgottenDays: forgottenDays,
    );
  }

  Future<StorageSnapshot?> _migrateLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLegacy =
        prefs.getBool(_legacySeeded) == true ||
        prefs.getString(_legacyItems) != null;
    if (!hasLegacy) return null;

    List<Map<String, dynamic>> read(String key) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    final items = read(_legacyItems).map(ClothingItem.fromJson).toList();
    final outfits = read(_legacyOutfits).map(Outfit.fromJson).toList();
    final logs = read(_legacyLogs).map(WearLog.fromJson).toList();
    final forgottenDays = prefs.getInt(_legacyForgottenDays) ?? 30;

    for (final item in items) {
      final legacy = item.imageBase64;
      if (legacy == null || legacy.isEmpty) continue;
      try {
        final bytes = base64Decode(legacy);
        item.imagePath = await saveImage(bytes, item.id);
        item.imageBase64 = null;
      } on FormatException {
        // Keep the legacy payload as a last-resort fallback rather than lose it.
      }
    }

    await saveSnapshot(
      items: items,
      outfits: outfits,
      logs: logs,
      forgottenDays: forgottenDays,
    );

    for (final key in [
      _legacyItems,
      _legacyOutfits,
      _legacyLogs,
      _legacyForgottenDays,
      _legacySeeded,
    ]) {
      await prefs.remove(key);
    }

    return StorageSnapshot(
      initialized: true,
      items: items,
      outfits: outfits,
      logs: logs,
      forgottenDays: forgottenDays,
    );
  }

  @override
  Future<void> saveSnapshot({
    required List<ClothingItem> items,
    required List<Outfit> outfits,
    required List<WearLog> logs,
    required int forgottenDays,
  }) async {
    final itemRows = [
      for (final item in items)
        {'id': item.id, 'payload': jsonEncode(item.toJson())},
    ];
    final outfitRows = [
      for (final outfit in outfits)
        {'id': outfit.id, 'payload': jsonEncode(outfit.toJson())},
    ];
    final logRows = [
      for (final log in logs)
        {'id': log.id, 'payload': jsonEncode(log.toJson())},
    ];

    await _db.transaction((txn) async {
      await txn.delete('items');
      await txn.delete('outfits');
      await txn.delete('logs');

      final batch = txn.batch();
      for (final row in itemRows) {
        batch.insert('items', row);
      }
      for (final row in outfitRows) {
        batch.insert('outfits', row);
      }
      for (final row in logRows) {
        batch.insert('logs', row);
      }
      batch.insert('settings', {
        'key': 'initialized',
        'value': '1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('settings', {
        'key': 'forgottenDays',
        'value': forgottenDays.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<String> saveImage(Uint8List bytes, String itemId) async {
    final safeId = itemId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${_imageDir.path}${Platform.pathSeparator}$safeId.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    final root = _imageDir.absolute.path;
    final absolute = file.absolute.path;
    if (!absolute.startsWith(root)) return;
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> clearImages() async {
    if (await _imageDir.exists()) {
      await _imageDir.delete(recursive: true);
    }
    await _imageDir.create(recursive: true);
  }

  Future<String?> _setting(String key) async {
    final rows = await _db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }
}
