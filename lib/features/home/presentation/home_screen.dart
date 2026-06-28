import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/amount_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../transactions/domain/transaction_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthlySummaryProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(formatMonthYear(currentMonth)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(monthlySummaryProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summary.when(
              data: (data) => Column(
                children: [
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text('Saldo Bulan Ini',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              )),
                          const SizedBox(height: 8),
                          Text(
                            formatCurrency(data['balance']!),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AmountCard(
                          label: 'Pemasukan',
                          amount: data['income']!,
                          color: Colors.green,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AmountCard(
                          label: 'Pengeluaran',
                          amount: data['expense']!,
                          color: Colors.red,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/transactions?type=income'),
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('Lihat Pemasukan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/transactions?type=expense'),
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('Lihat Pengeluaran'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const LoadingIndicator(message: 'Memuat...'),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Input Manual'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/transactions/add');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Pindai Struk'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/scan');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
