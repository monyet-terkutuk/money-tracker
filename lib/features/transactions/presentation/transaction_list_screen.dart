import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/transaction_providers.dart';
import '../domain/category_providers.dart';

class TransactionListScreen extends ConsumerWidget {
  final String? filterType;

  const TransactionListScreen({super.key, this.filterType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(formatMonthYear(currentMonth)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(currentMonthProvider.notifier).state =
                  DateTime(currentMonth.year, currentMonth.month - 1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(currentMonthProvider.notifier).state =
                  DateTime(currentMonth.year, currentMonth.month + 1);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(transactionListProvider.future),
        child: transactionsAsync.when(
          data: (transactions) {
            final filtered = filterType != null
                ? transactions.where((t) => t.type == filterType).toList()
                : transactions;
            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long,
                title: 'Belum ada transaksi',
                subtitle: 'Tambahkan transaksi pertama Anda',
                actionLabel: 'Tambah Transaksi',
                onAction: () => context.push('/transactions/add'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final t = filtered[index];
                final cat = categoriesAsync.valueOrNull?.firstWhere(
                  (c) => c.id == t.categoryId,
                  orElse: () => Category(id: '', name: 'Lainnya', icon: 'category', type: t.type, isDefault: false, sortOrder: 0),
                );
                final isIncome = t.type == 'income';
                return Dismissible(
                  key: Key(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: theme.colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(transactionNotifierProvider.notifier).deleteTransaction(t.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Transaksi dihapus'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {},
                        ),
                        duration: const Duration(seconds: undoDeleteDurationSeconds),
                      ),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(cat?.name ?? 'Lainnya'),
                      subtitle: Text(formatDate(t.date)),
                      trailing: Text(
                        '${isIncome ? '+' : '-'} ${formatCurrency(t.amount)}',
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => context.push('/transactions/${t.id}'),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingIndicator(message: 'Memuat transaksi...'),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
