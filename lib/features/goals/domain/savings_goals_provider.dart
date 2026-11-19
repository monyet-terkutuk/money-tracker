import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/backup/secure_backup_keys.dart';

const _goalsPrefKey = savingsGoalsPrefKey;

class GoalDeposit {
  final int amount;
  final DateTime date;
  final String? note;

  const GoalDeposit({
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory GoalDeposit.fromJson(Map<String, dynamic> json) => GoalDeposit(
        amount: (json['amount'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}

class SavingsGoal {
  final String id;
  final String name;
  final int targetAmount;
  final int savedAmount;
  final List<GoalDeposit> deposits;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deposits = const [],
  });

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => savedAmount >= targetAmount && targetAmount > 0;

  SavingsGoal copyWith({
    int? savedAmount,
    List<GoalDeposit>? deposits,
  }) =>
      SavingsGoal(
        id: id,
        name: name,
        targetAmount: targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        deposits: deposits ?? this.deposits,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'deposits': deposits.map((d) => d.toJson()).toList(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toInt(),
        savedAmount: (json['savedAmount'] as num?)?.toInt() ?? 0,
        deposits: (json['deposits'] as List? ?? [])
            .map((e) => GoalDeposit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

final savingsGoalsProvider =
    StateNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>((ref) {
  return SavingsGoalsNotifier();
});

class SavingsGoalsNotifier extends StateNotifier<List<SavingsGoal>> {
  final _storage = const FlutterSecureStorage();

  SavingsGoalsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _goalsPrefKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> _save() async {
    await _storage.write(
      key: _goalsPrefKey,
      value: jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addGoal({
    required String name,
    required int targetAmount,
    int initialSaved = 0,
  }) async {
    final goal = SavingsGoal(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      savedAmount: initialSaved,
      deposits: initialSaved > 0
          ? [GoalDeposit(amount: initialSaved, date: DateTime.now())]
          : [],
    );
    state = [goal, ...state];
    await _save();
  }

  Future<void> addDeposit(String id, int amount, {String? note}) async {
    if (amount <= 0) return;
    final deposit = GoalDeposit(amount: amount, date: DateTime.now(), note: note);
    state = [
      for (final g in state)
        if (g.id == id)
          g.copyWith(
            savedAmount: g.savedAmount + amount,
            deposits: [deposit, ...g.deposits],
          )
        else
          g,
    ];
    await _save();
  }

  Future<void> removeGoal(String id) async {
    state = state.where((g) => g.id != id).toList();
    await _save();
  }
}
