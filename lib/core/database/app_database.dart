import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import '../../features/transactions/domain/csv_import.dart';
import '../../features/recurring/domain/legacy_recurring_rules.dart';
import '../../features/recurring/domain/recurring_schedule.dart';
import 'database_open_gate.dart';
import 'receipt_lines.dart';
import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/receipt_items_table.dart';
import 'tables/recurring_bills_table.dart';
import 'tables/recurring_occurrences_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Transactions,
  Categories,
  RecurringBills,
  RecurringOccurrences,
  ReceiptItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  bool _closed = false;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await super.close();
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(recurringBills);
            await m.createTable(recurringOccurrences);
          }
          if (from < 3) {
            await m.createTable(receiptItems);
            await backfillReceiptItems();
          }
        },
      );

  // Transactions
  Expression<bool> _inMonth($TransactionsTable t, int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end);
  }

  Future<List<Transaction>> getAllTransactions() => select(transactions).get();

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) {
    return (select(transactions)
          ..where((t) => _inMonth(t, year, month))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  Future<Transaction?> getTransactionById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);

  Future<int> updateTransaction(TransactionsCompanion entry) =>
      (update(transactions)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<int> deleteTransaction(String id) {
    return transaction(() async {
      await (delete(receiptItems)..where((r) => r.transactionId.equals(id))).go();
      return (delete(transactions)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> insertReceiptLines(
    String transactionId,
    List<ReceiptLineInput> lines,
  ) async {
    if (lines.isEmpty) return;
    await batch((b) {
      b.insertAll(receiptItems, [
        for (var i = 0; i < lines.length; i++)
          ReceiptItemsCompanion.insert(
            id: const Uuid().v4(),
            transactionId: transactionId,
            name: lines[i].name,
            price: lines[i].price,
            qty: Value(lines[i].qty),
            storeName: Value(lines[i].storeName),
            position: Value(i),
          ),
      ]);
    });
  }

  Future<List<ReceiptLineInput>> receiptLinesFor(String transactionId) async {
    final rows = await (select(receiptItems)
          ..where((r) => r.transactionId.equals(transactionId))
          ..orderBy([(r) => OrderingTerm(expression: r.position)]))
        .get();
    return [
      for (final row in rows)
        ReceiptLineInput(
          name: row.name,
          price: row.price,
          qty: row.qty,
          storeName: row.storeName,
        ),
    ];
  }

  Future<List<StoredReceiptLine>> storedReceiptLines() async {
    final rows = await (select(receiptItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(receiptItems.transactionId),
      ),
    ])
          ..orderBy([
            OrderingTerm(
              expression: transactions.date,
              mode: OrderingMode.desc,
            ),
            OrderingTerm(expression: receiptItems.position),
          ]))
        .get();
    return [
      for (final row in rows)
        StoredReceiptLine(
          name: row.readTable(receiptItems).name,
          price: row.readTable(receiptItems).price,
          qty: row.readTable(receiptItems).qty,
          storeName: row.readTable(receiptItems).storeName ??
              row.readTable(transactions).note ??
              'Toko',
          date: row.readTable(transactions).date,
          transactionId: row.readTable(transactions).id,
        ),
    ];
  }

  Future<void> backfillReceiptItems() async {
    final existing = await select(receiptItems).get();
    final already = existing.map((row) => row.transactionId).toSet();
    final txs = await (select(transactions)
          ..where((t) => t.aiRawResponse.isNotNull()))
        .get();
    for (final tx in txs) {
      if (already.contains(tx.id)) continue;
      await insertReceiptLines(
        tx.id,
        parseStoredReceipt(tx.aiRawResponse, tx.note),
      );
    }
  }

  Future<int> totalIncome(int year, int month) =>
      _totalForType('income', year, month);

  Future<int> totalExpense(int year, int month) =>
      _totalForType('expense', year, month);

  Future<int> _totalForType(String type, int year, int month) async {
    final total = transactions.amount.sum();
    final row = await (selectOnly(transactions)
          ..addColumns([total])
          ..where(
            transactions.type.equals(type) & _inMonth(transactions, year, month),
          ))
        .getSingle();
    return row.read(total) ?? 0;
  }

  /// Income and expense per calendar month, from [start] through the month of [end].
  Future<List<MonthTotal>> totalsBetween(DateTime start, DateTime end) async {
    final localDate =
        transactions.date.modify(const DateTimeModifier.localTime());
    final yearCol = localDate.year;
    final monthCol = localDate.month;
    final total = transactions.amount.sum();
    final rangeStart = DateTime(start.year, start.month);
    final rangeEnd = DateTime(end.year, end.month + 1);
    final rows = await (selectOnly(transactions)
          ..addColumns([yearCol, monthCol, transactions.type, total])
          ..where(
            transactions.date.isBiggerOrEqualValue(rangeStart) &
                transactions.date.isSmallerThanValue(rangeEnd),
          )
          ..groupBy([yearCol, monthCol, transactions.type]))
        .get();

    final byMonth = <String, MonthTotal>{};
    for (final row in rows) {
      final year = row.read(yearCol)!;
      final month = row.read(monthCol)!;
      final key = '$year-$month';
      final current = byMonth[key] ?? MonthTotal(year: year, month: month);
      final amount = row.read(total) ?? 0;
      final type = row.read(transactions.type);
      byMonth[key] = MonthTotal(
        year: year,
        month: month,
        income: type == 'income' ? amount : current.income,
        expense: type == 'expense' ? amount : current.expense,
      );
    }
    return byMonth.values.toList();
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

  Future<List<RecurringBill>> getRecurringBills() {
    return (select(recurringBills)
          ..orderBy([(r) => OrderingTerm(expression: r.dayOfMonth)]))
        .get();
  }

  Future<void> insertRecurringBill(RecurringBillsCompanion entry) =>
      into(recurringBills).insert(entry);

  Future<void> updateRecurringBill(RecurringBillsCompanion entry) =>
      (update(recurringBills)..where((r) => r.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteRecurringBill(String id) async {
    await (delete(recurringOccurrences)..where((o) => o.recurringId.equals(id)))
        .go();
    await (delete(recurringBills)..where((r) => r.id.equals(id))).go();
  }

  Future<int> postDueRecurring({required DateTime through}) async {
    final rules = await (select(recurringBills)
          ..where((r) => r.active.equals(true)))
        .get();
    var posted = 0;
    for (final rule in rules) {
      for (final month in monthsInclusive(rule.startDate, through)) {
        final key = periodKey(month.year, month.month);
        final existing = await (select(recurringOccurrences)
              ..where(
                (o) => o.recurringId.equals(rule.id) & o.periodKey.equals(key),
              ))
            .getSingleOrNull();
        if (existing != null) continue;

        final txId = const Uuid().v4();
        final now = DateTime.now();
        final date = occurrenceDate(month.year, month.month, rule.dayOfMonth);
        await transaction(() async {
          await insertTransaction(TransactionsCompanion(
            id: Value(txId),
            type: Value(rule.type),
            amount: Value(rule.amount),
            categoryId: Value(rule.categoryId),
            date: Value(date),
            note: Value(rule.note?.trim().isNotEmpty == true ? rule.note : rule.name),
            paymentMethod: Value(rule.paymentMethod),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
          await into(recurringOccurrences).insert(RecurringOccurrencesCompanion(
            id: Value(const Uuid().v4()),
            recurringId: Value(rule.id),
            periodKey: Value(key),
            transactionId: Value(txId),
          ));
        });
        posted++;
      }
    }
    return posted;
  }

  Future<Map<String, int>> importCsvRows(List<CsvImportRow> rows) async {
    final categories = await getAllCategories();
    final byKey = <String, Category>{
      for (final category in categories)
        '${category.type}|${category.name.trim().toLowerCase()}': category,
    };
    final existing = await getAllTransactions();
    final seen = <String>{
      for (final t in existing)
        _txKey(
          t.date,
          t.type,
          t.amount,
          t.categoryId,
          t.note,
          t.paymentMethod,
        ),
    };
    var sortOrder = await maxCategorySortOrder();
    var inserted = 0;
    var skipped = 0;
    var createdCategories = 0;

    for (final row in rows) {
      final categoryKey = '${row.type}|${row.categoryName.trim().toLowerCase()}';
      var category = byKey[categoryKey];
      if (category == null) {
        sortOrder += 1;
        final id = const Uuid().v4();
        await insertCategory(CategoriesCompanion(
          id: Value(id),
          name: Value(row.categoryName.trim()),
          icon: const Value('category'),
          type: Value(row.type),
          isDefault: const Value(false),
          sortOrder: Value(sortOrder),
        ));
        category = await getCategoryById(id);
        if (category == null) continue;
        byKey[categoryKey] = category;
        createdCategories++;
      }

      final key = _txKey(
        row.date,
        row.type,
        row.amount,
        category.id,
        row.note,
        row.paymentMethod,
      );
      if (!seen.add(key)) {
        skipped++;
        continue;
      }
      final now = DateTime.now();
      await insertTransaction(TransactionsCompanion(
        id: Value(const Uuid().v4()),
        type: Value(row.type),
        amount: Value(row.amount),
        categoryId: Value(category.id),
        date: Value(row.date),
        note: Value(row.note),
        paymentMethod: Value(row.paymentMethod),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      inserted++;
    }
    return {
      'inserted': inserted,
      'skipped': skipped,
      'categories': createdCategories,
    };
  }

  Future<int> importLegacyRecurringRules(
    List<LegacyRecurringRule> rules,
    DateTime now,
  ) async {
    var imported = 0;
    for (final rule in rules) {
      final existing = await (select(recurringBills)
            ..where((r) => r.id.equals(rule.id)))
          .getSingleOrNull();
      if (existing != null) continue;

      final start = legacyRuleStart(rule, now);
      await insertRecurringBill(RecurringBillsCompanion(
        id: Value(rule.id),
        name: Value(rule.title),
        amount: Value(rule.amount),
        categoryId: Value(rule.categoryId),
        type: Value(rule.type),
        paymentMethod: Value(rule.paymentMethod),
        dayOfMonth: Value(rule.dayOfMonth),
        active: Value(rule.isActive),
        startDate: Value(start),
        createdAt: Value(now),
      ));
      final applied = rule.lastAppliedMonth;
      if (applied != null &&
          applied == periodKey(start.year, start.month)) {
        await into(recurringOccurrences).insert(RecurringOccurrencesCompanion(
          id: Value(const Uuid().v4()),
          recurringId: Value(rule.id),
          periodKey: Value(applied),
          transactionId: const Value(''),
        ));
      }
      imported++;
    }
    return imported;
  }

  Future<int> maxCategorySortOrder() async {
    final rows = await select(categories).get();
    if (rows.isEmpty) return 0;
    return rows.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);
  }
}

class StoredReceiptLine {
  const StoredReceiptLine({
    required this.name,
    required this.price,
    required this.qty,
    required this.storeName,
    required this.date,
    required this.transactionId,
  });

  final String name;
  final int price;
  final int qty;
  final String storeName;
  final DateTime date;
  final String transactionId;
}

class MonthTotal {
  const MonthTotal({
    required this.year,
    required this.month,
    this.income = 0,
    this.expense = 0,
  });

  final int year;
  final int month;
  final int income;
  final int expense;
}

String _txKey(
  DateTime date,
  String type,
  int amount,
  String categoryId,
  String? note,
  String paymentMethod,
) {
  return '${date.year}-${date.month}-${date.day}|$type|$amount|$categoryId|${note ?? ''}|$paymentMethod';
}

Future<File> resolveDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, dbFileName));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    await DatabaseOpenGate.ready;
    final file = await resolveDatabaseFile();
    return NativeDatabase(file);
  });
}
