import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/savings_goals_provider.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider);
    final secondaryText = AppPalette.secondaryTextColor(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Target Tabungan')),
      body: goals.isEmpty
          ? EmptyState(
              icon: Icons.savings_outlined,
              title: 'Belum ada target tabungan',
              subtitle:
                  'Buat target dana darurat, liburan, atau barang impian dan pantau progresnya.',
              actionLabel: 'Buat Target',
              onAction: () => _showCreateGoalDialog(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final remaining =
                    (goal.targetAmount - goal.savedAmount).clamp(0, goal.targetAmount);
                final barColor = goal.isCompleted
                    ? AppPalette.incomeColor(context)
                    : AppPalette.accent(context);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPalette.borderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            '${(goal.progress * 100).round()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: barColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: secondaryText,
                            ),
                            onPressed: () => ref
                                .read(savingsGoalsProvider.notifier)
                                .removeGoal(goal.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          minHeight: 7,
                          backgroundColor: barColor.withValues(alpha: 0.14),
                          valueColor: AlwaysStoppedAnimation(barColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatCurrency(goal.savedAmount)} / ${formatCurrency(goal.targetAmount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            goal.isCompleted
                                ? 'Tercapai!'
                                : 'Kurang ${formatCompactCurrency(remaining)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: goal.isCompleted
                                  ? AppPalette.incomeColor(context)
                                  : secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (!goal.isCompleted) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showDepositDialog(context, ref, goal),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Setor Tabungan'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGoalDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Target'),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final initialController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Target Tabungan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Target (mis. Dana Darurat)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Target Nominal',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: initialController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Sudah Terkumpul (opsional)',
                  prefixText: 'Rp ',
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
              final target =
                  int.tryParse(targetController.text.replaceAll('.', '')) ?? 0;
              final initial =
                  int.tryParse(initialController.text.replaceAll('.', '')) ?? 0;
              if (name.isEmpty || target <= 0) return;
              await ref.read(savingsGoalsProvider.notifier).addGoal(
                    name: name,
                    targetAmount: target,
                    initialSaved: initial,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Setor ke ${goal.name}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Jumlah Setoran',
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
              final amount =
                  int.tryParse(amountController.text.replaceAll('.', '')) ?? 0;
              if (amount <= 0) return;
              await ref
                  .read(savingsGoalsProvider.notifier)
                  .addDeposit(goal.id, amount);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Setor'),
          ),
        ],
      ),
    );
  }
}
