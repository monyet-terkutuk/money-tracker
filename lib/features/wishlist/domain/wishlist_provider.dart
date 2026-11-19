import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/backup/secure_backup_keys.dart';

const String _wishlistPrefKey = wishlistPrefKey;

class WishlistItem {
  final String id;
  final String name;
  final int price;
  final String? note;
  final DateTime createdAt;
  final int cooldownHours;
  final String status; // 'waiting' | 'resisted' | 'bought'

  const WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.note,
    required this.createdAt,
    this.cooldownHours = 24,
    this.status = 'waiting',
  });

  DateTime get unlockAt => createdAt.add(Duration(hours: cooldownHours));

  bool isReady(DateTime now) => !now.isBefore(unlockAt);

  Duration remaining(DateTime now) {
    final diff = unlockAt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  WishlistItem copyWith({String? status}) => WishlistItem(
        id: id,
        name: name,
        price: price,
        note: note,
        createdAt: createdAt,
        cooldownHours: cooldownHours,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'cooldownHours': cooldownHours,
        'status': status,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toInt(),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        cooldownHours: (json['cooldownHours'] as num?)?.toInt() ?? 24,
        status: (json['status'] as String?) ?? 'waiting',
      );
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, List<WishlistItem>>((ref) {
  return WishlistNotifier();
});

class WishlistNotifier extends StateNotifier<List<WishlistItem>> {
  WishlistNotifier() : super(const []) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final raw = await _storage.read(key: _wishlistPrefKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = decoded
            .whereType<Map>()
            .map((e) => WishlistItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _wishlistPrefKey,
      value: jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addItem({
    required String name,
    required int price,
    String? note,
    int cooldownHours = 24,
  }) async {
    final item = WishlistItem(
      id: const Uuid().v4(),
      name: name,
      price: price,
      note: note,
      createdAt: DateTime.now(),
      cooldownHours: cooldownHours,
    );
    state = [item, ...state];
    await _persist();
  }

  Future<void> markResisted(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: 'resisted') else item,
    ];
    await _persist();
  }

  Future<void> markBought(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: 'bought') else item,
    ];
    await _persist();
  }

  Future<void> removeItem(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }
}
