import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String formatCurrency(int amount) {
  final formatter = NumberFormat('#,##0', 'id');
  return 'Rp ${formatter.format(amount)}';
}

String formatNumberInput(int amount) {
  if (amount <= 0) return '';
  return NumberFormat('#,##0', 'id').format(amount);
}

int? parseFormattedAmount(String text) {
  final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return null;
  return int.tryParse(digitsOnly);
}

String formatCompactCurrency(int amount) {
  if (amount.abs() >= 1000000000) {
    return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
  }
  if (amount.abs() >= 1000000) {
    return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
  }
  if (amount.abs() >= 1000) {
    return 'Rp ${(amount / 1000).round()}rb';
  }
  return 'Rp $amount';
}

/// Formats numeric input with Indonesian dot thousand separators (e.g. 20.000.000).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat('#,##0', 'id');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final parsed = int.tryParse(digits);
    if (parsed == null) return oldValue;

    final formatted = _formatter.format(parsed);
    final digitsBeforeCursor = newValue.selection.baseOffset <= 0
        ? 0
        : newValue.text
            .substring(0, newValue.selection.baseOffset.clamp(0, newValue.text.length))
            .replaceAll(RegExp(r'[^0-9]'), '')
            .length;

    int newOffset = 0;
    int seenDigits = 0;
    while (newOffset < formatted.length && seenDigits < digitsBeforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(formatted[newOffset])) {
        seenDigits++;
      }
      newOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
