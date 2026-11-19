import 'dart:convert';
import '../../../core/database/app_database.dart';

class PriceMemoryEntry {
  final String itemName;
  final int price;
  final int qty;
  final String storeName;
  final DateTime date;
  final String transactionId;

  const PriceMemoryEntry({
    required this.itemName,
    required this.price,
    required this.qty,
    required this.storeName,
    required this.date,
    required this.transactionId,
  });
}

List<PriceMemoryEntry> extractPriceMemory(List<Transaction> transactions) {
  final entries = <PriceMemoryEntry>[];

  for (final t in transactions) {
    final raw = t.aiRawResponse;
    if (raw == null || raw.trim().isEmpty) continue;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) continue;
      final storeName =
          (decoded['store_name'] as String?)?.trim().isNotEmpty == true
              ? (decoded['store_name'] as String).trim()
              : (t.note ?? 'Toko');
      final items = decoded['items'];
      if (items is! List) continue;
      for (final item in items.whereType<Map>()) {
        final name = item['name']?.toString().trim() ?? '';
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final qty = (item['qty'] as num?)?.toInt() ?? 1;
        if (name.isEmpty || price <= 0) continue;
        entries.add(
          PriceMemoryEntry(
            itemName: name,
            price: price,
            qty: qty < 1 ? 1 : qty,
            storeName: storeName,
            date: t.date,
            transactionId: t.id,
          ),
        );
      }
    } catch (_) {}
  }

  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}
