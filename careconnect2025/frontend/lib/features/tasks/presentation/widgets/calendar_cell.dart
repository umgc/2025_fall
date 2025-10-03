import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_utils.dart';
import 'package:flutter/material.dart';

/// A single day cell in the MonthView calendar.
class CalendarCell extends StatelessWidget {
  final DateTime date;
  final List<CalendarEventData<Task>> events;
  final bool isToday;
  final bool isInMonth;
  final bool isWeekend;
  final bool isSelected;

  const CalendarCell({
    super.key,
    required this.date,
    required this.events,
    required this.isToday,
    required this.isInMonth,
    required this.isWeekend,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? Colors.green
              : (isToday ? theme.colorScheme.primary : theme.dividerColor),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            "${date.day}",
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: isInMonth
                  ? theme.colorScheme.onSurface
                  : theme.disabledColor,
            ),
          ),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: events.take(4).map((e) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TaskTypeUtils.getColor(e.event?.taskType),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
