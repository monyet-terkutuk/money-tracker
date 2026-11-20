import 'dart:io';

import 'package:catat_uang_pribadi/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backfill copies receipt JSON into receipt_items once', () async {
    final file = File('${Directory.systemTemp.path}/receipt-lines.db');
    if (await file.exists()) await file.delete();
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      if (await file.exists()) await file.delete();
    });

    final now = DateTime(2026, 11, 19);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat',
          name: 'Lainnya',
          icon: 'category',
          type: 'expense',
          isDefault: true,
          sortOrder: 1,
        ));
    await db.insertTransaction(TransactionsCompanion.insert(
      id: 't1',
      type: 'expense',
      amount: 45000,
      categoryId: 'cat',
      date: now,
      paymentMethod: 'qris',
      note: const Value('Catatan'),
      aiRawResponse: const Value(
        '{"store_name":"Kopi Kenangan","items":[{"name":"Kopi Susu","price":22000,"qty":2}]}',
      ),
      createdAt: now,
      updatedAt: now,
    ));

    await db.backfillReceiptItems();
    await db.backfillReceiptItems();

    final lines = await db.storedReceiptLines();
    expect(lines, hasLength(1));
    expect(lines.single.name, 'Kopi Susu');
    expect(lines.single.storeName, 'Kopi Kenangan');
    expect(lines.single.qty, 2);
  });
}
