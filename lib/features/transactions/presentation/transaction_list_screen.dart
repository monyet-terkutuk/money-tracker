import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/category_providers.dart';
import '../domain/transaction_providers.dart';
import '../domain/transaction_search.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final String? filterType;

  const TransactionListScreen({super.key, this.filterType});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String? _activeFilter;
  String? _activeMethodFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.filterType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = AppPalette.secondaryTextColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(formatMonthYear(currentMonth)),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari catatan, kategori, atau nominal...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppPalette.surfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.borderColor(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentedFilterTab(
                      label: 'Semua',
                      selected: _activeFilter == null,
                      activeColor: AppPalette.accent(context),
                      onTap: () => setState(() => _activeFilter = null),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _SegmentedFilterTab(
                      label: 'Pemasukan',
                      selected: _activeFilter == 'income',
                      activeColor: AppPalette.incomeColor(context),
                      onTap: () => setState(() => _activeFilter = 'income'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _SegmentedFilterTab(
                      label: 'Pengeluaran',
                      selected: _activeFilter == 'expense',
                      activeColor: AppPalette.expenseColor(context),
                      onTap: () => setState(() => _activeFilter = 'expense'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: 'Semua Metode',
                    selected: _activeMethodFilter == null,
                    activeColor: AppPalette.accent(context),
                    onTap: () => setState(() => _activeMethodFilter = null),
                  ),
                ),
                for (final m in paymentMethods.where((m) => m != 'unknown'))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterPill(
                      label: paymentMethodLabels[m] ?? m,
                      selected: _activeMethodFilter == m,
                      activeColor: AppPalette.accent(context),
                      onTap: () => setState(
                        () => _activeMethodFilter =
                            _activeMethodFilter == m ? null : m,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 6),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(transactionListProvider.future),
              child: transactionsAsync.when(
                data: (transactions) {
                  final catNames = {
                    for (final c in categoriesAsync.valueOrNull ?? [])
                      c.id: c.name.toLowerCase(),
                  };
                  final filtered = transactions.where((t) {
                    if (_activeFilter != null && t.type != _activeFilter) {
                      return false;
                    }
                    if (_activeMethodFilter != null &&
                        t.paymentMethod != _activeMethodFilter) {
                      return false;
                    }
                    if (!matchesLedgerQuery(
                      query: _searchQuery,
                      note: t.note,
                      categoryName: catNames[t.categoryId] ?? '',
                      paymentLabel:
                          paymentMethodLabels[t.paymentMethod] ?? t.paymentMethod,
                      amount: t.amount,
                    )) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'Belum ada transaksi',
                      subtitle: 'Tambahkan transaksi pertama Anda bulan ini',
                      actionLabel: 'Tambah Transaksi',
                      onAction: () => context.push('/transactions/add'),
                    );
                  }

                  final total = filtered.fold<int>(
                    0,
                    (sum, t) =>
                        sum + (t.type == 'income' ? t.amount : -t.amount),
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.surfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppPalette.borderColor(context),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtered.length} Transaksi',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatCurrency(total.abs()),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _activeFilter == 'income'
                                      ? AppPalette.incomeColor(context)
                                      : _activeFilter == 'expense'
                                          ? AppPalette.expenseColor(context)
                                          : theme.colorScheme.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final t = filtered[index - 1];
                      final cat = categoriesAsync.valueOrNull
                          ?.where((c) => c.id == t.categoryId)
                          .firstOrNull;
                      final isIncome = t.type == 'income';
                      final color = isIncome
                          ? AppPalette.incomeColor(context)
                          : AppPalette.expenseColor(context);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: Key(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) async {
                            final notifier =
                                ref.read(transactionNotifierProvider.notifier);
                            await notifier.deleteTransaction(t.id);
                            ref.invalidate(transactionListProvider);
                            ref.invalidate(monthlySummaryProvider);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Transaksi dihapus'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    await notifier.restoreTransaction(t);
                                    ref.invalidate(transactionListProvider);
                                    ref.invalidate(monthlySummaryProvider);
                                  },
                                ),
                                duration: const Duration(
                                  seconds: undoDeleteDurationSeconds,
                                ),
                              ),
                            );
                          },
                          child: Material(
                            color: AppPalette.surfaceColor(context),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: () =>
                                  context.push('/transactions/${t.id}'),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppPalette.borderColor(context),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(
                                          isDark ? 0.16 : 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        resolveCategoryIcon(
                                          cat?.icon,
                                          categoryName: cat?.name,
                                          type: t.type,
                                        ),
                                        color: color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat?.name ?? 'Lainnya',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${formatDate(t.date)} • ${paymentMethodLabels[t.paymentMethod] ?? t.paymentMethod}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: secondaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${isIncome ? '+' : '-'} ${formatCurrency(t.amount)}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const LoadingIndicator(message: 'Memuat transaksi...'),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedFilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _SegmentedFilterTab({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? activeColor
                    : AppPalette.secondaryTextColor(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? activeColor;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppPalette.accent(context);
    return Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : AppPalette.surfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? color : AppPalette.borderColor(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppPalette.secondaryTextColor(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
