import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_utils.dart';
import 'package:flutter/material.dart';

/// Task list view for a single day.
class TaskListDay extends StatelessWidget {
  final List<CalendarEventData<Task>> events;
  final Map<int, String> patientNames;
  final void Function(Task) onEdit;
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
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No tasks for this day"),
      );
    }

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

    return Column(
      children: tasks.map((task) {
        final assignedName = task.assignedPatientId != null
            ? patientNames[task.assignedPatientId] ?? "Unknown Patient"
            : "Unassigned";

        return ListTile(
          leading: Icon(
            TaskTypeUtils.getIcon(task.taskType),
            color: TaskTypeUtils.getColor(task.taskType),
          ),
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
