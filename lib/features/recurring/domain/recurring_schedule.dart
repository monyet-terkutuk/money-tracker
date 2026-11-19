String periodKey(int year, int month) =>
    '$year-${month.toString().padLeft(2, '0')}';

DateTime occurrenceDate(int year, int month, int dayOfMonth) {
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = dayOfMonth.clamp(1, lastDay);
  return DateTime(year, month, day);
}

/// Fill missing bills through the current month.
/// The next month is included only when that is the month on screen.
DateTime postingHorizon(DateTime viewed, DateTime now) {
  final todayMonth = DateTime(now.year, now.month);
  final nextMonth = DateTime(now.year, now.month + 1);
  final viewedMonth = DateTime(viewed.year, viewed.month);
  if (viewedMonth.isAfter(nextMonth)) return todayMonth;
  if (viewedMonth.isAfter(todayMonth)) return viewedMonth;
  return todayMonth;
}

Iterable<DateTime> monthsInclusive(DateTime start, DateTime through) sync* {
  var cursor = DateTime(start.year, start.month);
  final end = DateTime(through.year, through.month);
  while (!cursor.isAfter(end)) {
    yield cursor;
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
}
