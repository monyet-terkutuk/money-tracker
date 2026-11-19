import 'package:catat_uang_pribadi/features/recurring/domain/legacy_recurring_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses stored rules and skips broken rows', () {
    const raw = '''
[
  {
    "id": "a",
    "title": "Listrik",
    "type": "expense",
    "amount": 250000,
    "categoryId": "tagihan",
    "paymentMethod": "debit",
    "dayOfMonth": 31,
    "lastAppliedMonth": "2026-10",
    "isActive": true
  },
  {"id": 1}
]
''';
    final rules = parseLegacyRecurringRules(raw);
    expect(rules, hasLength(1));
    expect(rules.single.title, 'Listrik');
    expect(rules.single.dayOfMonth, 31);
    expect(
      legacyRuleStart(rules.single, DateTime(2026, 11, 19)),
      DateTime(2026, 10, 1),
    );
  });

  test('a rule that was never applied starts this month', () {
    const rule = LegacyRecurringRule(
      id: 'b',
      title: 'Gaji',
      type: 'income',
      amount: 1,
      categoryId: 'gaji',
      paymentMethod: 'cash',
      dayOfMonth: 1,
      isActive: true,
    );
    expect(
      legacyRuleStart(rule, DateTime(2026, 11, 19)),
      DateTime(2026, 11, 19),
    );
    expect(parseLegacyRecurringRules(null), isEmpty);
  });
}