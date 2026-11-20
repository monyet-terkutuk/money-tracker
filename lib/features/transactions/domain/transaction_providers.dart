import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/receipt_lines.dart';
import '../../home/domain/monthly_insight.dart';
import 'category_providers.dart';

final databaseGenerationProvider = StateProvider<int>((ref) => 0);

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.watch(databaseGenerationProvider);
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
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

final monthlyInsightProvider = FutureProvider.autoDispose<MonthlyInsight>((ref) async {
  final month = ref.watch(currentMonthProvider);
  final db = ref.watch(databaseProvider);
  final currentTransactions = await ref.watch(transactionListProvider.future);
  final categories = await ref.watch(categoryListProvider.future);
  final prevMonth = DateTime(month.year, month.month - 1, 1);
  final prevTransactions = await db.getTransactionsByMonth(prevMonth.year, prevMonth.month);

  return computeMonthlyInsight(
    month: month,
    now: DateTime.now(),
    currentTransactions: currentTransactions,
    prevTransactions: prevTransactions,
    categories: categories,
  );
});

final transactionDetailProvider = FutureProvider.autoDispose.family<Transaction?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.getTransactionById(id);
});

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Map<String, List<ReceiptLineInput>> _removedLines = {};

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
    List<ReceiptLineInput> receiptLines = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      final id = const Uuid().v4();
      await _db.transaction(() async {
        await _db.insertTransaction(TransactionsCompanion(
          id: Value(id),
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
        await _db.insertReceiptLines(id, receiptLines);
      });
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
      _removedLines[id] = await _db.receiptLinesFor(id);
      await _db.deleteTransaction(id);
    });
  }

  Future<void> restoreTransaction(Transaction t) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final lines = _removedLines.remove(t.id) ?? const <ReceiptLineInput>[];
      await _db.transaction(() async {
        await _db.insertTransaction(TransactionsCompanion(
          id: Value(t.id),
          type: Value(t.type),
          amount: Value(t.amount),
          categoryId: Value(t.categoryId),
          date: Value(t.date),
          note: Value(t.note),
          paymentMethod: Value(t.paymentMethod),
          receiptImagePath: Value(t.receiptImagePath),
          aiRawResponse: Value(t.aiRawResponse),
          createdAt: Value(t.createdAt),
          updatedAt: Value(t.updatedAt),
        ));
        await _db.insertReceiptLines(t.id, lines);
      });
    });
  }
}

final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  return TransactionNotifier(ref.watch(databaseProvider));
});
