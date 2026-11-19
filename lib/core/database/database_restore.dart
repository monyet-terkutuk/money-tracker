import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'app_database.dart';
import 'database_open_gate.dart';

const sqliteHeader = 'SQLite format 3';

bool looksLikeSqlite(List<int> header) {
  if (header.length < sqliteHeader.length) return false;
  final text = String.fromCharCodes(header.take(sqliteHeader.length));
  return text == sqliteHeader;
}

Future<void> assertRestorableBackup(File file) async {
  if (!await file.exists()) {
    throw const BackupRestoreException('File cadangan tidak ditemukan.');
  }
  final length = await file.length();
  if (length < 100) {
    throw const BackupRestoreException('File cadangan kosong atau terlalu kecil.');
  }
  final header = await file.openRead(0, sqliteHeader.length).fold<List<int>>(
    <int>[],
    (bytes, chunk) => bytes..addAll(chunk),
  );
  if (!looksLikeSqlite(header)) {
    throw const BackupRestoreException('File ini bukan database SQLite.');
  }

  Database? probe;
  try {
    probe = sqlite3.open(file.path);
    final rows = probe.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name IN ('transactions', 'categories')",
    );
    final names = rows.map((row) => row['name'] as String).toSet();
    if (!names.contains('transactions') || !names.contains('categories')) {
      throw const BackupRestoreException(
        'Database cadangan tidak berisi tabel transaksi dan kategori.',
      );
    }
    probe.execute('PRAGMA wal_checkpoint(FULL);');
  } on BackupRestoreException {
    rethrow;
  } catch (error) {
    throw BackupRestoreException('Database cadangan tidak bisa dibaca: $error');
  } finally {
    probe?.dispose();
  }
}

Future<void> replaceLiveDatabase(
  AppDatabase live,
  File source, {
  required void Function() onSwapped,
}) async {
  await DatabaseOpenGate.exclusive(() async {
    try {
      await live.customStatement('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}
    await live.close();

    final dest = await resolveDatabaseFile();
    await source.copy(dest.path);
    for (final suffix in const ['-wal', '-shm']) {
      final side = File('${dest.path}$suffix');
      if (await side.exists()) await side.delete();
    }
    onSwapped();
  });
}

class BackupRestoreException implements Exception {
  final String message;
  const BackupRestoreException(this.message);

  @override
  String toString() => message;
}

