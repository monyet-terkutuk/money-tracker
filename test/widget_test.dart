import 'package:flutter_test/flutter_test.dart';

import 'package:catat_uang_pribadi/core/utils/constants.dart';
import 'package:catat_uang_pribadi/features/scan/ai_parser_service.dart';

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
        raw: '{"total_amount":15000}',
      );
      expect(result.storeName, 'Toko A');
      expect(result.date, '2024-01-15');
      expect(result.totalAmount, 15000);
      expect(result.paymentMethod, 'qris');
      expect(result.raw, '{"total_amount":15000}');
    });
  });
}
