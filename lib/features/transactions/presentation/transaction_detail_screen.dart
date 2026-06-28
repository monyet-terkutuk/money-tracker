import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/constants.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/transaction_providers.dart';
import '../domain/category_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String id;

  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tAsync = ref.watch(transactionDetailProvider(id));
    final catsAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);

    return tAsync.when(
      data: (t) {
        if (t == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Transaksi')),
            body: const Center(child: Text('Transaksi tidak ditemukan')),
          );
        }
        final cat = catsAsync.valueOrNull?.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => Category(id: '', name: 'Lainnya', icon: 'category', type: t.type, isDefault: false, sortOrder: 0),
        );
        final isIncome = t.type == 'income';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Transaksi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Transaksi?'),
                      content: const Text('Tindakan ini tidak bisa dibatalkan.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(transactionNotifierProvider.notifier).deleteTransaction(id);
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(isIncome ? 'Pemasukan' : 'Pengeluaran',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${isIncome ? '+' : '-'} ${formatCurrency(t.amount)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Kategori', cat?.name ?? 'Lainnya', Icons.category),
              _detailRow('Tanggal', formatDate(t.date), Icons.calendar_today),
              _detailRow('Metode Bayar', paymentMethodLabels[t.paymentMethod] ?? 'Lainnya', Icons.payment),
              if (t.note != null && t.note!.isNotEmpty)
                _detailRow('Catatan', t.note!, Icons.notes),
              if (t.receiptImagePath != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(t.receiptImagePath!), fit: BoxFit.contain),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const LoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }
}
