// =============================
// CalendarAssistantScreen
// =============================

import 'dart:convert';

import 'package:calendar_view/calendar_view.dart';
import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/features/tasks/utils/recurrence_utils.dart';
import 'package:care_connect_app/features/tasks/utils/task_type_utils.dart';
import 'package:care_connect_app/features/tasks/utils/task_utils.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/widgets/app_bar_helper.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/task_form_dialog.dart';

// View type enum
enum CalendarViewType { month, week, day }

/// =============================
/// Calendar Assistant Screen
/// - Displays tasks in a calendar view
/// - Supports filtering by type and patient
/// - Integrates with TaskFormDialog to add/edit tasks
/// =============================
class CalendarAssistantScreen extends StatefulWidget {
  const CalendarAssistantScreen({super.key});

  @override
  State<CalendarAssistantScreen> createState() =>
      _CalendarAssistantScreenState();
}

class _CalendarAssistantScreenState extends State<CalendarAssistantScreen> {
  bool isLoading = true;
  String? error;
  bool _filtersExpanded = false;
  Set<String> _selectedTypes = {};
  Set<int> _selectedPatients = {};
  Map<int, String> patientNames = {};
  DateTime? _selectedDay;

  late EventController<Task> _eventController;

  // Current view state
  CalendarViewType _currentView = CalendarViewType.month;

  @override
  void initState() {
    super.initState();
    _eventController = EventController<Task>();
    _selectedDay = DateTime.now();
    _loadTasksFromDb();
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  ///This function is used across the assistant to query task information from the DB
  Future<void> _loadTasksFromDb() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) {
        setState(() {
          error = "User not logged in.";
          isLoading = false;
        });
        return;
      }

      final List<Task> allTasks = [];

      if (user.isPatient) {
        // Build their display name
        if (user.patientId != null) {
          final safeName = (user.name ?? "").trim();
          patientNames[user.patientId!] = safeName.isNotEmpty
              ? safeName
              : "Unknown Patient";
        }
        allTasks.addAll(await _fetchTasksForPatient(user.patientId!));
      } else if (user.isCaregiver) {
        patientNames.clear();
        final patientsResponse = await ApiService.getCaregiverPatients(
          user.caregiverId!,
        );
        if (patientsResponse.statusCode == 200) {
          final patients = json.decode(patientsResponse.body);
          for (final patient in patients) {
            final pid = patient['patient']?['id'];
            if (pid != null) {
              patientNames[pid] =
                  "${patient['patient']?['firstName']} ${patient['patient']?['lastName']}";
              allTasks.addAll(await _fetchTasksForPatient(pid));
            }
          }
        }
      }
      // Apply filters
      final filtered = allTasks.where((task) {
        if (_selectedTypes.isNotEmpty &&
            !_selectedTypes.contains(task.taskType ?? "general")) {
          return false;
        }
        if (_selectedPatients.isNotEmpty &&
            (task.assignedPatientId == null ||
                !_selectedPatients.contains(task.assignedPatientId))) {
          return false;
        }
        return true;
      }).toList();

      // Build CalendarEventData list
      final events = filtered.map((task) {
        return CalendarEventData<Task>(
          title: task.name,
          description: task.description,
          date: TaskUtils.normalizeDate(task.date),
          startTime: task.timeOfDay != null
              ? DateTime(
                  task.date.year,
                  task.date.month,
                  task.date.day,
                  task.timeOfDay!.hour,
                  task.timeOfDay!.minute,
                )
              : TaskUtils.normalizeDate(task.date),
          endTime: task.timeOfDay != null
              ? DateTime(
                  task.date.year,
                  task.date.month,
                  task.date.day,
                  task.timeOfDay!.hour,
                  task.timeOfDay!.minute + 30,
                )
              : TaskUtils.normalizeDate(
                  task.date,
                ).add(const Duration(hours: 1)),
          event: task,
        );
      }).toList();

