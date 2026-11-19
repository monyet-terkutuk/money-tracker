import 'package:catat_uang_pribadi/features/recurring/domain/recurring_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clamps the due day to the last day of the month', () {
    expect(
      occurrenceDate(2026, 2, 31),
      DateTime(2026, 2, 28),
    );
    expect(
      occurrenceDate(2024, 2, 31),
      DateTime(2024, 2, 29),
    );
  });

  test('horizon stops at today unless the next month is open', () {
    final now = DateTime(2026, 11, 19);
    expect(postingHorizon(DateTime(2026, 9), now), DateTime(2026, 11));
    expect(postingHorizon(DateTime(2026, 12), now), DateTime(2026, 12));
    expect(postingHorizon(DateTime(2027, 3), now), DateTime(2026, 11));
  });

  test('months stay inside the start and horizon', () {
    expect(
      monthsInclusive(DateTime(2026, 10, 20), DateTime(2026, 12)).toList(),
      [
        DateTime(2026, 10),
        DateTime(2026, 11),
        DateTime(2026, 12),
      ],
    );
  });
}
