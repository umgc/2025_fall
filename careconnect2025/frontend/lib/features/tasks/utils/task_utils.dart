import 'dart:collection';
import 'dart:convert';

import 'package:table_calendar/table_calendar.dart';

import '../models/task_model.dart';

/// =============================
/// TaskUtils
/// =============================
/// Utility class for common task-related operations:
/// - Normalizing API data into [Task] model-friendly structures
/// - Grouping tasks by date for calendar display
/// - Normalizing dates to midnight (for consistent comparisons)
class TaskUtils {
  /// Normalize raw task map values (from API or DB) into expected formats.
  ///
  /// Handles:
  /// - Converts `date` strings without `T` into ISO-like strings
  /// - Parses `daysOfWeek` stringified JSON into `List<bool>`
  /// - Maps legacy `completed` field into `isComplete`
  ///
  /// Returns the normalized map, ready to feed into [Task.fromJson].
  static Map<String, dynamic> normalizeTaskMap(Map<String, dynamic> map) {
    if (map['date'] is String) {
      final d = map['date'];
      if (!d.contains('T')) map['date'] = d.replaceFirst(' ', 'T');
    }
    final dow = map['daysOfWeek'];
    if (dow is String) {
      try {
        map['daysOfWeek'] = List<bool>.from(jsonDecode(dow));
      } catch (_) {
        map['daysOfWeek'] = [];
      }
    }
    if (map['isComplete'] == null && map['completed'] != null) {
      map['isComplete'] = map['completed'];
    }
    return map;
  }

  /// Group a list of [Task] objects by their normalized date (midnight).
  ///
  /// - Uses [isSameDay] from `table_calendar` for equality
  /// - Custom hashCode ensures unique keys for year/month/day combos
  /// - Deduplicates tasks by `(task.id + task.date)`
  ///
  /// Useful for feeding into `TableCalendar` or other date-based UIs.
  static LinkedHashMap<DateTime, List<Task>> groupTasksByDate(
    List<Task> tasks,
  ) {
    final grouped = LinkedHashMap<DateTime, List<Task>>(
      equals: isSameDay,
      hashCode: (date) => date.day * 1000000 + date.month * 10000 + date.year,
    );

    for (final task in tasks) {
      final key = DateTime(task.date.year, task.date.month, task.date.day);

      // Deduplicate by (task.id + task.date)
      final existing = grouped.putIfAbsent(key, () => []);
      if (!existing.any((t) => t.id == task.id && t.date == task.date)) {
        existing.add(task);
      }
    }
    return grouped;
  }

  /// Normalize a [DateTime] by stripping out hours, minutes, and seconds.
  ///
  /// Example:
  ///   2025-09-30 14:35 → 2025-09-30 00:00
  ///
  /// Ensures consistency for comparisons, calendar keys, etc.
  static DateTime normalizeDate(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }
}
