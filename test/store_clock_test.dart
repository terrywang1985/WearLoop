import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/models.dart';
import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:wearloop/store.dart';

void main() {
  test(
    'injected clock keeps demo data, daily records and idle days consistent',
    () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 10, 29, 12);
      final store = WardrobeStore(
        storageFactory: preferences.WearLoopStorage.open,
        clock: () => now,
      );
      await store.load();
      expect(store.now, now);
      expect(store.items.every((item) => item.createdAt.isBefore(now)), isTrue);
      expect(store.newId(), isNot(store.newId()));
      final item = store.items.first;
      store.logWear(now, [item.id]);
      expect(store.todayLog?.date, dateOnly(now));
      expect(store.idleDays(item), 0);
      now = now.add(const Duration(days: 1));
      expect(store.todayLog, isNull);
      expect(store.idleDays(item), 1);
      expect(store.streak, greaterThanOrEqualTo(1));
    },
  );
}
