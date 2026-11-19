import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/category_providers.dart';
import '../domain/transaction_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String id;

  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tAsync = ref.watch(transactionDetailProvider(id));
    final catsAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return tAsync.when(
      data: (t) {
        if (t == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Transaksi')),
            body: const Center(child: Text('Transaksi tidak ditemukan')),
          );
        }
        final cat = catsAsync.valueOrNull
            ?.where((c) => c.id == t.categoryId)
            .firstOrNull;
        final isIncome = t.type == 'income';
        final accent = isIncome
            ? AppPalette.incomeColor(context)
            : AppPalette.expenseColor(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Transaksi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Transaksi',
                onPressed: () => context.push(
                  '/transactions/${t.id}/edit',
                  extra: t,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppPalette.expenseColor(context),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Transaksi?'),
                      content: const Text('Tindakan ini tidak bisa dibatalkan.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(transactionNotifierProvider.notifier)
                        .deleteTransaction(id);
                    ref.invalidate(transactionListProvider);
                    ref.invalidate(monthlySummaryProvider);
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppPalette.borderColor(context)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isIncome ? 'PEMASUKAN' : 'PENGELUARAN',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${isIncome ? '+' : '-'} ${formatCurrency(t.amount)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: -0.6,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDate(t.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.secondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppPalette.borderColor(context)),
                ),
                child: Column(
                  children: [
                    _detailRow(
                      context,
                      'Kategori',
                      cat?.name ?? 'Lainnya',
                      Icons.category_rounded,
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: AppPalette.borderColor(context),
                    ),
                    _detailRow(
                      context,
                      'Metode Bayar',
                      paymentMethodLabels[t.paymentMethod] ?? 'Lainnya',
                      Icons.account_balance_wallet_rounded,
                    ),
                    if (t.note != null && t.note!.isNotEmpty) ...[
                      Divider(
                        height: 1,
                        indent: 56,
                        color: AppPalette.borderColor(context),
                      ),
                      _detailRow(
                        context,
                        'Catatan',
                        t.note!,
                        Icons.notes_rounded,
                      ),
                    ],
                  ],
                ),
              ),
              if (_parseReceiptItems(t.aiRawResponse).isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Item Struk',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.borderColor(context)),
                  ),
                  child: Column(
                    children: [
                      for (final entry in _parseReceiptItems(t.aiRawResponse).asMap().entries) ...[
                        if (entry.key > 0)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppPalette.borderColor(context),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${entry.value['name'] ?? '-'}'
                                  '${(entry.value['qty'] is num && (entry.value['qty'] as num) > 1) ? ' (${entry.value['qty']}x)' : ''}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (entry.value['price'] is num)
                                Text(
                                  formatCurrency((entry.value['price'] as num).toInt()),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (t.receiptImagePath != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Lampiran Struk',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.borderColor(context)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.file(
                      File(t.receiptImagePath!),
                      fit: BoxFit.contain,
                    ),
                  ),
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

  List<Map<String, dynamic>> _parseReceiptItems(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return (decoded['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final secondaryText = AppPalette.secondaryTextColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
