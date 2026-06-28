import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/constants.dart';
import 'transaction_providers.dart';

final categoryListProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllCategories();
});

final expenseCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getCategoriesByType('expense');
});

final incomeCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getCategoriesByType('income');
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  CategoryNotifier(this._db) : super(const AsyncData(null));

  Future<void> addCategory({
    required String name,
    required String icon,
    required String type,
  }) async {
    final maxOrder = await _db.maxCategorySortOrder();
    await _db.insertCategory(CategoriesCompanion(
      id: Value(const Uuid().v4()),
      name: Value(name),
      icon: Value(icon),
      type: Value(type),
      isDefault: const Value(false),
      sortOrder: Value(maxOrder + 1),
    ));
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? icon,
    int? sortOrder,
  }) async {
    final existing = await _db.getCategoryById(id);
    if (existing == null) return;
    await _db.updateCategory(CategoriesCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      icon: Value(icon ?? existing.icon),
      type: Value(existing.type),
      isDefault: Value(existing.isDefault),
      sortOrder: Value(sortOrder ?? existing.sortOrder),
    ));
  }

  Future<void> deleteCategory(String id) async {
    final existing = await _db.getCategoryById(id);
    if (existing == null || existing.isDefault) return;
    await _db.deleteCategory(id);
  }

  Future<void> seedDefaultCategories() async {
    final existing = await _db.getAllCategories();
    if (existing.isNotEmpty) return;

    int order = 0;
    for (final name in expenseCategories) {
      await _db.insertCategory(CategoriesCompanion(
        id: Value(const Uuid().v4()),
        name: Value(name),
        icon: Value(categoryIcons[name] ?? 'category'),
        type: const Value('expense'),
        isDefault: const Value(true),
        sortOrder: Value(order++),
      ));
    }
    for (final name in incomeCategories) {
      await _db.insertCategory(CategoriesCompanion(
        id: Value(const Uuid().v4()),
        name: Value(name),
        icon: Value(categoryIcons[name] ?? 'category'),
        type: const Value('income'),
        isDefault: const Value(true),
        sortOrder: Value(order++),
      ));
    }
  }
}

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier(ref.watch(databaseProvider));
});
