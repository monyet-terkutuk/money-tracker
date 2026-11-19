import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catat_uang_pribadi/core/utils/currency_formatter.dart';

void main() {
  test('ThousandsSeparatorInputFormatter formats digits with dots', () {
    final formatter = ThousandsSeparatorInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(
        text: '20000000',
        selection: TextSelection.collapsed(offset: 8),
      ),
    );
    expect(result.text, '20.000.000');
    expect(result.selection.baseOffset, 10);
  });

  test('parseFormattedAmount and formatNumberInput round-trip cleanly', () {
    expect(formatNumberInput(20000000), '20.000.000');
    expect(parseFormattedAmount('20.000.000'), 20000000);
    expect(parseFormattedAmount(''), isNull);
  });
}