      _eventController
        ..removeWhere((_) => true)
        ..addAll(events);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  /// Using V2 of endpoint, fetch the need task information
  Future<List<Task>> _fetchTasksForPatient(int patientId) async {
    final tasks = <Task>[];

    try {
      final response = await ApiService.getPatientTasksV2(patientId);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        for (final raw in data) {
          final map = TaskUtils.normalizeTaskMap(
            Map<String, dynamic>.from(raw),
          );

          try {
            final baseTask = Task.fromJson(map);
            baseTask.date = TaskUtils.normalizeDate(baseTask.date.toLocal());
            tasks.add(baseTask);
          } catch (e) {
            debugPrint("Error parsing task for patient $patientId: $e");
          }
        }
      } else {
        debugPrint(
          "Failed to fetch tasks for patient $patientId: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Exception while fetching tasks for patient $patientId: $e");
    }

    return tasks;
  }

  /// Build a small colored dot + label for the legend
  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildCalendarCell(
    DateTime date,
    List<CalendarEventData<Task>> events,
    bool isToday,
    bool isInMonth,
    bool isWeekend,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: TaskUtils.isSameDay(date, _selectedDay)
              ? Colors
                    .green // highlight selected
              : (isToday ? theme.colorScheme.primary : theme.dividerColor),
          width: TaskUtils.isSameDay(date, _selectedDay) ? 2 : 1,
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
              final task = e.event;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TaskTypeUtils.getColor(task?.taskType),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Render the timeline hour labels (respects theme & dark mode)
  Widget _themedTimeLabel(DateTime date) {
    final theme = Theme.of(context);
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final suffix = date.hour < 12 ? 'AM' : 'PM';
    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        '$hour12 $suffix',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Custom tile for events in Week/Day views
  Widget _buildEventTile(
    DateTime date,
    List<CalendarEventData<Task>> events,
    Rect boundary,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (events.isEmpty) return const SizedBox.shrink();

    final task = events.first.event; // use first event for display
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

  /// Main widget tree for the screen
  /// - Shows loading spinner while fetching
  /// - Renders filter panel, calendar, legend, and task list
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        drawer: const CommonDrawer(currentRoute: '/calendar'),
        appBar: AppBarHelper.createAppBar(context, title: 'Calendar Assistant'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return CalendarControllerProvider<Task>(
      controller: _eventController,
      child: Scaffold(
        drawer: const CommonDrawer(currentRoute: '/calendar'),
        appBar: AppBarHelper.createAppBar(
          context,
          title: 'Calendar Assistant',
          additionalActions: [
            TextButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Task",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _addTask,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildFiltersRow(),

              // ------------------
              // View switcher
              // ------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<CalendarViewType>(
                      value: _currentView,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _currentView = val;
                            _selectedDay ??= DateTime.now();
                            if (val == CalendarViewType.week &&
                                _selectedDay != null) {
                              _selectedDay = _getStartOfWeek(_selectedDay!);
                            }
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: CalendarViewType.month,
                          child: Text("Monthly"),
                        ),
                        DropdownMenuItem(
                          value: CalendarViewType.week,
                          child: Text("Weekly"),
                        ),
                        DropdownMenuItem(
                          value: CalendarViewType.day,
                          child: Text("Daily"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ------------------
              // Calendar widget
              // ------------------
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);

                      switch (_currentView) {
                        case CalendarViewType.month:
                          return MonthView<Task>(
                            controller: _eventController,
                            initialMonth: _selectedDay,
                            cellAspectRatio: 1.5,
                            cellBuilder: _buildCalendarCell,
                            headerStyle: HeaderStyle(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                              ),
                              headerTextStyle:
                                  (theme.textTheme.titleMedium ??
                                          const TextStyle(fontSize: 16))
                                      .copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                              leftIcon: Icon(
                                Icons.chevron_left,
                                color: theme.colorScheme.onSurface,
                              ),
                              rightIcon: Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            weekDayBuilder: (day) {
                              final labels = [
                                "M",
                                "T",
                                "W",
                                "T",
                                "F",
                                "S",
                                "S",
                              ];
                              return Center(
                                child: Text(
                                  labels[day % 7],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                            onCellTap: (events, date) {
                              setState(() => _selectedDay = date);
                            },
                            onEventTap: (event, date) {
                              final task = event.event;
                              if (task != null) _editTask(task);
                            },
                          );

                        case CalendarViewType.week:
                          return WeekView<Task>(
                            controller: _eventController,
                            initialDay: _selectedDay,
                            onPageChange: (date, _) {
                              setState(() {
                                _selectedDay = _getStartOfWeek(date);
                              });
                            },
                            backgroundColor: theme.colorScheme.surface,
                            hourIndicatorSettings: HourIndicatorSettings(
                              color: theme.dividerColor,
                              height: 1,
                              lineStyle: LineStyle.solid,
                            ),
                            halfHourIndicatorSettings: HourIndicatorSettings(
                              color: theme.dividerColor.withOpacity(0.4),
                              height: 1,
                              lineStyle: LineStyle.dashed,
                            ),
                            timeLineWidth: 56,
                            timeLineBuilder: _themedTimeLabel,
                            eventTileBuilder: _buildEventTile,
                            headerStyle: HeaderStyle(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                              ),
                              headerTextStyle:
                                  (theme.textTheme.titleMedium ??
                                          const TextStyle(fontSize: 16))
                                      .copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                              leftIcon: Icon(
                                Icons.chevron_left,
                                color: theme.colorScheme.onSurface,
                              ),
                              rightIcon: Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            weekDayBuilder: (date) {
                              final theme = Theme.of(context);

                              final isSelected = TaskUtils.isSameDay(
                                date,
                                _selectedDay,
                              );
                              final isToday = TaskUtils.isSameDay(
                                date,
                                DateTime.now(),
                              );

                              final labels = [
                                "M",
                                "T",
                                "W",
                                "T",
                                "F",
                                "S",
                                "S",
                              ];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDay = date;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.green
                                          : (isToday
                                                ? theme.colorScheme.primary
                                                : theme.dividerColor),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: theme.colorScheme.surface,
                                  ),
                                  child: Center(
                                    child: Text(
                                      labels[date.weekday - 1],
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              );
                            },

                            onEventTap: (events, date) {
                              if (events.isNotEmpty) {
                                final task = events.first.event;
                                if (task != null) _editTask(task);
                              }
                            },
                          );

                        case CalendarViewType.day:
                          return DayView<Task>(
                            controller: _eventController,
                            initialDay: _selectedDay,
                            onPageChange: (date, _) {
                              setState(() {
                                _selectedDay = date;
                              });
                            },
                            backgroundColor: theme.colorScheme.surface,
                            hourIndicatorSettings: HourIndicatorSettings(
                              color: theme.dividerColor,
                              height: 1,
                              lineStyle: LineStyle.solid,
                            ),
                            halfHourIndicatorSettings: HourIndicatorSettings(
                              color: theme.dividerColor.withOpacity(0.4),
                              height: 1,
                              lineStyle: LineStyle.dashed,
                            ),
                            timeLineWidth: 56,
                            timeLineBuilder: _themedTimeLabel,
                            eventTileBuilder: _buildEventTile,
                            headerStyle: HeaderStyle(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                              ),
                              headerTextStyle:
                                  (theme.textTheme.titleMedium ??
                                          const TextStyle(fontSize: 16))
                                      .copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                              leftIcon: Icon(
                                Icons.chevron_left,
                                color: theme.colorScheme.onSurface,
                              ),
                              rightIcon: Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            onEventTap: (events, date) {
                              if (events.isNotEmpty) {
                                final task = events.first.event;
                                if (task != null) _editTask(task);
                              }
                            },
                          );
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Legend
              Wrap(
                spacing: 16,
                children: TaskTypeUtils.taskTypeColors.entries
                    .map((e) => _buildLegendDot(e.value, e.key))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Task list changes depending on view
              if (_selectedDay != null)
                _currentView == CalendarViewType.week
                    ? _buildTaskListForWeek(_selectedDay!)
                    : _buildTaskListForDay(_selectedDay!),
            ],
          ),
        ),
      ),
    );
  }

  // Put this inside _CalendarAssistantScreenState (not inside build)
  DateTime _getStartOfWeek(DateTime date, {bool mondayStart = true}) {
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

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 👈 key change
                children: [
                  ListTile(
                    title: const Text("Filters"),
                    trailing: IconButton(
                      icon: Icon(
                        _filtersExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                      ),
                      onPressed: () {
                        setState(() => _filtersExpanded = !_filtersExpanded);
                      },
                    ),
                  ),
                  if (_filtersExpanded) ...[
                    // -----------------------
                    // Task Type Filters
                    // -----------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: Text(
                        "Task Types",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: SizedBox(
                        // 👈 force full width
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: TaskTypeUtils.getSortedTypes().map((type) {
                            return FilterChip(
                              label: Text(
                                type[0].toUpperCase() + type.substring(1),
                              ),
                              selected: _selectedTypes.contains(type),
                              onSelected: (sel) {
                                setState(() {
                                  sel
                                      ? _selectedTypes.add(type)
                                      : _selectedTypes.remove(type);
                                });
                                _loadTasksFromDb();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // -----------------------
                    // Patient Filters
                    // -----------------------
                    if (Provider.of<UserProvider>(
                          context,
                          listen: false,
                        ).user?.isCaregiver ??
                        false)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                            child: Text(
                              "Patients",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: SizedBox(
                              // 👈 same fix here
                              width: double.infinity,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.start,
                                children: patientNames.entries.map((entry) {
                                  return FilterChip(
                                    label: Text(entry.value),
                                    selected: _selectedPatients.contains(
                                      entry.key,
                                    ),
                                    onSelected: (sel) {
                                      setState(() {
                                        sel
                                            ? _selectedPatients.add(entry.key)
                                            : _selectedPatients.remove(
                                                entry.key,
                                              );
                                      });
                                      _loadTasksFromDb();
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // -----------------------
                    // Clear button
                    // -----------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text("Clear"),
                        onPressed: () {
                          setState(() {
                            _selectedTypes.clear();
                            _selectedPatients.clear();
                          });
                          _loadTasksFromDb();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.today),
            label: const Text("Today"),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListForWeek(DateTime weekDate) {
    final weekStart = weekDate.subtract(
      Duration(days: weekDate.weekday - 1),
    ); // Monday
    final weekEnd = weekStart.add(const Duration(days: 7));

    final events = _eventController.events.where((e) {
      return e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(weekEnd);
    }).toList();

    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No tasks this week"),
      );
    }

    final tasks = events.map((e) => e.event!).toList()
      ..sort((a, b) {
        final cmpDate = a.date.compareTo(b.date);
        if (cmpDate != 0) return cmpDate;

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
                "${task.date.month}/${task.date.day} • "
                "${task.timeOfDay != null ? task.timeOfDay!.format(context) : "All day"}",
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
                onPressed: () => _editTask(task),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeTask(task),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskListForDay(DateTime day) {
    final events = _eventController.getEventsOnDay(day);
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
                onPressed: () => _editTask(task),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeTask(task),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  // ==========================
  // TASK CRUD HANDLERS
  // ==========================

  /// Add a new task to the CareConnect system
  /// - Opens the [TaskFormDialog] for user input
  /// - Preloads patient list if caregiver
  /// - Submits new task to backend via [ApiService.createTaskV2]
  /// - On success: refreshes tasks from DB and shows confirmation
  /// - On failure: shows error snackbar
  Future<void> _addTask() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;
    // Preload patients if caregiver
    List<Map<String, dynamic>> patients = [];
    if (user.isCaregiver) {
      final response = await ApiService.getCaregiverPatients(user.caregiverId!);
      if (response.statusCode == 200) {
        patients = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    }
    // Show dialog
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TaskFormDialog(
        isCaregiver: user.isCaregiver,
        patients: patients,
        defaultPatientId: user.isPatient ? user.patientId : null,
        initialDate: _selectedDay,
      ),
    );
    if (result == null) return;
    final draftTask = result['task'] as Task;
    final newTask = RecurrenceUtils.buildTask(baseTask: draftTask);

    try {
      final response = await ApiService.createTaskV2(
        newTask.assignedPatientId!,
        jsonEncode(newTask.toJson()),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        await _loadTasksFromDb();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task added successfully")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add task: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding task: $e")));
    }
  }

  /// Edit an existing task in the CareConnect system
  /// - Refreshes the latest version of the task from backend
  /// - Resolves series anchor date if task is part of a recurrence
  /// - Opens the [TaskFormDialog] for editing
  /// - Submits updates via [ApiService.editTaskV2]
  /// - Supports updating a single task or entire series
  Future<void> _editTask(Task task) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    if (task.id == null || task.id == -1) {
      debugPrint("Tried to edit a task without a valid ID");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot edit a task without an ID")),
      );
      return;
    }

    // Refresh task from backend
    try {
      final freshResponse = await ApiService.getTaskByIdV2(task.id!);
      if (freshResponse.statusCode == 200) {
        task = Task.fromJson(jsonDecode(freshResponse.body));
        task = task.copyWith(
          date: TaskUtils.normalizeDate(task.date.toLocal()),
        );
      }
    } catch (e) {
      debugPrint("Error refreshing task ${task.id}: $e");
    }

    DateTime seriesAnchorDate = task.date;
    if (task.parentTaskId != null) {
      try {
        final parentResp = await ApiService.getTaskByIdV2(task.parentTaskId!);
        if (parentResp.statusCode == 200) {
          final parent = Task.fromJson(jsonDecode(parentResp.body));
          seriesAnchorDate = TaskUtils.normalizeDate(parent.date.toLocal());
        }
      } catch (_) {}
    }

    // Preload patients if caregiver
    List<Map<String, dynamic>> patients = [];
    if (user.isCaregiver) {
      final response = await ApiService.getCaregiverPatients(user.caregiverId!);
      if (response.statusCode == 200) {
        patients = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    }

    // Show edit form
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TaskFormDialog(
        initialTask: task,
        isCaregiver: user.isCaregiver,
        patients: patients,
        defaultPatientId: user.isPatient
            ? user.patientId
            : task.assignedPatientId,
        initialDate: _selectedDay,
        seriesAnchorDate: seriesAnchorDate,
      ),
    );

    if (result == null) return;

    final editedTask = result['task'] as Task;
    final applyToSeries = result['applyToSeries'] as bool? ?? false;

    // normalize recurrence
    final newTask = RecurrenceUtils.buildTask(baseTask: editedTask);

    try {
      final response = await ApiService.editTaskV2(
        newTask.id!,
        newTask.toJson(),
        updateSeries: applyToSeries,
      );

      if (response.statusCode == 200) {
        await _loadTasksFromDb();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              applyToSeries
                  ? "Series updated successfully"
                  : "Task updated successfully",
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update task: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating task: $e")));
    }
  }

  /// Remove a task from the CareConnect system
  /// - Prompts user for confirmation
  /// - If task is part of a recurrence, offers option to delete entire series
  /// - Calls [ApiService.deleteTaskV2] with appropriate flag
  /// - On success: reloads tasks and shows confirmation
  Future<void> _removeTask(Task task) async {
    bool applyToSeries = false;

    final confirmed = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Confirm Delete"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Are you sure you want to delete '${task.name}'?"),
                  if (task.frequency != null || task.parentTaskId != null)
                    CheckboxListTile(
                      title: const Text("Delete entire series"),
                      value: applyToSeries,
                      onChanged: (val) {
                        setState(() => applyToSeries = val ?? false);
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, {
                    'confirmed': true,
                    'applyToSeries': applyToSeries,
                  }),
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == null || confirmed['confirmed'] != true) return;
    if (!mounted) return;

    final deleteSeries = confirmed['applyToSeries'] as bool? ?? false;

    if (task.id == null || task.id == -1) {
      debugPrint("Tried to remove a task without a valid ID");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot delete a task without an ID")),
      );
      return;
    }

    try {
      final response = await ApiService.deleteTaskV2(
        task.id!,
        deleteSeries: deleteSeries,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _loadTasksFromDb();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteSeries
                  ? "Task series deleted"
                  : "Task '${task.name}' deleted",
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete task: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting task: $e")));
    }
  }
}
