import 'package:catat_uang_pribadi/features/transactions/domain/transaction_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty query keeps every row', () {
    expect(
      matchesLedgerQuery(
        query: '   ',
        note: 'kopi',
        categoryName: 'Makanan',
        paymentLabel: 'Tunai',
        amount: 12000,
      ),
      isTrue,
    );
  });

  test('matches note, category, payment label, or amount digits', () {
    expect(
      matchesLedgerQuery(
        query: 'Indomaret',
        note: 'belanja indomaret',
        categoryName: 'Belanja',
        paymentLabel: 'QRIS',
        amount: 50000,
      ),
      isTrue,
    );
    expect(
      matchesLedgerQuery(
        query: 'qris',
        note: '',
        categoryName: 'Makanan',
        paymentLabel: 'QRIS',
        amount: 1,
      ),
      isTrue,
    );
    expect(
      matchesLedgerQuery(
        query: '50000',
        note: null,
        categoryName: 'Lainnya',
        paymentLabel: 'Tunai',
        amount: 50000,
      ),
      isTrue,
    );
    expect(
      matchesLedgerQuery(
        query: 'gaji',
        note: 'kopi',
        categoryName: 'Makanan',
        paymentLabel: 'Tunai',
        amount: 15000,
      ),
      isFalse,
    );
  });
}
