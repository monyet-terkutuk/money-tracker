import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/backup/secure_backup_keys.dart';

const _presetsPrefKey = quickPresetsPrefKey;

class QuickPreset {
  final String id;
  final String label;
  final String type;
  final int amount;
  final String categoryId;
  final String paymentMethod;

  const QuickPreset({
    required this.id,
    required this.label,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type,
        'amount': amount,
        'categoryId': categoryId,
        'paymentMethod': paymentMethod,
      };

  factory QuickPreset.fromJson(Map<String, dynamic> json) => QuickPreset(
        id: json['id'] as String,
        label: json['label'] as String,
        type: json['type'] as String? ?? 'expense',
        amount: (json['amount'] as num).toInt(),
        categoryId: json['categoryId'] as String,
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      );
}

final quickPresetsProvider =
    StateNotifierProvider<QuickPresetsNotifier, List<QuickPreset>>((ref) {
  return QuickPresetsNotifier();
});

class QuickPresetsNotifier extends StateNotifier<List<QuickPreset>> {
  final _storage = const FlutterSecureStorage();

  QuickPresetsNotifier() : super([]) {
    _load();
  }

  static const _defaultPresets = [
    QuickPreset(
      id: 'preset_coffee',
      label: 'Kopi 20rb',
      type: 'expense',
      amount: 20000,
      categoryId: 'cat_food',
      paymentMethod: 'qris',
    ),
    QuickPreset(
      id: 'preset_lunch',
      label: 'Makan 25rb',
      type: 'expense',
      amount: 25000,
      categoryId: 'cat_food',
      paymentMethod: 'qris',
    ),
    QuickPreset(
      id: 'preset_parking',
      label: 'Parkir 5rb',
      type: 'expense',
      amount: 5000,
      categoryId: 'cat_transport',
      paymentMethod: 'cash',
    ),
  ];

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _presetsPrefKey);
      if (raw == null || raw.isEmpty) {
        state = _defaultPresets;
        return;
      }
      final list = (jsonDecode(raw) as List)
          .map((e) => QuickPreset.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {
      state = _defaultPresets;
    }
  }

  Future<void> _save() async {
    await _storage.write(
      key: _presetsPrefKey,
      value: jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addPreset({
    required String label,
    required String type,
    required int amount,
    required String categoryId,
    required String paymentMethod,
  }) async {
    final preset = QuickPreset(
      id: const Uuid().v4(),
      label: label,
      type: type,
      amount: amount,
      categoryId: categoryId,
      paymentMethod: paymentMethod,
    );
    state = [...state, preset];
    await _save();
  }

  Future<void> removePreset(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }
}
