import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../home/domain/budget_provider.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoryListProvider);
    final txAsync = ref.watch(transactionListProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final budgets = ref.watch(budgetNotifierProvider);
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);

    return catsAsync.when(
      data: (cats) {
        final category = cats.where((c) => c.id == categoryId).firstOrNull;
        if (category == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Kategori')),
            body: const Center(child: Text('Kategori tidak ditemukan')),
          );
        }

        final isIncome = category.type == 'income';
        final fallbackColor = isIncome
            ? AppPalette.incomeColor(context)
            : AppPalette.expenseColor(context);
        final accent =
            resolveCategoryAccent(category.icon, fallback: fallbackColor);
        final icon = resolveCategoryIcon(
          category.icon,
          categoryName: category.name,
          type: category.type,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(category.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  ref.read(currentMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month - 1);
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  ref.read(currentMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month + 1);
                },
              ),
            ],
          ),
          body: txAsync.when(
            data: (allTx) {
              final catTx =
                  allTx.where((t) => t.categoryId == category.id).toList();
              final totalAmount =
                  catTx.fold<int>(0, (sum, t) => sum + t.amount);
              final avgAmount =
                  catTx.isNotEmpty ? (totalAmount / catTx.length).round() : 0;
              final budgetLimit = budgets[category.id];

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceColor(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppPalette.borderColor(context),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(icon, color: accent, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: fallbackColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isIncome ? 'Pemasukan' : 'Pengeluaran',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: fallbackColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatMonthYear(currentMonth),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Total Bulan Ini',
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(totalAmount),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: fallbackColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: AppPalette.borderColor(context),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                label: 'Jumlah Transaksi',
                                value: '${catTx.length}x',
                              ),
                            ),
                            Expanded(
                              child: _StatItem(
                                label: 'Rata-rata / Transaksi',
                                value: formatCurrency(avgAmount),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isIncome) ...[
                    const SizedBox(height: 14),
                    _BudgetCard(
                      category: category,
                      spent: totalAmount,
                      budgetLimit: budgetLimit,
                      onEditBudget: () =>
                          _showBudgetDialog(context, ref, category, budgetLimit),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Transaksi',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${catTx.length} item',
                        style: TextStyle(fontSize: 12, color: secondaryText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (catTx.isEmpty)
                    EmptyState(
                      icon: icon,
                      title: 'Belum ada transaksi',
                      subtitle:
                          'Belum ada catatan di ${category.name} pada ${formatMonthYear(currentMonth)}',
                      actionLabel: 'Catat Sekarang',
                      onAction: () => context.push('/transactions/add'),
                    )
                  else
                    Material(
                      color: AppPalette.surfaceColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: AppPalette.borderColor(context),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final entry in catTx.asMap().entries) ...[
                            if (entry.key > 0)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: AppPalette.borderColor(context),
                              ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                (entry.value.note != null &&
                                        entry.value.note!.isNotEmpty)
                                    ? entry.value.note!
                                    : category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${formatDate(entry.value.date)} · ${paymentMethodLabels[entry.value.paymentMethod] ?? entry.value.paymentMethod}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              ),
                              trailing: Text(
                                '${isIncome ? '+' : '-'}${formatCurrency(entry.value.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: fallbackColor,
                                ),
                              ),
                              onTap: () => context
                                  .push('/transactions/${entry.value.id}'),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => const LoadingIndicator(message: 'Memuat transaksi...'),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/transactions/add'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Catat'),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Detail Kategori')),
        body: const LoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Detail Kategori')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
    int? currentLimit,
  ) {
    final controller = TextEditingController(
      text: formatNumberInput(currentLimit ?? 0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Budget ${category.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Batas Bulanan (Rp)',
            hintText: 'Kosongkan atau 0 untuk hapus',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final parsed =
                  int.tryParse(controller.text.replaceAll('.', '').trim()) ?? 0;
              await ref
                  .read(budgetNotifierProvider.notifier)
                  .setBudget(category.id, parsed);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final secondaryText = AppPalette.secondaryTextColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: secondaryText)),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Category category;
  final int spent;
  final int? budgetLimit;
  final VoidCallback onEditBudget;

  const _BudgetCard({
    required this.category,
    required this.spent,
    required this.budgetLimit,
    required this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);
    final hasBudget = budgetLimit != null && budgetLimit! > 0;
    final ratio = hasBudget ? spent / budgetLimit! : 0.0;
    final barColor = ratio >= 1.0
        ? AppPalette.expenseColor(context)
        : ratio >= 0.8
            ? AppPalette.warningColor(context)
            : AppPalette.incomeColor(context);
    final remaining = hasBudget ? budgetLimit! - spent : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Bulanan',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: onEditBudget,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(hasBudget ? 'Ubah' : 'Atur Budget'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (!hasBudget)
            Text(
              'Belum ada batas bulanan untuk kategori ini.',
              style: TextStyle(fontSize: 12, color: secondaryText),
            )
          else ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatCurrency(spent)} / ${formatCurrency(budgetLimit!)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
                Text(
                  remaining >= 0
                      ? 'Sisa ${formatCurrency(remaining)}'
                      : 'Lebih ${formatCurrency(remaining.abs())}',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                color: barColor,
                backgroundColor: barColor.withValues(alpha: 0.14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
