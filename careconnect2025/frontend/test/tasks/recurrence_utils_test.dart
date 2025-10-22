import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/utils/recurrence_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurrenceUtils.buildTask()', () {
    final baseTask = Task(
      id: 1,
      name: "Test Task",
      description: "Base recurring task",
      date: DateTime(2025, 1, 1),
      taskType: "Vitals",
      assignedPatientId: 1,
    );

    test('builds a daily recurrence correctly with end date', () {
      final task = RecurrenceUtils.buildTask(
        baseTask: baseTask,
        isRecurring: true,
        recurrenceType: "Daily",
        interval: 1,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
      );

      expect(task.frequency, "daily");
      expect(task.interval, 1);
      expect(task.count, 10);
      expect(task.date, DateTime(2025, 1, 1));
    });

    test('builds a weekly recurrence with selected days', () {
      final daysOfWeek = [
        true,
        false,
        false,
        false,
        false,
        false,
        true,
      ]; // Sun + Sat
      final task = RecurrenceUtils.buildTask(
        baseTask: baseTask,
        isRecurring: true,
        recurrenceType: "Weekly",
        daysOfWeek: daysOfWeek,
        interval: 1,
        startDate: DateTime(2025, 1, 1), // Wed
        endDate: DateTime(2025, 1, 31),
      );

      expect(task.frequency, "weekly");
      expect(task.interval, 1);
      expect(task.count, isNonZero);
    });

    test('builds a monthly recurrence correctly', () {
      final task = RecurrenceUtils.buildTask(
        baseTask: baseTask,
        isRecurring: true,
        recurrenceType: "Monthly",
        interval: 1,
        startDate: DateTime(2025, 1, 15),
        endDate: DateTime(2025, 5, 15),
        dayOfMonth: 15,
      );

      expect(task.frequency, "monthly");
      expect(task.interval, 1);
      expect(task.count, 5);
      expect(task.date.day, 15);
    });

    test('builds a yearly recurrence correctly', () {
      final task = RecurrenceUtils.buildTask(
        baseTask: baseTask,
        isRecurring: true,
        recurrenceType: "Yearly",
        interval: 1,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2030, 1, 1),
      );

      expect(task.frequency, "yearly");
      expect(task.interval, 1);
      expect(task.count, 6);
    });

    test('returns same task when not recurring', () {
      final task = RecurrenceUtils.buildTask(
        baseTask: baseTask,
        isRecurring: false,
      );

      expect(task.frequency, isNull);
      expect(task.interval, isNull);
      expect(task.count, isNull);
    });
  });

  group('RecurrenceUtils.calculateCount()', () {
    test('calculates daily correctly', () {
      final count = RecurrenceUtils.calculateCount(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        frequency: "daily",
        interval: 1,
      );
      expect(count, 10);
    });

    test('calculates weekly with interval', () {
      final count = RecurrenceUtils.calculateCount(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 2, 1),
        frequency: "weekly",
        interval: 1,
      );
      expect(count, greaterThan(3)); // ~4 or 5
    });

    test('calculates monthly count', () {
      final count = RecurrenceUtils.calculateCount(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        frequency: "monthly",
        interval: 1,
      );
      expect(count, 12);
    });

    test('calculates yearly count', () {
      final count = RecurrenceUtils.calculateCount(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2030, 1, 1),
        frequency: "yearly",
        interval: 1,
      );
      expect(count, 6);
    });
  });

  group('RecurrenceUtils.calculateEndDate()', () {
    test('daily frequency adds correct days', () {
      final endDate = RecurrenceUtils.calculateEndDate(
        startDate: DateTime(2025, 1, 1),
        frequency: "daily",
        interval: 1,
        count: 10,
      );
      expect(endDate, DateTime(2025, 1, 10));
    });

    test('weekly frequency adds correct weeks', () {
      final endDate = RecurrenceUtils.calculateEndDate(
        startDate: DateTime(2025, 1, 1),
        frequency: "weekly",
        interval: 1,
        count: 4,
      );
      expect(endDate, DateTime(2025, 1, 22));
    });

    test('monthly frequency adds correct months', () {
      final endDate = RecurrenceUtils.calculateEndDate(
        startDate: DateTime(2025, 1, 15),
        frequency: "monthly",
        interval: 1,
        count: 3,
      );
      expect(endDate, DateTime(2025, 3, 15));
    });

    test('yearly frequency adds correct years', () {
      final endDate = RecurrenceUtils.calculateEndDate(
        startDate: DateTime(2025, 1, 1),
        frequency: "yearly",
        interval: 2,
        count: 3,
      );
      expect(endDate, DateTime(2029, 1, 1));
    });
  });
}
