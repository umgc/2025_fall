import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_utils.dart';
import 'package:flutter/material.dart';

/// A styled tile for events in Day/Week views.
class EventTile extends StatelessWidget {
  final List<CalendarEventData<Task>> events;

  const EventTile({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final task = events.first.event;
    final color = TaskTypeUtils.getColor(task?.taskType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          Expanded(
            child: Text(
              task?.name ?? "Task",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
