import 'dart:convert';

class ReceiptLineInput {
  const ReceiptLineInput({
    required this.name,
    required this.price,
    required this.qty,
    this.storeName,
  });

  final String name;
  final int price;
  final int qty;
  final String? storeName;
}

/// Reads item rows out of the JSON previously stored on `transactions.aiRawResponse`.
List<ReceiptLineInput> parseStoredReceipt(String? raw, String? note) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final store = decoded['store_name']?.toString().trim();
    final storeName = (store != null && store.isNotEmpty) ? store : note;
    final items = decoded['items'];
    if (items is! List) return const [];
    final lines = <ReceiptLineInput>[];
    for (final item in items.whereType<Map>()) {
      final name = item['name']?.toString().trim() ?? '';
      final price = (item['price'] as num?)?.toInt() ?? 0;
      var qty = (item['qty'] as num?)?.toInt() ?? 1;
      if (qty < 1) qty = 1;
      if (name.isEmpty || price <= 0) continue;
      lines.add(ReceiptLineInput(
        name: name,
        price: price,
        qty: qty,
        storeName: storeName,
      ));
    }
    return lines;
  } catch (_) {
    return const [];
  }
}
