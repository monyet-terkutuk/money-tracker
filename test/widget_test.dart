import 'package:flutter_test/flutter_test.dart';

import 'package:catat_uang_pribadi/core/database/app_database.dart';
import 'package:catat_uang_pribadi/core/utils/constants.dart';
import 'package:catat_uang_pribadi/features/home/domain/monthly_insight.dart';
import 'package:catat_uang_pribadi/features/price_memory/domain/price_memory_helper.dart';
import 'package:catat_uang_pribadi/features/scan/ai_parser_service.dart';
import 'package:catat_uang_pribadi/features/scan/quick_parser.dart';

void main() {
  group('payment methods', () {
    test('every payment method has a label', () {
      for (final method in paymentMethods) {
        expect(paymentMethodLabels[method], isNotNull);
      }
    });

    test('cash is a valid payment method', () {
      expect(paymentMethods, contains('cash'));
    });
  });

  group('AiParseResult', () {
    test('defaults to a receipt with no items', () {
      final result = AiParseResult();
      expect(result.isReceipt, isTrue);
      expect(result.items, isEmpty);
      expect(result.totalAmount, isNull);
      expect(result.raw, isNull);
    });

    test('retains provided values including raw response', () {
      final result = AiParseResult(
        storeName: 'Toko A',
        date: '2024-01-15',
        totalAmount: 15000,
        paymentMethod: 'qris',
        suggestedCategory: 'Belanja',
        raw: '{"total_amount":15000}',
      );
      expect(result.storeName, 'Toko A');
      expect(result.date, '2024-01-15');
      expect(result.totalAmount, 15000);
      expect(result.paymentMethod, 'qris');
      expect(result.suggestedCategory, 'Belanja');
      expect(result.raw, '{"total_amount":15000}');
    });
  });

  group('computeMonthlyInsight', () {
    test('calculates totals, burn rate, MoM change, and category breakdown', () {
      final month = DateTime(2026, 11, 1);
      final now = DateTime(2026, 11, 10);
      final cats = [
        const Category(
          id: 'c1',
          name: 'Makanan',
          icon: 'restaurant',
          type: 'expense',
          isDefault: true,
          sortOrder: 0,
        ),
        const Category(
          id: 'c2',
          name: 'Transportasi',
          icon: 'directions_car',
          type: 'expense',
          isDefault: true,
          sortOrder: 1,
        ),
      ];
      final currentTx = [
        Transaction(
          id: 't1',
          type: 'income',
          amount: 500000,
          categoryId: 'inc1',
          date: DateTime(2026, 11, 1),
          paymentMethod: 'cash',
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't2',
          type: 'expense',
          amount: 150000,
          categoryId: 'c1',
          date: DateTime(2026, 11, 3),
          paymentMethod: 'qris',
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't3',
          type: 'expense',
          amount: 50000,
          categoryId: 'c2',
          date: DateTime(2026, 11, 5),
          paymentMethod: 'cash',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final prevTx = [
        Transaction(
          id: 'p1',
          type: 'expense',
          amount: 100000,
          categoryId: 'c1',
          date: DateTime(2026, 10, 10),
          paymentMethod: 'cash',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final insight = computeMonthlyInsight(
        month: month,
        now: now,
        currentTransactions: currentTx,
        prevTransactions: prevTx,
        categories: cats,
      );

      expect(insight.totalIncome, 500000);
      expect(insight.totalExpense, 200000);
      expect(insight.balance, 300000);
      expect(insight.dailyBurnRate, 20000);
      expect(insight.projectedMonthEndExpense, 600000);
      expect(insight.expenseChangePercent, closeTo(100.0, 0.01));
      expect(insight.categoryBreakdown.length, 2);
      expect(insight.categoryBreakdown.first.categoryName, 'Makanan');
      expect(insight.categoryBreakdown.first.percentage, closeTo(0.75, 0.01));
      expect(insight.latteFactor, isNull);
      expect(insight.paymentMethodBreakdown.length, 2);
    });

    test('detects latte factor when small expenses reach threshold count', () {
      final month = DateTime(2026, 11, 1);
      final now = DateTime(2026, 11, 10);
      final smallTxs = [
        for (int i = 0; i < 3; i++)
          Transaction(
            id: 's$i',
            type: 'expense',
            amount: 20000,
            categoryId: 'c1',
            date: DateTime(2026, 11, i + 1),
            paymentMethod: 'qris',
            createdAt: now,
            updatedAt: now,
          ),
      ];

      final insight = computeMonthlyInsight(
        month: month,
        now: now,
        currentTransactions: smallTxs,
        prevTransactions: const [],
        categories: const [],
      );

      expect(insight.latteFactor, isNotNull);
      expect(insight.latteFactor!.count, 3);
      expect(insight.latteFactor!.totalAmount, 60000);
      expect(insight.paymentMethodBreakdown.single.method, 'qris');
      expect(insight.paymentMethodBreakdown.single.net, -60000);
    });
  });

  group('parseQuickTextOffline', () {
    test('parses multiple Indonesian transactions with units and methods', () {
      final parsed = parseQuickTextOffline(
        'parkir 5rb cash, makan siang 28rb qris, dapat bonus 1.5jt debit',
      );
      expect(parsed.length, 3);
      expect(parsed[0].amount, 5000);
      expect(parsed[0].paymentMethod, 'cash');
      expect(parsed[0].type, 'expense');
      expect(parsed[1].amount, 28000);
      expect(parsed[1].paymentMethod, 'qris');
      expect(parsed[2].amount, 1500000);
      expect(parsed[2].type, 'income');
      expect(parsed[2].paymentMethod, 'debit');
    });
  });

  group('extractPriceMemory', () {
    test('extracts itemized receipt prices sorted by newest date', () {
      final now = DateTime(2026, 11, 19);
      final txs = [
        Transaction(
          id: 't1',
          type: 'expense',
          amount: 45000,
          categoryId: 'c1',
          date: DateTime(2026, 11, 10),
          paymentMethod: 'qris',
          aiRawResponse:
              '{"store_name":"Kopi Kenangan","items":[{"name":"Kopi Susu","price":22000,"qty":2}]}',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final entries = extractPriceMemory(txs);
      expect(entries.length, 1);
      expect(entries.first.itemName, 'Kopi Susu');
      expect(entries.first.price, 22000);
      expect(entries.first.qty, 2);
      expect(entries.first.storeName, 'Kopi Kenangan');
    });
  });
}
