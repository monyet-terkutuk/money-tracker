import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../domain/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);
    final insight = ref.watch(monthlyInsightProvider).valueOrNull;
    final dailyBurn = insight?.dailyBurnRate ?? 0;
    final now = DateTime.now();
    final theme = Theme.of(context);

    final waiting = items.where((i) => i.status == 'waiting').toList();
    final resistedTotal = items
        .where((i) => i.status == 'resisted')
        .fold<int>(0, (sum, i) => sum + i.price);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist Cooldown')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Container(
            height: 112,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPalette.incomeColor(context).withValues(alpha: 0.85),
                  theme.colorScheme.primary.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://plus.unsplash.com/premium_photo-1711051475117-f3a4d3ff6778?fm=jpg&q=60&w=1200&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.savings_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Berhasil Ditahan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatCurrency(resistedTotal),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (waiting.isEmpty)
            EmptyState(
              icon: Icons.hourglass_empty_rounded,
              title: 'Belum ada barang di cooldown',
              subtitle:
                  'Tunda pembelian impulsif selama 24-72 jam sebelum memutuskan beli',
              actionLabel: 'Tambah Wishlist',
              onAction: () => _showAddDialog(context, ref),
            )
          else
            for (final item in waiting) ...[
              _WishlistCard(
                item: item,
                now: now,
                dailyBurnRate: dailyBurn,
                onResist: () async {
                  await ref
                      .read(wishlistProvider.notifier)
                      .markResisted(item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mantap! Kamu menghemat ${formatCurrency(item.price)}',
                        ),
                      ),
                    );
                  }
                },
                onBuy: () => _logPurchase(context, ref, item),
                onDelete: () =>
                    ref.read(wishlistProvider.notifier).removeItem(item.id),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tunda Beli'),
      ),
    );
  }

  Future<void> _logPurchase(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
  ) async {
    final cats = await ref.read(expenseCategoriesProvider.future);
    if (cats.isEmpty) return;
    final defaultCat = cats
            .where((c) => c.name.toLowerCase().contains('belanja'))
            .firstOrNull ??
        cats.first;

    await ref.read(transactionNotifierProvider.notifier).addTransaction(
          type: 'expense',
          amount: item.price,
          categoryId: defaultCat.id,
          date: DateTime.now(),
          note: item.name,
          paymentMethod: 'cash',
        );
    await ref.read(wishlistProvider.notifier).markBought(item.id);
    ref.invalidate(transactionListProvider);
    ref.invalidate(monthlySummaryProvider);
    ref.invalidate(monthlyInsightProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} dicatat sebagai pengeluaran')),
      );
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final noteController = TextEditingController();
    int hours = 24;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tunda Pembelian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang / Keinginan',
                    hintText: 'Mis. TWS baru, Keyboard',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: hours,
                  decoration: const InputDecoration(labelText: 'Durasi Cooldown'),
                  items: const [
                    DropdownMenuItem(value: 24, child: Text('24 Jam')),
                    DropdownMenuItem(value: 48, child: Text('48 Jam')),
                    DropdownMenuItem(value: 72, child: Text('72 Jam (3 Hari)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => hours = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan (opsional)',
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
                final name = nameController.text.trim();
                final price = int.tryParse(
                      priceController.text.replaceAll('.', '').trim(),
                    ) ??
                    0;
                if (name.isEmpty || price <= 0) return;
                await ref.read(wishlistProvider.notifier).addItem(
                      name: name,
                      price: price,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                      cooldownHours: hours,
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
}

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final DateTime now;
  final int dailyBurnRate;
  final VoidCallback onResist;
  final VoidCallback onBuy;
  final VoidCallback onDelete;

  const _WishlistCard({
    required this.item,
    required this.now,
    required this.dailyBurnRate,
    required this.onResist,
    required this.onBuy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);
    final ready = item.isReady(now);
    final rem = item.remaining(now);
    final remText = ready
        ? 'Cooldown selesai — masih yakin mau beli?'
        : 'Tersisa ${rem.inHours} jam ${rem.inMinutes.remainder(60)} menit';
    final eqDays = dailyBurnRate > 0 ? (item.price / dailyBurnRate) : null;

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
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatCurrency(item.price),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.expenseColor(context),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: secondaryText),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (item.note != null) ...[
            const SizedBox(height: 2),
            Text(item.note!, style: TextStyle(fontSize: 12, color: secondaryText)),
          ],
          const SizedBox(height: 8),
          Text(
            remText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ready ? AppPalette.accent(context) : secondaryText,
            ),
          ),
          if (eqDays != null) ...[
            const SizedBox(height: 2),
            Text(
              'Setara ${eqDays.toStringAsFixed(1)} hari rata-rata pengeluaranmu',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onResist,
                  child: const Text('Batal Beli'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onBuy,
                  child: const Text('Tetap Beli'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
