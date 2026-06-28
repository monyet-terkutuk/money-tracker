import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Transactions, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Transactions
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  Future<Transaction?> getTransactionById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);

  Future<int> updateTransaction(TransactionsCompanion entry) =>
      (update(transactions)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<int> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<int> totalIncome(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final rows = await (select(transactions)
          ..where((t) => t.type.equals('income') & t.date.isBetweenValues(start, end)))
        .get();
    return rows.fold<int>(0, (sum, t) => sum + t.amount);
  }

  Future<int> totalExpense(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final rows = await (select(transactions)
          ..where((t) => t.type.equals('expense') & t.date.isBetweenValues(start, end)))
        .get();
    return rows.fold<int>(0, (sum, t) => sum + t.amount);
  }

  // Categories
  Future<List<Category>> getAllCategories() => select(categories).get();

  Future<List<Category>> getCategoriesByType(String type) =>
      (select(categories)
            ..where((c) => c.type.equals(type))
            ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .get();

  Future<Category?> getCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion entry) => into(categories).insert(entry);

  Future<int> updateCategory(CategoriesCompanion entry) =>
      (update(categories)..where((c) => c.id.equals(entry.id.value))).write(entry);

  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  Future<int> maxCategorySortOrder() async {
    final rows = await select(categories).get();
    if (rows.isEmpty) return 0;
    return rows.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'catat_uang.db'));
    return NativeDatabase(file);
  });
}
