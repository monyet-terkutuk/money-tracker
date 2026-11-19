import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/backup/secure_backup_keys.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/domain/transaction_providers.dart';
import 'legacy_recurring_rules.dart';
import 'recurring_schedule.dart';

final recurringListProvider =
    FutureProvider.autoDispose<List<RecurringBill>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getRecurringBills();
});

final recurringPostProvider = FutureProvider.autoDispose<int>((ref) async {
  final viewed = ref.watch(currentMonthProvider);
  final db = ref.watch(databaseProvider);
  const storage = FlutterSecureStorage();
  final legacy = parseLegacyRecurringRules(
    await storage.read(key: recurringRulesPrefKey),
  );
  if (legacy.isNotEmpty) {
    final imported = await db.importLegacyRecurringRules(legacy, DateTime.now());
    if (imported > 0) ref.invalidate(recurringListProvider);
    await storage.delete(key: recurringRulesPrefKey);
  }
  return db.postDueRecurring(
    through: postingHorizon(viewed, DateTime.now()),
  );
});

class RecurringNotifier extends StateNotifier<AsyncValue<void>> {
  RecurringNotifier(this._db) : super(const AsyncData(null));

  final AppDatabase _db;

  Future<void> save({
    String? id,
    required String name,
    required int amount,
    required String categoryId,
    required String type,
    required String paymentMethod,
    required int dayOfMonth,
    String? note,
    bool active = true,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      if (id == null) {
        await _db.insertRecurringBill(RecurringBillsCompanion(
          id: Value(const Uuid().v4()),
          name: Value(name),
          amount: Value(amount),
          categoryId: Value(categoryId),
          type: Value(type),
          paymentMethod: Value(paymentMethod),
          dayOfMonth: Value(dayOfMonth),
          note: Value(note),
          active: Value(active),
          startDate: Value(DateTime(now.year, now.month, now.day)),
          createdAt: Value(now),
        ));
      } else {
        await _db.updateRecurringBill(RecurringBillsCompanion(
          id: Value(id),
          name: Value(name),
          amount: Value(amount),
          categoryId: Value(categoryId),
          type: Value(type),
          paymentMethod: Value(paymentMethod),
          dayOfMonth: Value(dayOfMonth),
          note: Value(note),
          active: Value(active),
        ));
      }
    });
  }

  Future<void> setActive(String id, bool active) async {
    await _db.updateRecurringBill(RecurringBillsCompanion(
      id: Value(id),
      active: Value(active),
    ));
  }

  Future<void> delete(String id) => _db.deleteRecurringBill(id);
}

final recurringNotifierProvider =
    StateNotifierProvider<RecurringNotifier, AsyncValue<void>>((ref) {
  return RecurringNotifier(ref.watch(databaseProvider));
});
