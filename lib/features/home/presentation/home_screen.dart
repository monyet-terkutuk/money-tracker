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
import '../domain/monthly_insight.dart';
import '../../presets/domain/presets_provider.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../../transactions/domain/transaction_search.dart';
import '../../transactions/presentation/quick_input_sheet.dart';
import '../../recurring/domain/recurring_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hideBalance = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(monthlySummaryProvider);
    final insightAsync = ref.watch(monthlyInsightProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    ref.listen(recurringPostProvider, (previous, next) {
      final posted = next.valueOrNull ?? 0;
      if (posted > 0 && previous?.valueOrNull != posted) {
        ref.invalidate(transactionListProvider);
        ref.invalidate(monthlySummaryProvider);
        ref.invalidate(monthlyInsightProvider);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(monthlySummaryProvider);
            ref.invalidate(transactionListProvider);
            await ref.read(monthlySummaryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _buildEditorialHeader(context, currentMonth),
              const SizedBox(height: 20),
              summary.when(
                data: (data) => _buildStatementSlab(
                  context,
                  balance: data['balance'] ?? 0,
                  income: data['income'] ?? 0,
                  expense: data['expense'] ?? 0,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: LoadingIndicator(message: 'Memuat buku kas...'),
                ),
                error: (e, _) => _buildErrorBox(context, e.toString()),
              ),
              const SizedBox(height: 16),
              _buildActionStrip(context),
              const SizedBox(height: 14),
              _buildQuickPresetsStrip(context),
              if (insightAsync.valueOrNull != null &&
                  (insightAsync.valueOrNull!.totalExpense > 0 ||
                      insightAsync.valueOrNull!.expenseChangePercent != null)) ...[
                const SizedBox(height: 20),
                _buildCompactInsightCard(context, insightAsync.valueOrNull!),
              ],
              const SizedBox(height: 24),
              _buildLedgerHeader(context),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari catatan, kategori, atau nominal bulan ini',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  isDense: true,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 10),
              transactionsAsync.when(
                data: (transactions) {
                  final categories = categoriesAsync.valueOrNull ?? [];
                  final visible = transactions.where((t) {
                    final cat =
                        categories.where((c) => c.id == t.categoryId).firstOrNull;
                    return matchesLedgerQuery(
                      query: _searchQuery,
                      note: t.note,
                      categoryName: cat?.name ?? '',
                      paymentLabel: paymentMethodLabels[t.paymentMethod] ??
                          t.paymentMethod,
                      amount: t.amount,
                    );
                  }).toList();
                  return _buildLedgerFeed(
                    context,
                    transactions: visible,
                    categories: categories,
                    filtered: _searchQuery.isNotEmpty,
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingIndicator(message: 'Memuat transaksi...'),
                ),
                error: (e, _) => _buildErrorBox(context, e.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialHeader(BuildContext context, DateTime currentMonth) {
    final secondaryText = AppPalette.secondaryTextColor(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BUKU KAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: AppPalette.accent(context),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      formatMonthYear(currentMonth),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderChevron(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      ref.read(currentMonthProvider.notifier).state = DateTime(
                        currentMonth.year,
                        currentMonth.month - 1,
                      );
                    },
                  ),
                  _HeaderChevron(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      ref.read(currentMonthProvider.notifier).state = DateTime(
                        currentMonth.year,
                        currentMonth.month + 1,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tagihan berulang',
          onPressed: () => context.push('/recurring'),
          icon: Icon(
            Icons.event_repeat_rounded,
            size: 21,
            color: secondaryText,
          ),
        ),
        IconButton(
          tooltip: 'Kategori',
          onPressed: () => context.push('/categories'),
          icon: Icon(
            Icons.grid_view_outlined,
            size: 21,
            color: secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatementSlab(
    BuildContext context, {
    required int balance,
    required int income,
    required int expense,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalFlow = income + expense;
    final incomeRatio = totalFlow > 0 ? income / totalFlow : 0.5;
    const accent = AppPalette.burnishedBrassDark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E1A17), Color(0xFF12100E)]
              : const [Color(0xFF231D19), Color(0xFF141210)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppPalette.darkBorder : const Color(0xFF3A2E27),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SALDO BERSIH',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'IDR',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () =>
                              setState(() => _hideBalance = !_hideBalance),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              _hideBalance
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _hideBalance ? 'Rp ••••••••' : formatCurrency(balance),
                    style: const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 3,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (incomeRatio * 100).round().clamp(4, 96),
                        child: Container(color: const Color(0xFF4ADE80)),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: ((1 - incomeRatio) * 100).round().clamp(4, 96),
                        child: Container(
                          color: totalFlow > 0
                              ? accent
                              : Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/transactions?type=income'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PEMASUKAN',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hideBalance
                                    ? 'Rp ••••••'
                                    : formatCurrency(income),
                                style: const TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/transactions?type=expense'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PENGELUARAN',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hideBalance
                                    ? 'Rp ••••••'
                                    : formatCurrency(expense),
                                style: const TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildActionStrip(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QuickInputSheet(),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Input Cepat'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/scan'),
            icon: const Icon(Icons.document_scanner_outlined, size: 18),
            label: const Text('Pindai Struk'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPresetsStrip(BuildContext context) {
    final presets = ref.watch(quickPresetsProvider);
    final secondaryText = AppPalette.secondaryTextColor(context);
    final accent = AppPalette.accent(context);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final preset in presets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: AppPalette.surfaceColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppPalette.borderColor(context)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    final cats =
                        ref.read(categoryListProvider).valueOrNull ?? [];
                    final validCategoryId = cats
                            .where((c) => c.id == preset.categoryId)
                            .map((c) => c.id)
                            .firstOrNull ??
                        cats
                            .where((c) => c.type == preset.type)
                            .map((c) => c.id)
                            .firstOrNull ??
                        preset.categoryId;

                    await ref
                        .read(transactionNotifierProvider.notifier)
                        .addTransaction(
                          type: preset.type,
                          amount: preset.amount,
                          categoryId: validCategoryId,
                          date: DateTime.now(),
                          note: preset.label,
                          paymentMethod: preset.paymentMethod,
                        );
                    ref.invalidate(transactionListProvider);
                    ref.invalidate(monthlySummaryProvider);
                    ref.invalidate(monthlyInsightProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tercatat: ${preset.label}'),
                        ),
                      );
                    }
                  },
                  onLongPress: () => ref
                      .read(quickPresetsProvider.notifier)
                      .removePreset(preset.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 14, color: accent),
                        const SizedBox(width: 5),
                        Text(
                          preset.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Material(
            color: AppPalette.surfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppPalette.borderColor(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showAddPresetDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: secondaryText),
                    const SizedBox(width: 3),
                    Text(
                      'Preset',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPresetDialog(BuildContext context) {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    String paymentMethod = 'cash';
    final cats = ref.read(categoryListProvider).valueOrNull ?? [];
    final expenseCats = cats.where((c) => c.type == 'expense').toList();
    String categoryId =
        expenseCats.isNotEmpty ? expenseCats.first.id : 'cat_food';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Preset 1-Tap'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (mis. Bensin 30rb)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                if (expenseCats.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: expenseCats
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => categoryId = v);
                    },
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Metode'),
                  items: paymentMethods
                      .where((m) => m != 'unknown')
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(paymentMethodLabels[m] ?? m),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => paymentMethod = v);
                  },
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
                final label = labelController.text.trim();
                final amount =
                    int.tryParse(amountController.text.replaceAll('.', '')) ??
                        0;
                if (label.isEmpty || amount <= 0) return;
                await ref.read(quickPresetsProvider.notifier).addPreset(
                      label: label,
                      type: 'expense',
                      amount: amount,
                      categoryId: categoryId,
                      paymentMethod: paymentMethod,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInsightCard(BuildContext context, MonthlyInsight insight) {
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);
    final expenseColor = AppPalette.expenseColor(context);
    final incomeColor = AppPalette.incomeColor(context);
    final change = insight.expenseChangePercent;
    String mask(int v) => _hideBalance ? 'Rp ••••••' : formatCurrency(v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Insight Bulan Ini',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (change > 0 ? expenseColor : incomeColor)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}% vs bln lalu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: change > 0 ? expenseColor : incomeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata / Hari',
                      style: TextStyle(fontSize: 11, color: secondaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mask(insight.dailyBurnRate),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proyeksi Akhir Bulan',
                      style: TextStyle(fontSize: 11, color: secondaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mask(insight.projectedMonthEndExpense),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mutasi Terbaru',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
        ),
        TextButton(
          onPressed: () => context.push('/transactions'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Semua →',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.accent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerFeed(
    BuildContext context, {
    required List<Transaction> transactions,
    required List<Category> categories,
    bool filtered = false,
  }) {
    final secondaryText = AppPalette.secondaryTextColor(context);

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: AppPalette.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filtered ? 'Tidak ada mutasi yang cocok.' : 'Belum ada mutasi bulan ini.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gunakan tombol Catat Transaksi atau Pindai Struk di atas untuk mulai mengisi buku kas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      );
    }

    final recent = transactions.take(6).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderColor(context)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < recent.length; i++) ...[
            _buildLedgerRow(
              context,
              transaction: recent[i],
              categories: categories,
              secondaryText: secondaryText,
            ),
            if (i < recent.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppPalette.borderColor(context),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLedgerRow(
    BuildContext context, {
    required Transaction transaction,
    required List<Category> categories,
    required Color secondaryText,
  }) {
    final isIncome = transaction.type == 'income';
    final color = isIncome
        ? AppPalette.incomeColor(context)
        : AppPalette.expenseColor(context);
    final cat =
        categories.where((c) => c.id == transaction.categoryId).firstOrNull;
    final iconColor = resolveCategoryAccent(cat?.icon, fallback: color);

    return InkWell(
      onTap: () => context.push('/transactions/${transaction.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                resolveCategoryIcon(
                  cat?.icon,
                  categoryName: cat?.name,
                  type: transaction.type,
                ),
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat?.name ?? 'Lainnya',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDate(transaction.date)} · ${paymentMethodLabels[transaction.paymentMethod] ?? transaction.paymentMethod}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: secondaryText,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _hideBalance
                  ? '••••••'
                  : '${isIncome ? '+' : '-'} ${formatCurrency(transaction.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.expenseColor(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Error: $error'),
    );
  }
}

class _HeaderChevron extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderChevron({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: AppPalette.secondaryTextColor(context),
        ),
      ),
    );
  }
}
