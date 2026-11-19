import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/constants.dart';
import '../../transactions/domain/transaction_providers.dart';

import '../../../core/backup/secure_backup_keys.dart';

const _transfersPrefKey = walletTransfersPrefKey;
const _initialBalancesPrefKey = walletInitialBalancesPrefKey;

class WalletTransfer {
  final String id;
  final String fromMethod;
  final String toMethod;
  final int amount;
  final DateTime date;
  final String? note;

  const WalletTransfer({
    required this.id,
    required this.fromMethod,
    required this.toMethod,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromMethod': fromMethod,
        'toMethod': toMethod,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory WalletTransfer.fromJson(Map<String, dynamic> json) => WalletTransfer(
        id: json['id'] as String,
        fromMethod: json['fromMethod'] as String,
        toMethod: json['toMethod'] as String,
        amount: (json['amount'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}

class WalletSummary {
  final String method;
  final String label;
  final int initialBalance;
  final int balance;

  const WalletSummary({
    required this.method,
    required this.label,
    required this.initialBalance,
    required this.balance,
  });
}

class WalletsState {
  final List<WalletTransfer> transfers;
  final Map<String, int> initialBalances;

  const WalletsState({
    this.transfers = const [],
    this.initialBalances = const {},
  });
}

final walletsNotifierProvider =
    StateNotifierProvider<WalletsNotifier, WalletsState>((ref) {
  return WalletsNotifier();
});

class WalletsNotifier extends StateNotifier<WalletsState> {
  final _storage = const FlutterSecureStorage();

  WalletsNotifier() : super(const WalletsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rawTransfers = await _storage.read(key: _transfersPrefKey);
      final rawInitial = await _storage.read(key: _initialBalancesPrefKey);

      final transfers = rawTransfers != null && rawTransfers.isNotEmpty
          ? (jsonDecode(rawTransfers) as List)
              .map((e) => WalletTransfer.fromJson(e as Map<String, dynamic>))
              .toList()
          : <WalletTransfer>[];

      final initial = <String, int>{};
      if (rawInitial != null && rawInitial.isNotEmpty) {
        final decoded = jsonDecode(rawInitial) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          initial[entry.key] = (entry.value as num).toInt();
        }
      }

      state = WalletsState(transfers: transfers, initialBalances: initial);
    } catch (_) {}
  }

  Future<void> addTransfer({
    required String fromMethod,
    required String toMethod,
    required int amount,
    String? note,
  }) async {
    if (fromMethod == toMethod || amount <= 0) return;
    final transfer = WalletTransfer(
      id: const Uuid().v4(),
      fromMethod: fromMethod,
      toMethod: toMethod,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    final updated = [transfer, ...state.transfers];
    state = WalletsState(
      transfers: updated,
      initialBalances: state.initialBalances,
    );
    await _storage.write(
      key: _transfersPrefKey,
      value: jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteTransfer(String id) async {
    final updated = state.transfers.where((t) => t.id != id).toList();
    state = WalletsState(
      transfers: updated,
      initialBalances: state.initialBalances,
    );
    await _storage.write(
      key: _transfersPrefKey,
      value: jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> setInitialBalance(String method, int amount) async {
    final updated = Map<String, int>.from(state.initialBalances)
      ..[method] = amount;
    state = WalletsState(
      transfers: state.transfers,
      initialBalances: updated,
    );
    await _storage.write(
      key: _initialBalancesPrefKey,
      value: jsonEncode(updated),
    );
  }
}

final walletSummariesProvider =
    FutureProvider.autoDispose<List<WalletSummary>>((ref) async {
  final db = ref.watch(databaseProvider);
  final walletsState = ref.watch(walletsNotifierProvider);
  ref.watch(monthlySummaryProvider);

  final allTx = await db.getAllTransactions();
  final trackedMethods = paymentMethods.where((m) => m != 'unknown').toList();

  final balances = <String, int>{
    for (final m in trackedMethods) m: walletsState.initialBalances[m] ?? 0,
  };

  for (final tx in allTx) {
    if (!balances.containsKey(tx.paymentMethod)) continue;
    final delta = tx.type == 'income' ? tx.amount : -tx.amount;
    balances[tx.paymentMethod] = (balances[tx.paymentMethod] ?? 0) + delta;
  }

  for (final tr in walletsState.transfers) {
    if (balances.containsKey(tr.fromMethod)) {
      balances[tr.fromMethod] = (balances[tr.fromMethod] ?? 0) - tr.amount;
    }
    if (balances.containsKey(tr.toMethod)) {
      balances[tr.toMethod] = (balances[tr.toMethod] ?? 0) + tr.amount;
    }
  }

  return trackedMethods
      .map(
        (m) => WalletSummary(
          method: m,
          label: paymentMethodLabels[m] ?? m,
          initialBalance: walletsState.initialBalances[m] ?? 0,
          balance: balances[m] ?? 0,
        ),
      )
      .toList();
});
