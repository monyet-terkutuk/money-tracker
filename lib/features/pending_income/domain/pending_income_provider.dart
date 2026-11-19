import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/backup/secure_backup_keys.dart';

const _pendingIncomePrefKey = pendingIncomePrefKey;

class PendingIncomeEntry {
  final String id;
  final String label;
  final int grossAmount;
  final int sharePercent;
  final DateTime createdAt;

  const PendingIncomeEntry({
    required this.id,
    required this.label,
    required this.grossAmount,
    this.sharePercent = 100,
    required this.createdAt,
  });

  int get netAmount => ((grossAmount * sharePercent) / 100).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'grossAmount': grossAmount,
        'sharePercent': sharePercent,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingIncomeEntry.fromJson(Map<String, dynamic> json) =>
      PendingIncomeEntry(
        id: json['id'] as String,
        label: json['label'] as String,
        grossAmount: (json['grossAmount'] as num).toInt(),
        sharePercent: (json['sharePercent'] as num?)?.toInt() ?? 100,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class PendingPayoutHistory {
  final String id;
  final DateTime paidAt;
  final int entryCount;
  final int totalAmount;
  final String paymentMethod;

  const PendingPayoutHistory({
    required this.id,
    required this.paidAt,
    required this.entryCount,
    required this.totalAmount,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'paidAt': paidAt.toIso8601String(),
        'entryCount': entryCount,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
      };

  factory PendingPayoutHistory.fromJson(Map<String, dynamic> json) =>
      PendingPayoutHistory(
        id: json['id'] as String,
        paidAt: DateTime.parse(json['paidAt'] as String),
        entryCount: (json['entryCount'] as num).toInt(),
        totalAmount: (json['totalAmount'] as num).toInt(),
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      );
}

class PendingIncomeState {
  final List<PendingIncomeEntry> entries;
  final int defaultSharePercent;
  final List<PendingPayoutHistory> history;

  const PendingIncomeState({
    this.entries = const [],
    this.defaultSharePercent = 100,
    this.history = const [],
  });

  int get totalGross => entries.fold<int>(0, (s, e) => s + e.grossAmount);
  int get totalNet => entries.fold<int>(0, (s, e) => s + e.netAmount);
}

final pendingIncomeProvider =
    StateNotifierProvider<PendingIncomeNotifier, PendingIncomeState>((ref) {
  return PendingIncomeNotifier();
});

class PendingIncomeNotifier extends StateNotifier<PendingIncomeState> {
  final _storage = const FlutterSecureStorage();

  PendingIncomeNotifier() : super(const PendingIncomeState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _pendingIncomePrefKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entries = (map['entries'] as List? ?? [])
          .map((e) => PendingIncomeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final history = (map['history'] as List? ?? [])
          .map((e) => PendingPayoutHistory.fromJson(e as Map<String, dynamic>))
          .toList();
      final share = (map['defaultSharePercent'] as num?)?.toInt() ?? 100;
      state = PendingIncomeState(
        entries: entries,
        defaultSharePercent: share.clamp(1, 100),
        history: history,
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    await _storage.write(
      key: _pendingIncomePrefKey,
      value: jsonEncode({
        'defaultSharePercent': state.defaultSharePercent,
        'entries': state.entries.map((e) => e.toJson()).toList(),
        'history': state.history.map((h) => h.toJson()).toList(),
      }),
    );
  }

  Future<void> setDefaultSharePercent(int percent) async {
    state = PendingIncomeState(
      entries: state.entries,
      defaultSharePercent: percent.clamp(1, 100),
      history: state.history,
    );
    await _save();
  }

  Future<void> addEntry({
    String? label,
    required int grossAmount,
    int? sharePercent,
  }) async {
    if (grossAmount <= 0) return;
    final cleanLabel = (label ?? '').trim();
    final nextNumber = state.entries.length + 1;
    final entry = PendingIncomeEntry(
      id: const Uuid().v4(),
      label: cleanLabel.isEmpty ? 'Catatan #$nextNumber' : cleanLabel,
      grossAmount: grossAmount,
      sharePercent: (sharePercent ?? state.defaultSharePercent).clamp(1, 100),
      createdAt: DateTime.now(),
    );
    state = PendingIncomeState(
      entries: [entry, ...state.entries],
      defaultSharePercent: state.defaultSharePercent,
      history: state.history,
    );
    await _save();
  }

  Future<void> removeEntry(String id) async {
    state = PendingIncomeState(
      entries: state.entries.where((e) => e.id != id).toList(),
      defaultSharePercent: state.defaultSharePercent,
      history: state.history,
    );
    await _save();
  }

  Future<void> clearAndRecordPayout({
    required int finalAmount,
    required String paymentMethod,
  }) async {
    final record = PendingPayoutHistory(
      id: const Uuid().v4(),
      paidAt: DateTime.now(),
      entryCount: state.entries.length,
      totalAmount: finalAmount,
      paymentMethod: paymentMethod,
    );
    state = PendingIncomeState(
      entries: const [],
      defaultSharePercent: state.defaultSharePercent,
      history: [record, ...state.history].take(20).toList(),
    );
    await _save();
  }
}
