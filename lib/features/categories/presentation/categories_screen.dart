import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../home/domain/budget_provider.dart';
import '../../transactions/domain/category_providers.dart';
import '../../transactions/domain/transaction_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _selectedType = 'expense';

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoryListProvider);
    final txAsync = ref.watch(transactionListProvider);
    final budgets = ref.watch(budgetNotifierProvider);
    final currentMonth = ref.watch(currentMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                formatMonthYear(currentMonth),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.secondaryTextColor(context),
                ),
              ),
            ),
          ),
        ],
      ),
      body: catsAsync.when(
        data: (cats) {
          if (cats.isEmpty) {
            return const EmptyState(
              icon: Icons.category_rounded,
              title: 'Belum ada kategori',
              subtitle: 'Kategori default akan ditambahkan otomatis',
            );
          }

          final filteredCats =
              cats.where((c) => c.type == _selectedType).toList();
          final monthTx = txAsync.valueOrNull ?? [];
          final spentByCat = <String, int>{};
          final countByCat = <String, int>{};
          for (final t in monthTx) {
            spentByCat[t.categoryId] = (spentByCat[t.categoryId] ?? 0) + t.amount;
            countByCat[t.categoryId] = (countByCat[t.categoryId] ?? 0) + 1;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'expense',
                        label: Text(
                          'Pengeluaran (${cats.where((c) => c.type == 'expense').length})',
                        ),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text(
                          'Pemasukan (${cats.where((c) => c.type == 'income').length})',
                        ),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (v) =>
                        setState(() => _selectedType = v.first),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.08,
                  ),
                  itemCount: filteredCats.length,
                  itemBuilder: (context, index) {
                    final cat = filteredCats[index];
                    return _CategoryBentoCard(
                      category: cat,
                      totalAmount: spentByCat[cat.id] ?? 0,
                      txCount: countByCat[cat.id] ?? 0,
                      budgetLimit:
                          cat.type == 'expense' ? budgets[cat.id] : null,
                      onTap: () => context.push('/categories/${cat.id}'),
                      onDelete: cat.isDefault
                          ? null
                          : () {
                              ref
                                  .read(categoryNotifierProvider.notifier)
                                  .deleteCategory(cat.id);
                              ref.invalidate(categoryListProvider);
                            },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori'),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String type = _selectedType;
    String selectedIconKey = type == 'income' ? 'business_center' : 'restaurant';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Kategori'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                    ButtonSegment(value: 'income', label: Text('Pemasukan')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) {
                    setDialogState(() => type = v.first);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori',
                    hintText: 'Mis. Kopi, Langganan, Parkir',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pilih Ikon',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCategoryIcons.map((option) {
                    final selected = selectedIconKey == option.key;
                    final accent = resolveCategoryAccent(
                      option.key,
                      fallback: Theme.of(ctx).colorScheme.primary,
                    );
                    return InkWell(
                      onTap: () =>
                          setDialogState(() => selectedIconKey = option.key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.18)
                              : AppPalette.surfaceColor(ctx),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? accent
                                : AppPalette.borderColor(ctx),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          option.icon,
                          size: 20,
                          color: selected
                              ? accent
                              : AppPalette.secondaryTextColor(ctx),
                        ),
                      ),
                    );
                  }).toList(),
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
                if (name.isEmpty) return;
                await ref.read(categoryNotifierProvider.notifier).addCategory(
                      name: name,
                      icon: selectedIconKey,
                      type: type,
                    );
                ref.invalidate(categoryListProvider);
                ref.invalidate(expenseCategoriesProvider);
                ref.invalidate(incomeCategoriesProvider);
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

class _CategoryBentoCard extends StatelessWidget {
  final Category category;
  final int totalAmount;
  final int txCount;
  final int? budgetLimit;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CategoryBentoCard({
    required this.category,
    required this.totalAmount,
    required this.txCount,
    required this.budgetLimit,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = AppPalette.secondaryTextColor(context);
    final fallbackColor = category.type == 'income'
        ? AppPalette.incomeColor(context)
        : AppPalette.expenseColor(context);
    final color = resolveCategoryAccent(category.icon, fallback: fallbackColor);
    final hasBudget = budgetLimit != null && budgetLimit! > 0;
    final ratio = hasBudget ? totalAmount / budgetLimit! : 0.0;
    final barColor = ratio >= 1.0
        ? AppPalette.expenseColor(context)
        : ratio >= 0.8
            ? AppPalette.warningColor(context)
            : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    resolveCategoryIcon(
                      category.icon,
                      categoryName: category.name,
                      type: category.type,
                    ),
                    color: color,
                    size: 20,
                  ),
                ),
                if (onDelete != null)
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: secondaryText,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: secondaryText,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              txCount > 0
                  ? '${formatCurrency(totalAmount)} · ${txCount}x'
                  : 'Belum ada transaksi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: txCount > 0 ? FontWeight.w600 : FontWeight.w400,
                color: txCount > 0 ? fallbackColor : secondaryText,
              ),
            ),
            if (hasBudget) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 5,
                  color: barColor,
                  backgroundColor: barColor.withValues(alpha: 0.15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
