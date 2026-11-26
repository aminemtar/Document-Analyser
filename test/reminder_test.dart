import 'package:documind_ai/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 12, 3);

  test('future event gets a day-before and a day-of reminder at 09:00', () {
    final moments = reminderMoments(day, DateTime(2026, 11, 26, 12));
    expect(moments, [DateTime(2026, 12, 2, 9), DateTime(2026, 12, 3, 9)]);
  });

  test('day-before already passed leaves only the day-of reminder', () {
    final moments = reminderMoments(day, DateTime(2026, 12, 2, 10));
    expect(moments, [DateTime(2026, 12, 3, 9)]);
  });

  test('event today after 09:00 has nothing left to schedule', () {
    expect(reminderMoments(day, DateTime(2026, 12, 3, 9, 30)), isEmpty);
  });

  test('day-before rolls back across a month boundary', () {
    final moments =
        reminderMoments(DateTime(2026, 12, 1), DateTime(2026, 11, 20));
    expect(moments.first, DateTime(2026, 11, 30, 9));
  });
}
