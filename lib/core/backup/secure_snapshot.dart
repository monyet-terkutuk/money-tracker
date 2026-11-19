import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqlite3/sqlite3.dart';

import 'secure_backup_keys.dart';

const backupSecureTable = 'backup_secure_kv';

class SecureSnapshot {
  const SecureSnapshot({required this.present, required this.values});

  final bool present;
  final Map<String, String> values;
}

Future<Map<String, String>> readSecureValues(FlutterSecureStorage storage) async {
  final values = <String, String>{};
  for (final key in secureBackupKeys) {
    final value = await storage.read(key: key);
    if (value != null) values[key] = value;
  }
  return values;
}

Future<void> applySecureSnapshot(
  FlutterSecureStorage storage,
  SecureSnapshot snapshot,
) async {
  if (!snapshot.present) return;
  for (final key in secureBackupKeys) {
    final value = snapshot.values[key];
    if (value == null) {
      await storage.delete(key: key);
    } else {
      await storage.write(key: key, value: value);
    }
  }
}

void writeSecureSnapshot(File file, Map<String, String> values) {
  final db = sqlite3.open(file.path);
  try {
    db.execute(
      'CREATE TABLE IF NOT EXISTS $backupSecureTable ('
      'key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    db.execute('DELETE FROM $backupSecureTable');
    final stmt = db.prepare(
      'INSERT INTO $backupSecureTable (key, value) VALUES (?, ?)',
    );
    try {
      for (final entry in values.entries) {
        if (!secureBackupKeys.contains(entry.key)) continue;
        stmt.execute([entry.key, entry.value]);
      }
    } finally {
      stmt.dispose();
    }
    db.execute('PRAGMA wal_checkpoint(FULL)');
  } finally {
    db.dispose();
  }
}

SecureSnapshot readSecureSnapshot(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    final tables = db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [backupSecureTable],
    );
    if (tables.isEmpty) {
      return const SecureSnapshot(present: false, values: {});
    }
    final rows = db.select('SELECT key, value FROM $backupSecureTable');
    final values = <String, String>{};
    for (final row in rows) {
      final key = row['key'] as String;
      if (!secureBackupKeys.contains(key)) continue;
      values[key] = row['value'] as String;
    }
    return SecureSnapshot(present: true, values: values);
  } finally {
    db.dispose();
  }
}
