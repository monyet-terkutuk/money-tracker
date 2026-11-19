import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/backup/secure_snapshot.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_restore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../goals/domain/savings_goals_provider.dart';
import '../../home/domain/budget_provider.dart';
import '../../pending_income/domain/pending_income_provider.dart';
import '../../presets/domain/presets_provider.dart';
import '../../recurring/domain/recurring_providers.dart';
import '../../transactions/domain/csv_import.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../../wallets/domain/wallets_provider.dart';
import '../../wishlist/domain/wishlist_provider.dart';
import '../../security/domain/pin_lock_provider.dart';
import '../../security/presentation/pin_lock_screen.dart';
import '../domain/ai_provider_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiConfigAsync = ref.watch(aiConfigProvider);
    final aiConfig = aiConfigAsync.valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = AppPalette.secondaryTextColor(context);

    final hasKey = aiConfig?.apiKey != null && aiConfig!.apiKey!.isNotEmpty;
    final keyPreview = hasKey && aiConfig.apiKey!.length >= 4
        ? '••••${aiConfig.apiKey!.substring(aiConfig.apiKey!.length - 4)}'
        : (hasKey ? 'Tersimpan' : 'Belum diatur');

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('AI & INTEGRASI'),
          const SizedBox(height: 8),
          Material(
            color: AppPalette.surfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppPalette.borderColor(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: _SettingsIcon(
                icon: Icons.auto_awesome_rounded,
                color: AppPalette.accent(context),
                isDark: isDark,
              ),
              title: Text(
                'Provider AI · ${aiConfig?.label ?? 'DeepSeek'}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '${aiConfig?.model ?? 'deepseek-chat'} · $keyPreview',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              trailing: const Icon(Icons.edit_outlined, size: 20),
              onTap: () => _showAiConfigDialog(context, ref, aiConfig),
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel('KATEGORI'),
          const SizedBox(height: 8),
          Material(
            color: AppPalette.surfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppPalette.borderColor(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: _SettingsIcon(
                icon: Icons.category_outlined,
                color: theme.colorScheme.primary,
                isDark: isDark,
              ),
              title: const Text(
                'Kelola Kategori',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Tambah, ubah, atau hapus kategori transaksi',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/categories'),
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel('DATA & CADANGAN'),
          const SizedBox(height: 8),
          Material(
            color: AppPalette.surfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppPalette.borderColor(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: _SettingsIcon(
                    icon: Icons.file_download_outlined,
                    color: AppPalette.incomeColor(context),
                    isDark: isDark,
                  ),
                  title: const Text(
                    'Export CSV',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Ekspor seluruh transaksi ke file CSV',
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _exportCsv(ref, context),
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: AppPalette.borderColor(context),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: _SettingsIcon(
                    icon: Icons.file_upload_outlined,
                    color: AppPalette.incomeColor(context),
                    isDark: isDark,
                  ),
                  title: const Text(
                    'Impor CSV',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Masukkan transaksi dari file ekspor aplikasi ini',
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _importCsv(ref, context),
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: AppPalette.borderColor(context),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: _SettingsIcon(
                    icon: Icons.backup_outlined,
                    color: theme.colorScheme.primary,
                    isDark: isDark,
                  ),
                  title: const Text(
                    'Backup Database',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Database plus dompet, target, wishlist, dan budget',
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _backupDatabase(context, ref),
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: AppPalette.borderColor(context),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: _SettingsIcon(
                    icon: Icons.restore_outlined,
                    color: theme.colorScheme.error,
                    isDark: isDark,
                  ),
                  title: const Text(
                    'Restore Backup',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Ganti data saat ini dengan file cadangan .db',
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _restoreDatabase(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel('TAMPILAN'),
          const SizedBox(height: 8),
          Material(
            color: AppPalette.surfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppPalette.borderColor(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: const Text(
                'Mode Gelap',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Tema gelap Obsidian & Warm Copper',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              secondary: _SettingsIcon(
                icon: Icons.dark_mode_outlined,
                color: AppPalette.accent(context),
                isDark: isDark,
              ),
              value: isDark,
              onChanged: (v) {
                ref.read(darkModeProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('KEAMANAN'),
          const SizedBox(height: 8),
          _PinLockTile(isDark: isDark),
        ],
      ),
    );
  }

  void _showAiConfigDialog(
    BuildContext context,
    WidgetRef ref,
    AiProviderConfig? current,
  ) {
    AiProviderPreset selectedPreset =
        current?.preset ?? AiProviderPreset.deepseek;
    final urlController = TextEditingController(
      text: current?.apiUrl ?? aiProviderPresets[selectedPreset]!.defaultUrl,
    );
    final modelController = TextEditingController(
      text: current?.model ?? aiProviderPresets[selectedPreset]!.defaultModel,
    );
    final keyController = TextEditingController(text: current?.apiKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Pengaturan Provider AI'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AiProviderPreset>(
                  initialValue: selectedPreset,
                  decoration: const InputDecoration(labelText: 'Provider'),
                  items: AiProviderPreset.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(aiProviderPresets[p]!.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final info = aiProviderPresets[v]!;
                    setDialogState(() {
                      selectedPreset = v;
                      if (v != AiProviderPreset.custom) {
                        urlController.text = info.defaultUrl;
                        modelController.text = info.defaultModel;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Model',
                    hintText: 'deepseek-chat / grok-3-mini / gemini-2.5-flash',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint URL',
                    hintText: 'https://.../v1/chat/completions',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: aiProviderPresets[selectedPreset]!.keyHint,
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await AiConfigStorage.save(
                  preset: selectedPreset,
                  apiUrl: urlController.text,
                  model: modelController.text,
                  apiKey: keyController.text,
                );
                ref.invalidate(aiConfigProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
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
          cats
                  .where((c) => c.id == t.categoryId)
                  .map((c) => c.name)
                  .firstOrNull ??
              'Lainnya',
          t.note ?? '',
          paymentMethodLabels[t.paymentMethod] ?? t.paymentMethod,
        ],
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'catat_uang_export.csv'));
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export Catat Uang Pribadi',
    );
  }

  Future<void> _importCsv(WidgetRef ref, BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;

    try {
      final raw = await File(path).readAsString();
      final parsed = parseCatatUangCsv(raw);
      if (parsed.rows.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                parsed.rejected.isEmpty
                    ? 'Tidak ada baris transaksi.'
                    : parsed.rejected.first,
              ),
            ),
          );
        }
        return;
      }
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Impor transaksi?'),
          content: Text(
            '${parsed.rows.length} baris siap dimasukkan. '
            '${parsed.rejected.length} baris dilewati. '
            'Transaksi yang sama persis tidak digandakan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Impor'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      final stats = await ref.read(databaseProvider).importCsvRows(parsed.rows);
      _invalidateRestoredState(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${stats['inserted']} masuk, ${stats['skipped']} sudah ada, '
              '${stats['categories']} kategori baru.',
            ),
          ),
        );
      }
    } on CsvImportException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impor gagal: $error')),
        );
      }
    }
  }

  Future<void> _restoreDatabase(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan cadangan?'),
        content: const Text(
          'Transaksi, kategori, serta data secure storage yang ada di file cadangan akan mengganti data di perangkat ini. Cadangan lama yang hanya berisi database tidak menghapus dompet atau wishlist. Langkah ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final incoming = File(p.join(dir.path, 'catat_uang_restore_incoming.db'));
    try {
      await File(path).copy(incoming.path);
      await assertRestorableBackup(incoming);
      final snapshot = readSecureSnapshot(incoming);
      await replaceLiveDatabase(
        ref.read(databaseProvider),
        incoming,
        onSwapped: () {
          ref.read(databaseGenerationProvider.notifier).state++;
        },
      );
      await applySecureSnapshot(const FlutterSecureStorage(), snapshot);
      await ref
          .read(databaseProvider)
          .customStatement('DROP TABLE IF EXISTS $backupSecureTable');
      _invalidateRestoredState(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadangan berhasil dipulihkan')),
        );
      }
    } on BackupRestoreException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore gagal: $error')),
        );
      }
    } finally {
      if (await incoming.exists()) await incoming.delete();
    }
  }

  Future<void> _backupDatabase(BuildContext context, WidgetRef ref) async {
    final live = ref.read(databaseProvider);
    try {
      await live.customStatement('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}
    final dbFile = await resolveDatabaseFile();
    if (!await dbFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database belum tersedia')),
        );
      }
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final copy = File(p.join(dir.path, 'catat_uang_backup.db'));
    await dbFile.copy(copy.path);
    final values = await readSecureValues(const FlutterSecureStorage());
    writeSecureSnapshot(copy, values);

    final downloads = Directory('/storage/emulated/0/Download');
    if (await downloads.exists()) {
      await copy.copy(p.join(downloads.path, 'catat_uang_backup.db'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup berhasil disimpan ke Downloads')),
        );
      }
    } else {
      await Share.shareXFiles(
        [XFile(copy.path)],
        text: 'Backup Catat Uang Pribadi',
      );
    }
  }
}

void _invalidateRestoredState(WidgetRef ref) {
  ref.invalidate(transactionListProvider);
  ref.invalidate(monthlySummaryProvider);
  ref.invalidate(monthlyInsightProvider);
  ref.invalidate(categoryListProvider);
  ref.invalidate(budgetNotifierProvider);
  ref.invalidate(walletsNotifierProvider);
  ref.invalidate(savingsGoalsProvider);
  ref.invalidate(pendingIncomeProvider);
  ref.invalidate(quickPresetsProvider);
  ref.invalidate(wishlistProvider);
  ref.invalidate(pinLockProvider);
  ref.invalidate(recurringListProvider);
  ref.invalidate(recurringPostProvider);
  ref.invalidate(darkModeProvider);
  ref.invalidate(aiConfigProvider);
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: AppPalette.secondaryTextColor(context),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SettingsIcon({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _PinLockTile extends ConsumerWidget {
  final bool isDark;

  const _PinLockTile({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinLockProvider);
    final secondaryText = AppPalette.secondaryTextColor(context);

    return Material(
      color: AppPalette.surfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppPalette.borderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: const Text(
          'Kunci PIN (4 Digit)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          pinState.hasPin ? 'Aktif saat aplikasi dibuka' : 'Belum diaktifkan',
          style: TextStyle(color: secondaryText, fontSize: 12),
        ),
        secondary: _SettingsIcon(
          icon: Icons.lock_outline_rounded,
          color: AppPalette.accent(context),
          isDark: isDark,
        ),
        value: pinState.hasPin,
        onChanged: (enable) async {
          if (enable) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PinLockScreen(isSetupMode: true),
              ),
            );
          } else {
            await ref.read(pinLockProvider.notifier).disablePin();
          }
        },
      ),
    );
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
