import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy', 'id').format(date);
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy', 'id').format(date);
}

String formatMonthYearShort(int month, int year) {
  return DateFormat('MMM yyyy', 'id').format(DateTime(year, month));
}
