import 'package:intl/intl.dart';

String formatCurrency(int amount) {
  final formatter = NumberFormat('#,##0', 'id');
  return 'Rp ${formatter.format(amount)}';
}
