import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../domain/price_memory_helper.dart';

final _allTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) {
  return ref.watch(databaseProvider).getAllTransactions();
});

class PriceMemoryScreen extends ConsumerStatefulWidget {
  const PriceMemoryScreen({super.key});

  @override
  ConsumerState<PriceMemoryScreen> createState() => _PriceMemoryScreenState();
}

class _PriceMemoryScreenState extends ConsumerState<PriceMemoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(_allTransactionsProvider);
    final secondaryText = AppPalette.secondaryTextColor(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ingatan Harga')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Container(
              height: 92,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    AppPalette.accent(context),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://plus.unsplash.com/premium_photo-1669904022364-2395d17d24c1?fm=jpg&q=60&w=1200&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.52),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingatan Harga Pribadi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Cari riwayat harga barang dari struk belanja yang pernah dipindai',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama barang atau toko dari struk...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: txAsync.when(
              data: (txs) {
                final allEntries = extractPriceMemory(txs);
                final filtered = _query.isEmpty
                    ? allEntries
                    : allEntries
                        .where(
                          (e) =>
                              e.itemName.toLowerCase().contains(_query) ||
                              e.storeName.toLowerCase().contains(_query),
                        )
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.sell_outlined,
                    title: allEntries.isEmpty
                        ? 'Belum ada data item struk'
                        : 'Barang tidak ditemukan',
                    subtitle: allEntries.isEmpty
                        ? 'Pindai struk belanja dengan AI agar riwayat harga tercatat otomatis'
                        : 'Coba kata kunci lain',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Material(
                      color: AppPalette.surfaceColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: AppPalette.borderColor(context),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        title: Text(
                          item.qty > 1
                              ? '${item.itemName} (${item.qty}x)'
                              : item.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${item.storeName} · ${formatDate(item.date)}',
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                        trailing: Text(
                          formatCurrency(item.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () =>
                            context.push('/transactions/${item.transactionId}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(message: 'Memuat riwayat...'),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
