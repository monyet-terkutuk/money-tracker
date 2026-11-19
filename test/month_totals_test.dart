import 'dart:io';

import 'package:catat_uang_pribadi/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sums a month in SQL and groups a range', () async {
    final file = File('${Directory.systemTemp.path}/month-totals.db');
    if (await file.exists()) await file.delete();
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      if (await file.exists()) await file.delete();
    });

    Future<void> add(String type, int amount, DateTime date) {
      final now = DateTime.now();
      return db.insertTransaction(TransactionsCompanion.insert(
        id: '${type}_${date.month}_$amount',
        type: type,
        amount: amount,
        categoryId: 'cat',
        date: date,
        paymentMethod: 'cash',
        createdAt: now,
        updatedAt: now,
      ));
    }

    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat',
          name: 'Lainnya',
          icon: 'category',
          type: 'expense',
          isDefault: true,
          sortOrder: 1,
        ));
    await add('income', 100, DateTime(2026, 10, 2));
    await add('expense', 40, DateTime(2026, 10, 3));
    await add('expense', 10, DateTime(2026, 11, 1));

    expect(await db.totalIncome(2026, 10), 100);
    expect(await db.totalExpense(2026, 10), 40);
    expect(await db.totalIncome(2026, 11), 0);

    final range = await db.totalsBetween(DateTime(2026, 10), DateTime(2026, 11));
    final october = range.singleWhere((m) => m.month == 10);
    final november = range.singleWhere((m) => m.month == 11);
    expect(october.income, 100);
    expect(october.expense, 40);
    expect(november.expense, 10);
    expect(november.income, 0);
  });
}