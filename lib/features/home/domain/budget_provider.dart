import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/utils/constants.dart';

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, Map<String, int>>((ref) {
  return BudgetNotifier();
});

class BudgetNotifier extends StateNotifier<Map<String, int>> {
  BudgetNotifier() : super(const {}) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final raw = await _storage.read(key: budgetPrefKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        state = decoded.map(
          (key, value) => MapEntry(key.toString(), (value as num).toInt()),
        );
      }
    } catch (_) {}
  }

  Future<void> setBudget(String categoryId, int limit) async {
    if (limit <= 0) {
      await removeBudget(categoryId);
      return;
    }
    state = {...state, categoryId: limit};
    await _storage.write(key: budgetPrefKey, value: jsonEncode(state));
  }

  Future<void> removeBudget(String categoryId) async {
    final next = Map<String, int>.from(state)..remove(categoryId);
    state = next;
    await _storage.write(key: budgetPrefKey, value: jsonEncode(state));
  }
}
