bool matchesLedgerQuery({
  required String query,
  required String? note,
  required String categoryName,
  required String paymentLabel,
  required int amount,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return (note ?? '').toLowerCase().contains(q) ||
      categoryName.toLowerCase().contains(q) ||
      paymentLabel.toLowerCase().contains(q) ||
      amount.toString().contains(q);
}
