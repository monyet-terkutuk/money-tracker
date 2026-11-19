import 'dart:io';

import 'package:catat_uang_pribadi/core/backup/secure_backup_keys.dart';
import 'package:catat_uang_pribadi/core/backup/secure_snapshot.dart';
import 'package:catat_uang_pribadi/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips secure values and ignores unknown keys', () async {
    final file = File('${Directory.systemTemp.path}/secure-snapshot.db');
    if (await file.exists()) await file.delete();
    final created = AppDatabase(NativeDatabase(file));
    await created.customSelect('SELECT 1').get();
    await created.close();
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });

    writeSecureSnapshot(file, {
      wishlistPrefKey: '[{"name":"sepatu"}]',
      'not-a-real-key': 'skip',
    });

    final snapshot = readSecureSnapshot(file);
    expect(snapshot.present, isTrue);
    expect(snapshot.values, {wishlistPrefKey: '[{"name":"sepatu"}]'});
  });

  test('a database without the snapshot table leaves secure storage alone', () async {
    final file = File('${Directory.systemTemp.path}/secure-snapshot-old.db');
    if (await file.exists()) await file.delete();
    final created = AppDatabase(NativeDatabase(file));
    await created.customSelect('SELECT 1').get();
    await created.close();
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });

    final snapshot = readSecureSnapshot(file);
    expect(snapshot.present, isFalse);
    expect(snapshot.values, isEmpty);
  });
}