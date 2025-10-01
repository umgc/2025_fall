import 'package:flutter/material.dart';

// =============================
// TaskTypeUtils.dart
// =============================
///Moving task Types into utility class for use across code base
class TaskTypeUtils {
  static final Map<String, Color> taskTypeColors = {
    'medication': Colors.red,
    'appointment': Colors.blue,
    'exercise': Colors.green,
    'general': Colors.deepOrange,
    'lab': Colors.purple,
    'pharmacy': Colors.teal,
  };

  /// Map used to change icon used for certain types of task
  static final Map<String, IconData> taskTypeIcons = {
    'medication': Icons.medication,
    'appointment': Icons.event,
    'exercise': Icons.fitness_center,
    'general': Icons.task,
    'lab': Icons.science,
    'pharmacy': Icons.local_pharmacy,
  };

  /// Get a color safely with fallback
  static Color getColor(String? type) {
    if (type == null) return Colors.deepOrange;
    return taskTypeColors[type.toLowerCase()] ?? Colors.deepOrange;
  }

  /// Get icon safely
  static IconData getIcon(String? type) {
    if (type == null) return taskTypeIcons['general']!;
    return taskTypeIcons[type.toLowerCase()] ?? taskTypeIcons['general']!;
  }

  /// Get an alphabetized list of task type keys
  static List<String> getSortedTypes() {
    final keys = taskTypeColors.keys.toList();
    keys.sort();
    return keys;
  }
}
