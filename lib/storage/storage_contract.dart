import 'dart:typed_data';

import '../models.dart';

class StorageSnapshot {
  const StorageSnapshot({
    required this.initialized,
    required this.items,
    required this.outfits,
    required this.logs,
    required this.forgottenDays,
  });
  final bool initialized;
  final List<ClothingItem> items;
  final List<Outfit> outfits;
  final List<WearLog> logs;
  final int forgottenDays;
}

/// The native SQLite backend is used in production; widget tests can inject
/// the same preferences backend as Web without mocking native SQL channels.
abstract interface class WardrobeStorage {
  Future<StorageSnapshot> load();
  Future<void> saveSnapshot({
    required List<ClothingItem> items,
    required List<Outfit> outfits,
    required List<WearLog> logs,
    required int forgottenDays,
  });
  Future<String?> saveImage(Uint8List bytes, String itemId);
  Future<void> deleteImage(String? path);
  Future<void> clearImages();
}
