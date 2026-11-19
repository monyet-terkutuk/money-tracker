import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../domain/recurring_providers.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(recurringListProvider);
    final categories = ref.watch(categoryListProvider).valueOrNull ?? [];

    final hasItems = (bills.valueOrNull ?? []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan Berulang')),
      floatingActionButton: hasItems
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, ref, categories),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            )
          : null,
      body: bills.when(
        loading: () => const LoadingIndicator(message: 'Memuat tagihan...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.event_repeat_rounded,
              title: 'Belum ada tagihan berulang',
              subtitle:
                  'Listrik, sewa, atau gaji dicatat otomatis setiap bulan.',
              actionLabel: 'Tambah Tagihan',
              onAction: () => _edit(context, ref, categories),
            );
          }

          final activeBills = items.where((b) => b.active).toList();
          final monthlyExpense = activeBills
              .where((b) => b.type == 'expense')
              .fold<int>(0, (s, b) => s + b.amount);
          final monthlyIncome = activeBills
              .where((b) => b.type == 'income')
              .fold<int>(0, (s, b) => s + b.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              _RecurringSummaryCard(
                activeCount: activeBills.length,
                monthlyExpense: monthlyExpense,
                monthlyIncome: monthlyIncome,
              ),
              const SizedBox(height: 18),
              Text(
                'Daftar Jadwal (${items.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < items.length; i++) ...[
                _BillTile(
                  bill: items[i],
                  category: categories
                      .where((c) => c.id == items[i].categoryId)
                      .firstOrNull,
                  onTap: () =>
                      _edit(context, ref, categories, existing: items[i]),
                  onToggle: (active) async {
                    await ref
                        .read(recurringNotifierProvider.notifier)
                        .setActive(items[i].id, active);
                    ref.invalidate(recurringListProvider);
                    ref.invalidate(recurringPostProvider);
                  },
                  onDelete: () async {
                    await ref
                        .read(recurringNotifierProvider.notifier)
                        .delete(items[i].id);
                    ref.invalidate(recurringListProvider);
                  },
                ),
                if (i < items.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories, {
    RecurringBill? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BillForm(existing: existing, categories: categories),
    );
    if (saved == true) {
      ref.invalidate(recurringListProvider);
      ref.invalidate(recurringPostProvider);
      ref.invalidate(transactionListProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(monthlyInsightProvider);
    }
  }
}

class _RecurringSummaryCard extends StatelessWidget {
  final int activeCount;
  final int monthlyExpense;
  final int monthlyIncome;

  const _RecurringSummaryCard({
    required this.activeCount,
    required this.monthlyExpense,
    required this.monthlyIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.charcoalInk,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppPalette.burnishedBrassDark.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTIMASI RUTIN / BULAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '$activeCount aktif',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.burnishedBrassDark,
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
                      'PENGELUARAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(monthlyExpense),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF87171),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PEMASUKAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(monthlyIncome),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4ADE80),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({
    required this.bill,
    required this.category,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringBill bill;
  final Category? category;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final secondary = AppPalette.secondaryTextColor(context);
    final isIncome = bill.type == 'income';
    final amountColor = isIncome
        ? AppPalette.incomeColor(context)
        : AppPalette.expenseColor(context);
    final iconColor = resolveCategoryAccent(
      category?.icon,
      fallback: amountColor,
    );
    final icon = resolveCategoryIcon(
      category?.icon,
      categoryName: category?.name,
      type: bill.type,
    );

    return Opacity(
      opacity: bill.active ? 1.0 : 0.58,
      child: Material(
        color: AppPalette.surfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppPalette.borderColor(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tgl ${bill.dayOfMonth} · ${category?.name ?? 'Lainnya'} · ${paymentMethodLabels[bill.paymentMethod] ?? bill.paymentMethod}',
                        style: TextStyle(color: secondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isIncome ? '+' : '-'} ${formatCurrency(bill.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: amountColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: bill.active, onChanged: onToggle),
                IconButton(
                  tooltip: 'Hapus jadwal',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillForm extends ConsumerStatefulWidget {
  const _BillForm({required this.categories, this.existing});

  final List<Category> categories;
  final RecurringBill? existing;

  @override
  ConsumerState<_BillForm> createState() => _BillFormState();
}

class _BillFormState extends ConsumerState<_BillForm> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _type;
  late String _categoryId;
  late String _method;
  late int _day;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _amount = TextEditingController(
      text: existing == null ? '' : formatNumberInput(existing.amount),
    );
    _note = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? 'expense';
    _method = existing?.paymentMethod ?? 'cash';
    final today = DateTime.now().day;
    _day = existing?.dayOfMonth ?? (today > 28 ? 28 : today);
    _categoryId = existing?.categoryId ?? _firstCategory(_type);
  }

  String _firstCategory(String type) {
    return widget.categories
            .where((c) => c.type == type)
            .map((c) => c.id)
            .firstOrNull ??
        '';
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.categories.where((c) => c.type == _type).toList();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    final activeColor = _type == 'income'
        ? AppPalette.incomeColor(context)
        : AppPalette.expenseColor(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Tagihan Baru' : 'Ubah Tagihan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPalette.borderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeTab(
                        label: 'Pengeluaran',
                        selected: _type == 'expense',
                        activeColor: AppPalette.expenseColor(context),
                        onTap: () => setState(() {
                          _type = 'expense';
                          _categoryId = _firstCategory(_type);
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _TypeTab(
                        label: 'Pemasukan',
                        selected: _type == 'income',
                        activeColor: AppPalette.incomeColor(context),
                        onTap: () => setState(() {
                          _type = 'income';
                          _categoryId = _firstCategory(_type);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nama Jadwal',
                  hintText: 'Mis. Internet, Sewa, Gaji',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  hintText: '0',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: options.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in options)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _categoryId = value ?? ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _day,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Tiap Bulan',
                      ),
                      items: [
                        for (var day = 1; day <= 31; day++)
                          DropdownMenuItem(
                            value: day,
                            child: Text('Tanggal $day'),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _day = value ?? _day),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _method,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Metode Bayar'),
                      items: [
                        for (final method in paymentMethods)
                          DropdownMenuItem(
                            value: method,
                            child: Text(
                              paymentMethodLabels[method] ?? method,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _method = value ?? _method),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration:
                    const InputDecoration(labelText: 'Catatan (opsional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppPalette.expenseColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _save,
                child: const Text('Simpan Jadwal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = parseFormattedAmount(_amount.text) ?? 0;
    if (_name.text.trim().isEmpty || amount <= 0 || _categoryId.isEmpty) {
      setState(() => _error = 'Nama, nominal, dan kategori wajib diisi.');
      return;
    }
    await ref.read(recurringNotifierProvider.notifier).save(
          id: widget.existing?.id,
          name: _name.text.trim(),
          amount: amount,
          categoryId: _categoryId,
          type: _type,
          paymentMethod: _method,
          dayOfMonth: _day,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          active: widget.existing?.active ?? true,
        );
    if (mounted) Navigator.pop(context, true);
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeColor.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
