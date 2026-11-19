import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../home/domain/budget_provider.dart';
import '../../home/domain/monthly_insight.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../../wishlist/domain/wishlist_provider.dart';
import '../../pending_income/domain/pending_income_provider.dart';
import '../domain/cashflow_chart_provider.dart';
import 'widgets/cashflow_charts.dart';

class InsightsHubScreen extends ConsumerWidget {
  const InsightsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final insightAsync = ref.watch(monthlyInsightProvider);
    final catsAsync = ref.watch(categoryListProvider);
    final budgets = ref.watch(budgetNotifierProvider);
    final wishlist = ref.watch(wishlistProvider);
    final pendingState = ref.watch(pendingIncomeProvider);
    final cashflowAsync = ref.watch(sixMonthCashflowProvider);
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);

    final waitingWishlistCount =
        wishlist.where((w) => w.status == 'waiting').length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionListProvider);
            ref.invalidate(monthlyInsightProvider);
            await ref.read(monthlyInsightProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANALISIS & ALAT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppPalette.accent(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatMonthYear(currentMonth),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
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
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Asisten Pribadi',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HubToolCard(
                      icon: Icons.hourglass_bottom_rounded,
                      title: 'Wishlist 24j',
                      subtitle: waitingWishlistCount > 0
                          ? '$waitingWishlistCount menunggu'
                          : 'Tahan impulsif',
                      accent: const Color(0xFFD97706),
                      onTap: () => context.push('/wishlist'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HubToolCard(
                      icon: Icons.sell_outlined,
                      title: 'Ingatan Harga',
                      subtitle: 'Cek harga struk',
                      accent: const Color(0xFF0284C7),
                      onTap: () => context.push('/price-memory'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HubToolCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Dompet',
                      subtitle: 'Saldo & transfer',
                      accent: AppPalette.incomeColor(context),
                      onTap: () => context.push('/wallets'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HubToolCard(
                      icon: Icons.autorenew_rounded,
                      title: 'Tagihan Rutin',
                      subtitle: 'Catat berulang',
                      accent: AppPalette.accent(context),
                      onTap: () => context.push('/recurring'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HubToolCard(
                      icon: Icons.savings_outlined,
                      title: 'Target Tabungan',
                      subtitle: 'Dana & impian',
                      accent: AppPalette.warningColor(context),
                      onTap: () => context.push('/goals'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HubToolCard(
                      icon: Icons.grid_view_rounded,
                      title: 'Kategori',
                      subtitle: 'Budget & ikon',
                      accent: AppPalette.secondaryTextColor(context),
                      onTap: () => context.push('/categories'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _HubToolCard(
                icon: Icons.schedule_rounded,
                title: 'Pendapatan Tertunda (Pending)',
                subtitle: pendingState.entries.isEmpty
                    ? 'Catat kerja harian sebelum gaji mingguan cair'
                    : '${pendingState.entries.length} catatan · Belum cair ${formatCurrency(pendingState.totalNet)}',
                accent: AppPalette.accent(context),
                onTap: () => context.push('/pending-income'),
              ),
              const SizedBox(height: 24),
              if (cashflowAsync.valueOrNull != null) ...[
                SixMonthCashflowCard(points: cashflowAsync.valueOrNull!),
                const SizedBox(height: 16),
              ],
              insightAsync.when(
                data: (insight) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (insight.categoryBreakdown.isNotEmpty) ...[
                      ExpenseDonutCard(
                        categoriesSpend: insight.categoryBreakdown,
                        categories: catsAsync.valueOrNull ?? [],
                        totalExpense: insight.totalExpense,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildAnalyticsBody(
                      context,
                      ref,
                      insight: insight,
                      budgets: budgets,
                      categories: catsAsync.valueOrNull ?? [],
                      secondaryText: secondaryText,
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: LoadingIndicator(message: 'Menghitung insight...'),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsBody(
    BuildContext context,
    WidgetRef ref, {
    required MonthlyInsight insight,
    required Map<String, int> budgets,
    required List<Category> categories,
    required Color secondaryText,
  }) {
    final theme = Theme.of(context);
    final expenseColor = AppPalette.expenseColor(context);
    final incomeColor = AppPalette.incomeColor(context);
    final expenseCats = categories.where((c) => c.type == 'expense').toList();
    final catMap = {for (final c in categories) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insight.latteFactor != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_cafe_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deteksi Bocor Halus',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${insight.latteFactor!.count} transaksi kecil (≤ ${formatCurrency(insight.latteFactor!.threshold)}) total ${formatCurrency(insight.latteFactor!.totalAmount)}',
                        style: TextStyle(fontSize: 12, color: secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
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
                    'Pengeluaran & Budget',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (expenseCats.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          _showBudgetDialog(context, ref, expenseCats, budgets),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Atur Budget'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              if (insight.categoryBreakdown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Belum ada pengeluaran bulan ini.',
                    style: TextStyle(fontSize: 13, color: secondaryText),
                  ),
                )
              else ...[
                const SizedBox(height: 10),
                for (final entry in insight.categoryBreakdown.asMap().entries) ...[
                  if (entry.key > 0) const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final item = entry.value;
                      final cat = catMap[item.categoryId];
                      final icon = resolveCategoryIcon(
                        cat?.icon,
                        categoryName: item.categoryName,
                        type: 'expense',
                      );
                      final catColor = resolveCategoryAccent(
                        cat?.icon,
                        fallback: theme.colorScheme.primary,
                      );
                      final limit = budgets[item.categoryId];
                      final ratio = (limit != null && limit > 0)
                          ? item.amount / limit
                          : item.percentage;
                      final barColor = (limit != null && limit > 0)
                          ? (ratio >= 1.0
                              ? expenseColor
                              : ratio >= 0.8
                                  ? Colors.amber.shade700
                                  : incomeColor)
                          : catColor;
                      final rightText = (limit != null && limit > 0)
                          ? '${formatCurrency(item.amount)} / ${formatCurrency(limit)}'
                          : '${(item.percentage * 100).toStringAsFixed(0)}% · ${formatCurrency(item.amount)}';

                      return InkWell(
                        onTap: () => context.push('/categories/${item.categoryId}'),
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, size: 16, color: catColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.categoryName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  rightText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: (limit != null && ratio >= 0.8)
                                        ? barColor
                                        : secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                minHeight: 7,
                                color: barColor,
                                backgroundColor:
                                    barColor.withValues(alpha: 0.14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
        if (insight.paymentMethodBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.surfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.borderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivitas per Metode Bayar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final entry
                    in insight.paymentMethodBreakdown.asMap().entries) ...[
                  if (entry.key > 0)
                    Divider(
                      height: 16,
                      color: AppPalette.borderColor(context),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        paymentMethodLabels[entry.value.method] ??
                            entry.value.method,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.value.net >= 0 ? '+' : '-'}${formatCurrency(entry.value.net.abs())}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: entry.value.net >= 0
                              ? incomeColor
                              : expenseColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    List<Category> expenseCats,
    Map<String, int> budgets,
  ) {
    String selectedId = expenseCats.first.id;
    final controller = TextEditingController(
      text: budgets[selectedId]?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Atur Budget Bulanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: expenseCats
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() {
                    selectedId = v;
                    controller.text = formatNumberInput(budgets[v] ?? 0);
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Batas Bulanan (Rp)',
                  hintText: 'Kosongkan atau 0 untuk hapus',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final parsed =
                    int.tryParse(controller.text.replaceAll('.', '').trim()) ??
                        0;
                await ref
                    .read(budgetNotifierProvider.notifier)
                    .setBudget(selectedId, parsed);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _HubToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryText = AppPalette.secondaryTextColor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.borderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
