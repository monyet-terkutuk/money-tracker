import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../transactions/domain/transaction_providers.dart';

final apiKeyProvider = FutureProvider.autoDispose<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return storage.read(key: apiKeyPrefKey);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKeyAsync = ref.watch(apiKeyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.key),
              title: const Text('API Key DeepSeek'),
              subtitle: Text(
                apiKeyAsync.valueOrNull != null && apiKeyAsync.valueOrNull!.isNotEmpty
                    ? '••••${apiKeyAsync.valueOrNull!.substring(apiKeyAsync.valueOrNull!.length - 4)}'
                    : 'Belum diatur',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () => _showApiKeyDialog(context, ref),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export CSV'),
              subtitle: const Text('Ekspor transaksi ke file CSV'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportCsv(ref, context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup Database'),
              subtitle: const Text('Salin database ke folder Downloads'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _backupDatabase(context),
            ),
          ),
          const Divider(),
          Card(
            child: SwitchListTile(
              title: const Text('Mode Gelap'),
              subtitle: const Text('Gunakan tema gelap'),
              secondary: const Icon(Icons.dark_mode),
              value: theme.brightness == Brightness.dark,
              onChanged: (v) {
                ref.read(darkModeProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key DeepSeek'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'sk-...',
            labelText: 'API Key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              const storage = FlutterSecureStorage();
              await storage.write(key: apiKeyPrefKey, value: controller.text);
              Navigator.pop(ctx);
              ref.invalidate(apiKeyProvider);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(WidgetRef ref, BuildContext context) async {
    final db = ref.read(databaseProvider);
    final transactions = await db.getAllTransactions();
    final cats = await db.getAllCategories();

    final rows = <List<String>>[
      ['Tanggal', 'Tipe', 'Jumlah', 'Kategori', 'Catatan', 'Metode Bayar'],
      for (final t in transactions)
        [
          formatDate(t.date),
          t.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
          t.amount.toString(),
          cats.where((c) => c.id == t.categoryId).map((c) => c.name).firstOrNull ?? 'Lainnya',
          t.note ?? '',
          paymentMethodLabels[t.paymentMethod] ?? t.paymentMethod,
        ],
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'catat_uang_export.csv'));
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Export Catat Uang Pribadi');
  }

  Future<void> _backupDatabase(BuildContext context) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dir.path, dbFileName));
    if (!await dbFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database belum tersedia')),
        );
      }
      return;
    }
    final downloads = Directory('/storage/emulated/0/Download');
    if (await downloads.exists()) {
      await dbFile.copy(p.join(downloads.path, 'catat_uang_backup.db'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup berhasil disimpan ke Downloads')),
        );
      }
    } else {
      await Share.shareXFiles([XFile(dbFile.path)], text: 'Backup Catat Uang Pribadi');
    }
  }
}

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final value = await _storage.read(key: darkModePrefKey);
    if (value != null) {
      state = value == 'true';
    }
  }

  Future<void> toggle() async {
    state = !state;
    await _storage.write(key: darkModePrefKey, value: state.toString());
  }
}
