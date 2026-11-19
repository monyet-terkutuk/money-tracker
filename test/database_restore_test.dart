import 'dart:io';

import 'package:catat_uang_pribadi/core/database/app_database.dart';
import 'package:catat_uang_pribadi/core/database/database_restore.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects a file that is not a sqlite database', () {
    expect(looksLikeSqlite('not a database'.codeUnits), isFalse);
    expect(looksLikeSqlite('SQLite format 3'.codeUnits), isTrue);
  });

  test('accepts a database that has the ledger tables', () async {
    final file = File('${Directory.systemTemp.path}/ledger-ok.db');
    if (await file.exists()) await file.delete();
    final created = AppDatabase(NativeDatabase(file));
    await created.customSelect('SELECT 1').get();
    await created.close();
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });

    await expectLater(assertRestorableBackup(file), completes);
  });

  test('assertRestorableBackup rejects plain text', () async {
    final file = File('${Directory.systemTemp.path}/not-a-ledger.txt');
    await file.writeAsString('hello backup ${'x' * 120}');
    addTearDown(file.delete);
    expect(
      assertRestorableBackup(file),
      throwsA(
        isA<BackupRestoreException>().having(
          (e) => e.message,
          'message',
          'File ini bukan database SQLite.',
        ),
      ),
    );
  });
}
