import 'dart:convert';

class LegacyRecurringRule {
  const LegacyRecurringRule({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.paymentMethod,
    required this.dayOfMonth,
    required this.isActive,
    this.lastAppliedMonth,
  });

  final String id;
  final String title;
  final String type;
  final int amount;
  final String categoryId;
  final String paymentMethod;
  final int dayOfMonth;
  final bool isActive;
  final String? lastAppliedMonth;
}

List<LegacyRecurringRule> parseLegacyRecurringRules(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  final rules = <LegacyRecurringRule>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final id = item['id'];
    final title = item['title'];
    final type = item['type'];
    final amount = item['amount'];
    final categoryId = item['categoryId'];
    if (id is! String ||
        title is! String ||
        (type != 'expense' && type != 'income') ||
        amount is! num ||
        categoryId is! String) {
      continue;
    }
    final day = item['dayOfMonth'];
    rules.add(LegacyRecurringRule(
      id: id,
      title: title,
      type: type,
      amount: amount.toInt(),
      categoryId: categoryId,
      paymentMethod: item['paymentMethod'] is String
          ? item['paymentMethod'] as String
          : 'cash',
      dayOfMonth: day is num ? day.toInt().clamp(1, 31).toInt() : 1,
      isActive: item['isActive'] is bool ? item['isActive'] as bool : true,
      lastAppliedMonth: item['lastAppliedMonth'] is String
          ? item['lastAppliedMonth'] as String
          : null,
    ));
  }
  return rules;
}

DateTime legacyRuleStart(LegacyRecurringRule rule, DateTime now) {
  final key = rule.lastAppliedMonth;
  if (key == null) return DateTime(now.year, now.month, now.day);
  final parts = key.split('-');
  if (parts.length != 2) return DateTime(now.year, now.month, now.day);
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) {
    return DateTime(now.year, now.month, now.day);
  }
  return DateTime(year, month, 1);
}
