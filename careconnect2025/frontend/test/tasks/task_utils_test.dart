import 'dart:convert';

import 'package:care_connect_app/features/tasks/utils/task_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskUtils', () {
    test('normalizeTaskMap fixes date string missing "T"', () {
      final input = {'date': '2025-10-19 12:00:00'};
      final result = TaskUtils.normalizeTaskMap(Map.from(input));

      expect(result['date'], equals('2025-10-19T12:00:00'));
    });

    test('normalizeTaskMap leaves proper ISO date unchanged', () {
      final input = {'date': '2025-10-19T08:30:00'};
      final result = TaskUtils.normalizeTaskMap(Map.from(input));

      expect(result['date'], equals('2025-10-19T08:30:00'));
    });

    test('normalizeTaskMap decodes valid daysOfWeek JSON string', () {
      final input = {
        'daysOfWeek': jsonEncode([
          true,
          false,
          true,
          false,
          false,
          true,
          false,
        ]),
      };
      final result = TaskUtils.normalizeTaskMap(Map.from(input));

      expect(result['daysOfWeek'], isA<List<bool>>());
      expect(result['daysOfWeek'][0], isTrue);
      expect(result['daysOfWeek'][1], isFalse);
      expect(result['daysOfWeek'][2], isTrue);
    });

    test('normalizeTaskMap handles invalid daysOfWeek JSON safely', () {
      final input = {'daysOfWeek': 'not-a-json'};
      final result = TaskUtils.normalizeTaskMap(Map.from(input));

      expect(result['daysOfWeek'], isA<List>());
      expect(result['daysOfWeek'], isEmpty);
    });

    test('normalizeTaskMap maps legacy "completed" to "isComplete"', () {
      final input = {'completed': true};
      final result = TaskUtils.normalizeTaskMap(Map.from(input));

      expect(result['isComplete'], isTrue);
    });

    test('normalizeTaskMap leaves isComplete if already set', () {
      final input = {'isComplete': false, 'completed': true};
      final result = TaskUtils.normalizeTaskMap(Map.from(input));

      expect(result['isComplete'], isFalse);
    });

    test('normalizeDate strips time components to midnight', () {
      final date = DateTime(2025, 10, 19, 15, 42, 33);
      final normalized = TaskUtils.normalizeDate(date);

      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.year, date.year);
      expect(normalized.month, date.month);
      expect(normalized.day, date.day);
    });

    test('isSameDay returns true for same date ignoring time', () {
      final a = DateTime(2025, 10, 19, 8, 30);
      final b = DateTime(2025, 10, 19, 23, 59);
      expect(TaskUtils.isSameDay(a, b), isTrue);
    });

    test('isSameDay returns false for different dates', () {
      final a = DateTime(2025, 10, 19);
      final b = DateTime(2025, 10, 20);
      expect(TaskUtils.isSameDay(a, b), isFalse);
    });

    test('isSameDay returns false if second date is null', () {
      final a = DateTime(2025, 10, 19);
      expect(TaskUtils.isSameDay(a, null), isFalse);
    });

    test('getStartOfWeek returns correct Monday-start date', () {
      // Example: Wednesday (weekday=3) → should backtrack to Monday
      final wednesday = DateTime(2025, 10, 15); // Wed
      final mondayStart = TaskUtils.getStartOfWeek(
        wednesday,
        mondayStart: true,
      );

      expect(mondayStart.weekday, equals(DateTime.monday));
      expect(mondayStart.isBefore(wednesday), isTrue);
      expect(mondayStart.day, equals(13)); // Monday of that week
    });

    test('getStartOfWeek returns correct Sunday-start date', () {
      // Example: Wednesday (weekday=3) → should backtrack to Sunday (12th)
      final wednesday = DateTime(2025, 10, 15);
      final sundayStart = TaskUtils.getStartOfWeek(
        wednesday,
        mondayStart: false,
      );

      expect(sundayStart.weekday, equals(DateTime.sunday));
      expect(sundayStart.day, equals(12));
    });

    test('getStartOfWeek normalizes to midnight', () {
      final date = DateTime(2025, 10, 19, 18, 45);
      final start = TaskUtils.getStartOfWeek(date);
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);
    });
  });
}
