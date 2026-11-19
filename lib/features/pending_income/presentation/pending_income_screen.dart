import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../domain/pending_income_provider.dart';

class PendingIncomeScreen extends ConsumerStatefulWidget {
  const PendingIncomeScreen({super.key});

  @override
  ConsumerState<PendingIncomeScreen> createState() =>
      _PendingIncomeScreenState();
}

class _PendingIncomeScreenState extends ConsumerState<PendingIncomeScreen> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();

  static const _quickAmounts = [20000, 25000, 50000, 100000];

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingIncomeProvider);
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);
    final accent = AppPalette.accent(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendapatan Tertunda'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ActionChip(
              label: Text('Bagian ${pendingState.defaultSharePercent}%'),
              onPressed: () => _showSharePercentDialog(
                context,
                pendingState.defaultSharePercent,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                      'BELUM CAIR (PENDING)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${pendingState.entries.length} catatan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.burnishedBrassDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(pendingState.totalNet),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF8FAFC),
                    letterSpacing: -0.8,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (pendingState.totalGross != pendingState.totalNet) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total kotor: ${formatCurrency(pendingState.totalGross)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.burnishedBrassDark,
                      foregroundColor: AppPalette.charcoalInk,
                    ),
                    onPressed: pendingState.entries.isEmpty
                        ? null
                        : () => _showPayoutDialog(context, pendingState),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Cairkan ke Pemasukan'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.surfaceColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.borderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catat Sementara',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tidak memengaruhi saldo utama sebelum dicairkan.',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nominal',
                          hintText: '0',
                          prefixText: 'Rp ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _addQuickEntry,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _quickAmounts.map((amt) {
                    return ActionChip(
                      label: Text('${amt ~/ 1000}rb'),
                      onPressed: () {
                        _amountController.text = formatNumberInput(amt);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Catatan (opsional)',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Daftar Tertunda',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (pendingState.entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.surfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.borderColor(context)),
              ),
              child: Text(
                'Belum ada catatan tertunda. Masukkan nominal di atas untuk mencatat pemasukan yang belum diterima.',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryText,
                  height: 1.4,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppPalette.surfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.borderColor(context)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < pendingState.entries.length; i++) ...[
                    _buildEntryRow(
                      context,
                      pendingState.entries[i],
                      secondaryText,
                      accent,
                    ),
                    if (i < pendingState.entries.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppPalette.borderColor(context),
                      ),
                  ],
                ],
              ),
            ),
          if (pendingState.history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Riwayat Pencairan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...pendingState.history.map((h) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppPalette.surfaceColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppPalette.borderColor(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppPalette.incomeColor(context),
                    ),
                    title: Text(
                      'Cair ${h.entryCount} catatan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${formatDate(h.paidAt)} · ${paymentMethodLabels[h.paymentMethod] ?? h.paymentMethod}',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                    trailing: Text(
                      '+ ${formatCurrency(h.totalAmount)}',
                      style: TextStyle(
                        color: AppPalette.incomeColor(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryRow(
    BuildContext context,
    PendingIncomeEntry entry,
    Color secondaryText,
    Color accent,
  ) {
    final timeStr =
        '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule_rounded, size: 17, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  entry.sharePercent < 100
                      ? '${formatDate(entry.createdAt)} $timeStr · ${entry.sharePercent}% dari ${formatCurrency(entry.grossAmount)}'
                      : '${formatDate(entry.createdAt)} · $timeStr',
                  style: TextStyle(fontSize: 11.5, color: secondaryText),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(entry.netAmount),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: secondaryText),
            onPressed: () =>
                ref.read(pendingIncomeProvider.notifier).removeEntry(entry.id),
          ),
        ],
      ),
    );
  }

  Future<void> _addQuickEntry() async {
    final amount = parseFormattedAmount(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid')),
      );
      return;
    }
    await ref.read(pendingIncomeProvider.notifier).addEntry(
          label: _noteController.text,
          grossAmount: amount,
        );
    _noteController.clear();
    _amountController.clear();
  }

  void _showSharePercentDialog(BuildContext context, int currentPercent) {
    final presets = [100, 70, 60, 50];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Persentase Bagian Bersih'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih berapa persen dari nominal yang menjadi bagian bersih Anda:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                return ChoiceChip(
                  label: Text(p == 100 ? '100% (Penuh)' : '$p%'),
                  selected: currentPercent == p,
                  onSelected: (_) async {
                    await ref
                        .read(pendingIncomeProvider.notifier)
                        .setDefaultSharePercent(p);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayoutDialog(BuildContext context, PendingIncomeState state) {
    final amountController =
        TextEditingController(text: formatNumberInput(state.totalNet));
    String paymentMethod = 'cash';
    final incomeCats = ref.read(incomeCategoriesProvider).valueOrNull ?? [];
    String categoryId =
        incomeCats.isNotEmpty ? incomeCats.first.id : 'cat_salary';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cairkan ke Pemasukan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Total Diterima',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                if (incomeCats.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration:
                        const InputDecoration(labelText: 'Kategori Pemasukan'),
                    items: incomeCats
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
                  decoration: const InputDecoration(labelText: 'Masuk ke Dompet'),
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
                final finalAmount =
                    parseFormattedAmount(amountController.text) ?? 0;
                if (finalAmount <= 0) return;

                await ref
                    .read(transactionNotifierProvider.notifier)
                    .addTransaction(
                      type: 'income',
                      amount: finalAmount,
                      categoryId: categoryId,
                      date: DateTime.now(),
                      note:
                          'Pencairan pendapatan tertunda (${state.entries.length} catatan)',
                      paymentMethod: paymentMethod,
                    );
                await ref
                    .read(pendingIncomeProvider.notifier)
                    .clearAndRecordPayout(
                      finalAmount: finalAmount,
                      paymentMethod: paymentMethod,
                    );

                ref.invalidate(transactionListProvider);
                ref.invalidate(monthlySummaryProvider);
                ref.invalidate(monthlyInsightProvider);

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${formatCurrency(finalAmount)} berhasil dicairkan ke Pemasukan!',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Cairkan'),
            ),
          ],
        ),
      ),
    );
  }
}
