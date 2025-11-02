import 'dart:convert';

import '../models/task_model.dart';

/// =============================
/// TaskUtils
/// =============================
/// Utility class for common task-related operations:
/// - Normalizing API data into [Task] model-friendly structures
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

  /// Normalize a [DateTime] by stripping out hours, minutes, and seconds.
  ///
  /// Example:
  ///   2025-09-30 14:35 → 2025-09-30 00:00
  ///
  /// Ensures consistency for comparisons, calendar keys, etc.
  static DateTime normalizeDate(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  // In task_utils.dart (inside class TaskUtils)
  static bool isSameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Put this inside _CalendarAssistantScreenState (not inside build)
  static DateTime getStartOfWeek(DateTime date, {bool mondayStart = true}) {
    // normalize to midnight
    final d = TaskUtils.normalizeDate(date);

    if (mondayStart) {
      // Monday = 1, Sunday = 7  → subtract (weekday - 1)
      return d.subtract(Duration(days: d.weekday - 1));
    } else {
      // Sunday-start week: Sunday = 7 treated as 0
      final offset = d.weekday % 7; // Sunday -> 0, Mon -> 1, ...
      return d.subtract(Duration(days: offset));
    }
  }
}
