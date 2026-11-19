class QuickParsedTransaction {
  final String type;
  final int amount;
  final String note;
  final String? categoryName;
  final String paymentMethod;

  const QuickParsedTransaction({
    required this.type,
    required this.amount,
    required this.note,
    this.categoryName,
    this.paymentMethod = 'cash',
  });
}

List<QuickParsedTransaction> parseQuickTextOffline(String input) {
  final segments = input
      .split(RegExp(r'[,;\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);

  final results = <QuickParsedTransaction>[];
  final amountRegex = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(jt|juta|rb|ribu|k)?\b',
    caseSensitive: false,
  );

  for (final segment in segments) {
    final matches = amountRegex.allMatches(segment).toList();
    if (matches.isEmpty) continue;

    // Prefer the last match that looks like a price/amount (or has a unit suffix).
    final match = matches.lastWhere(
      (m) => m.group(2) != null,
      orElse: () => matches.last,
    );

    final rawNum = match.group(1)!.replaceAll(',', '.');
    final unit = (match.group(2) ?? '').toLowerCase();
    double? parsed = double.tryParse(rawNum);
    if (parsed == null) {
      final cleanInt = int.tryParse(match.group(1)!.replaceAll(RegExp(r'[.,]'), ''));
      if (cleanInt == null) continue;
      parsed = cleanInt.toDouble();
    }

    int amount;
    if (unit == 'jt' || unit == 'juta') {
      amount = (parsed * 1000000).round();
    } else if (unit == 'rb' || unit == 'ribu' || unit == 'k') {
      amount = (parsed * 1000).round();
    } else {
      // Handle Indonesian thousand-separator dots like 25.000
      final dotNormalized = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
      amount = int.tryParse(dotNormalized) ?? parsed.round();
    }

    if (amount <= 0) continue;

    final lower = segment.toLowerCase();
    final isIncome = RegExp(
      r'\b(gaji|bonus|freelance|dapat|dapet|terima|masuk|hadiah|dividen)\b',
    ).hasMatch(lower);

    String paymentMethod = 'cash';
    if (RegExp(r'\bqris\b').hasMatch(lower)) {
      paymentMethod = 'qris';
    } else if (RegExp(r'\b(ewallet|gopay|ovo|dana|shopeepay|linkaja)\b').hasMatch(lower)) {
      paymentMethod = 'ewallet';
    } else if (RegExp(r'\b(debit|transfer|tf|bca|mandiri|bri|bni)\b').hasMatch(lower)) {
      paymentMethod = 'debit';
    } else if (RegExp(r'\b(kredit|credit|cc)\b').hasMatch(lower)) {
      paymentMethod = 'credit';
    }

    var note = segment
        .replaceRange(match.start, match.end, '')
        .replaceAll(
          RegExp(
            r'\b(qris|cash|tunai|ewallet|gopay|ovo|dana|shopeepay|debit|kredit|credit)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (note.isEmpty) {
      note = isIncome ? 'Pemasukan' : 'Pengeluaran';
    }

    results.add(
      QuickParsedTransaction(
        type: isIncome ? 'income' : 'expense',
        amount: amount,
        note: note,
        paymentMethod: paymentMethod,
      ),
    );
  }

  return results;
}
