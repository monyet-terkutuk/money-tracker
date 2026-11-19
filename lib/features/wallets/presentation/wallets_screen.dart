import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/wallets_provider.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  static IconData _methodIcon(String method) => switch (method) {
        'cash' => Icons.payments_outlined,
        'debit' => Icons.credit_card_rounded,
        'credit' => Icons.credit_score_rounded,
        'qris' => Icons.qr_code_2_rounded,
        'ewallet' => Icons.account_balance_wallet_outlined,
        _ => Icons.wallet_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(walletSummariesProvider);
    final walletsState = ref.watch(walletsNotifierProvider);
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dompet & Transfer')),
      body: summariesAsync.when(
        data: (wallets) {
          final totalAll = wallets.fold<int>(0, (s, w) => s + w.balance);
          return ListView(
            padding: const EdgeInsets.all(20),
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
                    Text(
                      'TOTAL SALDO SEMUA DOMPET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency(totalAll),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF8FAFC),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.burnishedBrassDark,
                          foregroundColor: AppPalette.charcoalInk,
                        ),
                        onPressed: () => _showTransferDialog(context, ref),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text('Transfer Antar Dompet'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Saldo per Akun',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...wallets.map((w) {
                final positive = w.balance >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppPalette.surfaceColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppPalette.borderColor(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              AppPalette.accent(context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _methodIcon(w.method),
                          color: AppPalette.accent(context),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        w.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Saldo awal: ${formatCurrency(w.initialBalance)}',
                        style: TextStyle(fontSize: 12, color: secondaryText),
                      ),
                      trailing: Text(
                        formatCurrency(w.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: positive
                              ? theme.colorScheme.onSurface
                              : AppPalette.expenseColor(context),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      onTap: () => _showInitialBalanceDialog(context, ref, w),
                    ),
                  ),
                );
              }),
              if (walletsState.transfers.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Riwayat Transfer',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...walletsState.transfers.take(10).map((tr) {
                  final fromLabel =
                      paymentMethodLabels[tr.fromMethod] ?? tr.fromMethod;
                  final toLabel =
                      paymentMethodLabels[tr.toMethod] ?? tr.toMethod;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppPalette.surfaceColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side:
                            BorderSide(color: AppPalette.borderColor(context)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Icon(
                          Icons.swap_horiz_rounded,
                          color: AppPalette.accent(context),
                        ),
                        title: Text(
                          '$fromLabel → $toLabel',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          tr.note?.isNotEmpty == true
                              ? '${formatDate(tr.date)} · ${tr.note}'
                              : formatDate(tr.date),
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                        trailing: Text(
                          formatCurrency(tr.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
        loading: () => const LoadingIndicator(message: 'Memuat dompet...'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showInitialBalanceDialog(
    BuildContext context,
    WidgetRef ref,
    WalletSummary wallet,
  ) {
    final controller = TextEditingController(
      text: formatNumberInput(wallet.initialBalance),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Saldo Awal ${wallet.label}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Nominal (Rp)',
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
              final val = int.tryParse(controller.text.replaceAll('.', '')) ?? 0;
              await ref
                  .read(walletsNotifierProvider.notifier)
                  .setInitialBalance(wallet.method, val);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
    final methods = paymentMethods.where((m) => m != 'unknown').toList();
    String from = methods.first;
    String to = methods.length > 1 ? methods[1] : methods.first;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Transfer Antar Dompet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: from,
                  decoration: const InputDecoration(labelText: 'Dari Dompet'),
                  items: methods
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(paymentMethodLabels[m] ?? m),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => from = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: to,
                  decoration: const InputDecoration(labelText: 'Ke Dompet'),
                  items: methods
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(paymentMethodLabels[m] ?? m),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => to = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                  ),
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
                final amount =
                    int.tryParse(amountController.text.replaceAll('.', '')) ??
                        0;
                if (from == to || amount <= 0) return;
                await ref.read(walletsNotifierProvider.notifier).addTransfer(
                      fromMethod: from,
                      toMethod: to,
                      amount: amount,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}
