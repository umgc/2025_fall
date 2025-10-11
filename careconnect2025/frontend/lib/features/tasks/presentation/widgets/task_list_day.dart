import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// =============================
/// TaskListDay Widget
/// =============================
///
/// Displays all tasks scheduled for a single day as a vertical list of [ListTile]s.
/// - Shows task icon, name, time, and assigned patient.
/// - Provides edit and delete actions through callbacks.
/// - Tasks are sorted by time (if present), then by name.
///
/// Used in the Calendar Assistant screen when the "Daily" view is active.
class TaskListDay extends StatelessWidget {
  /// Events from the calendar controller (converted into tasks).
  final List<CalendarEventData<Task>> events;

  /// Map of patient IDs to display names (used for "assigned to" labels).
  final Map<int, String> patientNames;

  /// Callback when the user taps the edit button on a task.
  final void Function(Task) onEdit;

  /// Callback when the user taps the delete button on a task.
  final void Function(Task) onDelete;

  const TaskListDay({
    super.key,
    required this.events,
    required this.patientNames,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<TaskTypeManager>();
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No tasks for this day"),
      );
    }

    // Extract Task objects from the calendar events
    // and sort them by time first, then by name.
    final tasks = events.map((e) => e.event!).toList()
      ..sort((a, b) {
        if (a.timeOfDay != null && b.timeOfDay != null) {
          final aMins = a.timeOfDay!.hour * 60 + a.timeOfDay!.minute;
          final bMins = b.timeOfDay!.hour * 60 + b.timeOfDay!.minute;
          return aMins.compareTo(bMins);
        }
        if (a.timeOfDay != null) return -1;
        if (b.timeOfDay != null) return 1;
        return a.name.compareTo(b.name);
      });
    // Render a vertical column of ListTiles, one per task.
    return Column(
      children: tasks.map((task) {
        final assignedName = task.assignedPatientId != null
            ? patientNames[task.assignedPatientId] ?? "Unknown Patient"
            : "Unassigned";

        final color = manager.getColor(task.taskType);
        final icon = manager.getIcon(task.taskType);
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            task.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.timeOfDay != null
                    ? task.timeOfDay!.format(context)
                    : "All day",
              ),
              if (assignedName.isNotEmpty && assignedName != "Unassigned")
                Text("👤 $assignedName"),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => onEdit(task),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(task),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
