import 'dart:io';

import 'package:catat_uang_pribadi/core/database/app_database.dart';
import 'package:catat_uang_pribadi/features/transactions/domain/csv_import.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the export shape and rejects a bad amount', () {
    const raw = '''
Tanggal,Tipe,Jumlah,Kategori,Catatan,Metode Bayar
19 Nov 2026,Pengeluaran,15000,Makanan & Minuman,kopi,Tunai
2026-11-01,Pemasukan,5000000,Gaji,,Debit
20 Nov 2026,Pengeluaran,abc,Transportasi,,QRIS
''';
    final parsed = parseCatatUangCsv(raw);
    expect(parsed.rows, hasLength(2));
    expect(parsed.rows.first.date, DateTime(2026, 11, 19));
    expect(parsed.rows.first.type, 'expense');
    expect(parsed.rows.first.paymentMethod, 'cash');
    expect(parsed.rows[1].type, 'income');
    expect(parsed.rows[1].note, isNull);
    expect(parsed.rejected, hasLength(1));
  });

  test('imports rows once and creates a missing category', () async {
    final file = File('${Directory.systemTemp.path}/csv-import.db');
    if (await file.exists()) await file.delete();
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      if (await file.exists()) await file.delete();
    });

    final first = CsvImportRow(
      date: DateTime(2026, 11, 19),
      type: 'expense',
      amount: 15000,
      categoryName: 'Jajan',
      paymentMethod: 'qris',
      note: 'kopi',
    );
    final once = await db.importCsvRows([first]);
    final twice = await db.importCsvRows([first]);

    expect(once['inserted'], 1);
    expect(once['categories'], 1);
    expect(twice['inserted'], 0);
    expect(twice['skipped'], 1);
    expect(await db.getAllTransactions(), hasLength(1));
    expect(await db.getCategoriesByType('expense'), hasLength(1));
  });
}