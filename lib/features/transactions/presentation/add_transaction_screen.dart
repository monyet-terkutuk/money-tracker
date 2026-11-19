import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/category_providers.dart';
import '../domain/transaction_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;
  final Transaction? existingTransaction;

  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.existingTransaction,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _type;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _type = existing.type;
      _amountController.text = formatNumberInput(existing.amount);
      _selectedCategoryId = existing.categoryId;
      _selectedDate = existing.date;
      _paymentMethod = existing.paymentMethod;
      _noteController.text = existing.note ?? '';
    } else {
      _type = widget.initialType ?? 'expense';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(
      _type == 'income' ? incomeCategoriesProvider : expenseCategoriesProvider,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = _type == 'income'
        ? AppPalette.incomeColor(context)
        : AppPalette.expenseColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTransaction != null
              ? 'Edit Transaksi'
              : 'Tambah ${_type == 'income' ? 'Pemasukan' : 'Pengeluaran'}',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppPalette.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
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
                        _selectedCategoryId = null;
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
                        _selectedCategoryId = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppPalette.surfaceColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppPalette.borderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JUMLAH NOMINAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppPalette.secondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: activeColor,
                      ),
                      hintText: '0',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Masukkan jumlah';
                      final n = parseFormattedAmount(v);
                      if (n == null || n <= 0) return 'Jumlah tidak valid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Kategori',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            categoriesAsync.when(
              data: (cats) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((cat) {
                  final selected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    avatar: Icon(
                      resolveCategoryIcon(
                        cat.icon,
                        categoryName: cat.name,
                        type: cat.type,
                      ),
                      size: 16,
                      color: selected
                          ? activeColor
                          : AppPalette.secondaryTextColor(context),
                    ),
                    label: Text(cat.name),
                    selected: selected,
                    selectedColor: activeColor.withOpacity(isDark ? 0.22 : 0.14),
                    labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? activeColor
                          : theme.colorScheme.onSurface,
                    ),
                    side: BorderSide(
                      color: selected
                          ? activeColor
                          : AppPalette.borderColor(context),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedCategoryId = cat.id),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 20),
            Material(
              color: AppPalette.surfaceColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppPalette.borderColor(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Tanggal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  formatDateWithLocale(_selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Metode Bayar',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: paymentMethods
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(paymentMethodLabels[m] ?? m),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Simpan Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDateWithLocale(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori')),
      );
      return;
    }
    final amount = int.parse(_amountController.text.replaceAll('.', ''));
    final notifier = ref.read(transactionNotifierProvider.notifier);
    if (widget.existingTransaction != null) {
      await notifier.updateTransaction(
        id: widget.existingTransaction!.id,
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        paymentMethod: _paymentMethod,
      );
      ref.invalidate(transactionDetailProvider(widget.existingTransaction!.id));
    } else {
      await notifier.addTransaction(
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        paymentMethod: _paymentMethod,
      );
    }
    if (mounted) {
      context.pop();
      ref.invalidate(transactionListProvider);
      ref.invalidate(monthlySummaryProvider);
    }
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
      color: selected ? activeColor.withOpacity(0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
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
