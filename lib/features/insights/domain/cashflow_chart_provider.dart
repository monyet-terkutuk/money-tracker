import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/domain/transaction_providers.dart';

class MonthlyCashflowPoint {
  final DateTime month;
  final int income;
  final int expense;

  const MonthlyCashflowPoint({
    required this.month,
    required this.income,
    required this.expense,
  });
}

final sixMonthCashflowProvider =
    FutureProvider.autoDispose<List<MonthlyCashflowPoint>>((ref) async {
  final current = ref.watch(currentMonthProvider);
  final db = ref.watch(databaseProvider);
  final months = List.generate(
    6,
    (index) => DateTime(current.year, current.month - (5 - index)),
  );

  final totals = await db.totalsBetween(months.first, months.last);
  return [
    for (final month in months)
      MonthlyCashflowPoint(
        month: month,
        income: totals
            .where((t) => t.year == month.year && t.month == month.month)
            .map((t) => t.income)
            .firstOrNull ??
            0,
        expense: totals
            .where((t) => t.year == month.year && t.month == month.month)
            .map((t) => t.expense)
            .firstOrNull ??
            0,
      ),
  ];
});
