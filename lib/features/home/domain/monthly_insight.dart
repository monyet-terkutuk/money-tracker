import '../../../core/database/app_database.dart';
import '../../../core/utils/constants.dart';

class CategorySpending {
  final String categoryId;
  final String categoryName;
  final int amount;
  final double percentage;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });
}

class LatteFactorSummary {
  final int count;
  final int totalAmount;
  final int threshold;

  const LatteFactorSummary({
    required this.count,
    required this.totalAmount,
    required this.threshold,
  });
}

class PaymentMethodSummary {
  final String method;
  final int income;
  final int expense;
  final int net;

  const PaymentMethodSummary({
    required this.method,
    required this.income,
    required this.expense,
    required this.net,
  });
}

class MonthlyInsight {
  final int totalIncome;
  final int totalExpense;
  final int balance;
  final int prevMonthExpense;
  final double? expenseChangePercent;
  final int dailyBurnRate;
  final int projectedMonthEndExpense;
  final List<CategorySpending> categoryBreakdown;
  final LatteFactorSummary? latteFactor;
  final List<PaymentMethodSummary> paymentMethodBreakdown;

  const MonthlyInsight({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.prevMonthExpense,
    required this.expenseChangePercent,
    required this.dailyBurnRate,
    required this.projectedMonthEndExpense,
    required this.categoryBreakdown,
    required this.latteFactor,
    required this.paymentMethodBreakdown,
  });
}

MonthlyInsight computeMonthlyInsight({
  required DateTime month,
  required DateTime now,
  required List<Transaction> currentTransactions,
  required List<Transaction> prevTransactions,
  required List<Category> categories,
}) {
  int totalIncome = 0;
  int totalExpense = 0;
  int smallExpenseCount = 0;
  int smallExpenseTotal = 0;
  final expenseByCategory = <String, int>{};
  final incomeByMethod = <String, int>{};
  final expenseByMethod = <String, int>{};

  for (final t in currentTransactions) {
    if (t.type == 'income') {
      totalIncome += t.amount;
      incomeByMethod[t.paymentMethod] =
          (incomeByMethod[t.paymentMethod] ?? 0) + t.amount;
    } else if (t.type == 'expense') {
      totalExpense += t.amount;
      expenseByCategory[t.categoryId] =
          (expenseByCategory[t.categoryId] ?? 0) + t.amount;
      expenseByMethod[t.paymentMethod] =
          (expenseByMethod[t.paymentMethod] ?? 0) + t.amount;
      if (t.amount <= latteFactorThreshold) {
        smallExpenseCount++;
        smallExpenseTotal += t.amount;
      }
    }
  }

  int prevMonthExpense = 0;
  for (final t in prevTransactions) {
    if (t.type == 'expense') {
      prevMonthExpense += t.amount;
    }
  }

  double? expenseChangePercent;
  if (prevMonthExpense > 0) {
    expenseChangePercent =
        ((totalExpense - prevMonthExpense) / prevMonthExpense) * 100;
  }

  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final isCurrentMonth = month.year == now.year && month.month == now.month;
  final isFutureMonth =
      month.year > now.year || (month.year == now.year && month.month > now.month);

  int elapsedDays;
  if (isFutureMonth) {
    elapsedDays = 0;
  } else if (isCurrentMonth) {
    elapsedDays = now.day.clamp(1, daysInMonth);
  } else {
    elapsedDays = daysInMonth;
  }

  final dailyBurnRate =
      elapsedDays > 0 ? (totalExpense / elapsedDays).round() : 0;
  final projectedMonthEndExpense =
      isFutureMonth ? 0 : dailyBurnRate * daysInMonth;

  final categoryNames = {for (final c in categories) c.id: c.name};
  final breakdown = expenseByCategory.entries.map((entry) {
    final pct = totalExpense > 0 ? entry.value / totalExpense : 0.0;
    return CategorySpending(
      categoryId: entry.key,
      categoryName: categoryNames[entry.key] ?? 'Lainnya',
      amount: entry.value,
      percentage: pct,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final latteFactor = smallExpenseCount >= latteFactorMinCount
      ? LatteFactorSummary(
          count: smallExpenseCount,
          totalAmount: smallExpenseTotal,
          threshold: latteFactorThreshold,
        )
      : null;

  final methods = {...incomeByMethod.keys, ...expenseByMethod.keys};
  final paymentMethodBreakdown = methods.map((m) {
    final inc = incomeByMethod[m] ?? 0;
    final exp = expenseByMethod[m] ?? 0;
    return PaymentMethodSummary(
      method: m,
      income: inc,
      expense: exp,
      net: inc - exp,
    );
  }).toList()
    ..sort((a, b) => (b.income + b.expense).compareTo(a.income + a.expense));

  return MonthlyInsight(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    balance: totalIncome - totalExpense,
    prevMonthExpense: prevMonthExpense,
    expenseChangePercent: expenseChangePercent,
    dailyBurnRate: dailyBurnRate,
    projectedMonthEndExpense: projectedMonthEndExpense,
    categoryBreakdown: breakdown,
    latteFactor: latteFactor,
    paymentMethodBreakdown: paymentMethodBreakdown,
  );
}
