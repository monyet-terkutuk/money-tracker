import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/constants.dart';
import '../domain/transaction_providers.dart';
import '../domain/category_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;

  const AddTransactionScreen({super.key, this.initialType});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
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
    _type = widget.initialType ?? 'expense';
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

    return Scaffold(
      appBar: AppBar(title: Text('Tambah ${_type == 'income' ? 'Pemasukan' : 'Pengeluaran'}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                ButtonSegment(value: 'income', label: Text('Pemasukan')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() {
                _type = v.first;
                _selectedCategoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Masukkan jumlah';
                final n = int.tryParse(v.replaceAll('.', ''));
                if (n == null || n <= 0) return 'Jumlah tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (cats) => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: cats.map((cat) {
                  final selected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text(cat.name),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                  );
                }).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(formatDateWithLocale(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
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
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Metode Bayar'),
              items: paymentMethods.map((m) => DropdownMenuItem(
                value: m,
                child: Text(paymentMethodLabels[m] ?? m),
              )).toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Simpan'),
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
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
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
    await ref.read(transactionNotifierProvider.notifier).addTransaction(
      type: _type,
      amount: amount,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      paymentMethod: _paymentMethod,
    );
    if (context.mounted) {
      context.pop();
      ref.invalidate(transactionListProvider);
      ref.invalidate(monthlySummaryProvider);
    }
  }
}
