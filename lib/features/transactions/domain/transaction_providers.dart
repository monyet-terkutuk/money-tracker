import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final currentMonthProvider = StateProvider.autoDispose<DateTime>((ref) => DateTime.now());

final transactionListProvider = FutureProvider.autoDispose<List<Transaction>>((ref) {
  final month = ref.watch(currentMonthProvider);
  final db = ref.watch(databaseProvider);
  return db.getTransactionsByMonth(month.year, month.month);
});

final monthlySummaryProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  final month = ref.watch(currentMonthProvider);
  final db = ref.watch(databaseProvider);
  return Future.wait([
    db.totalIncome(month.year, month.month),
    db.totalExpense(month.year, month.month),
  ]).then((results) => {
    'income': results[0],
    'expense': results[1],
    'balance': results[0] - results[1],
  });
});

final transactionDetailProvider = FutureProvider.autoDispose.family<Transaction?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.getTransactionById(id);
});

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  TransactionNotifier(this._db) : super(const AsyncData(null));

  Future<void> addTransaction({
    required String type,
    required int amount,
    required String categoryId,
    required DateTime date,
    String? note,
    String paymentMethod = 'unknown',
    String? receiptImagePath,
    String? aiRawResponse,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      await _db.insertTransaction(TransactionsCompanion(
        id: Value(const Uuid().v4()),
        type: Value(type),
        amount: Value(amount),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
        paymentMethod: Value(paymentMethod),
        receiptImagePath: Value(receiptImagePath),
        aiRawResponse: Value(aiRawResponse),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    });
  }

  Future<void> updateTransaction({
    required String id,
    String? type,
    int? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    String? paymentMethod,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final existing = await _db.getTransactionById(id);
      if (existing == null) return;
      await _db.updateTransaction(TransactionsCompanion(
        id: Value(id),
        type: Value(type ?? existing.type),
        amount: Value(amount ?? existing.amount),
        categoryId: Value(categoryId ?? existing.categoryId),
        date: Value(date ?? existing.date),
        note: Value(note ?? existing.note),
        paymentMethod: Value(paymentMethod ?? existing.paymentMethod),
        receiptImagePath: Value(existing.receiptImagePath),
        aiRawResponse: Value(existing.aiRawResponse),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db.deleteTransaction(id);
    });
  }
}

final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  return TransactionNotifier(ref.watch(databaseProvider));
});
