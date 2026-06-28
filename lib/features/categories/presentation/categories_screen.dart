import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../transactions/domain/category_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: catsAsync.when(
        data: (cats) {
          if (cats.isEmpty) {
            return const EmptyState(
              icon: Icons.category,
              title: 'Belum ada kategori',
              subtitle: 'Kategori default akan ditambahkan otomatis',
            );
          }
          final expenseCats = cats.where((c) => c.type == 'expense').toList();
          final incomeCats = cats.where((c) => c.type == 'income').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Pengeluaran', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...expenseCats.map((c) => _CategoryTile(category: c, ref: ref)),
              const SizedBox(height: 24),
              Text('Pemasukan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...incomeCats.map((c) => _CategoryTile(category: c, ref: ref)),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final WidgetRef ref;

  const _CategoryTile({required this.category, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          IconData(int.tryParse(category.icon) ?? 0xe8b8, fontFamily: 'MaterialIcons'),
          color: category.type == 'income' ? Colors.green : Colors.red,
        ),
        title: Text(category.name),
        subtitle: Text(category.isDefault ? 'Default' : 'Kustom'),
        trailing: category.isDefault
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
                  ref.invalidate(categoryListProvider);
                },
              ),
      ),
    );
  }
}
