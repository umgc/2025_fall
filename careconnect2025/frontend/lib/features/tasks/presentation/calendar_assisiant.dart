// =============================
// CalendarAssistantScreen
// =============================

import 'dart:collection';
import 'dart:convert';

import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/widgets/app_bar_helper.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

// =============================
// TaskCopyWith
// =============================
extension TaskCopyWith on Task {
  Task copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? date,
    TimeOfDay? timeOfDay,
    int? userId,
    bool? isComplete,
    String? frequency,
    int? interval,
    int? count,
    List<bool>? daysOfWeek,
    String? taskType,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      userId: userId ?? this.userId,
      isComplete: isComplete ?? this.isComplete,
      notifications: this.notifications, // keep existing notifications
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      count: count ?? this.count,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      taskType: taskType ?? this.taskType,
    );
  }
}

/// Utilities for task normalization & grouping
class TaskUtils {
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

  /// Normalize a date to local midnight (drops hours/minutes/seconds).
  static DateTime normalizeDate(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }
}

// =============================
// RecurrenceUtils
// =============================
/// Utilities for building recurring tasks consistently
class RecurrenceUtils {
  static Task buildTask({
    required Task baseTask,
    bool? isRecurring,
    String? recurrenceType, // "Daily", "Weekly", "Monthly", "Yearly"
    List<bool>? daysOfWeek,
    int? interval,
    int? count,
    DateTime? startDate,
    DateTime? endDate,
    int? dayOfMonth,
  }) {
    String? frequency;
    int? intervalToSend = interval;
    int? countToSend = count;

    // Preserve original task type safely
    final normalizedTaskType = baseTask.taskType?.toLowerCase();

    // Default effective start date
    DateTime effectiveDate = (startDate ?? baseTask.date).toLocal();
    // Normalize end date if provided
    DateTime? normalizedEndDate = endDate != null
        ? TaskUtils.normalizeDate(endDate)
        : null;

    if (isRecurring == true && recurrenceType != null) {
      switch (recurrenceType.toLowerCase()) {
        case "daily":
          frequency = "daily";
          intervalToSend = (intervalToSend == null || intervalToSend < 1)
              ? 1
              : intervalToSend;

          if (normalizedEndDate != null) {
            final daysBetween = normalizedEndDate
                .difference(effectiveDate)
                .inDays;
            countToSend = (daysBetween ~/ intervalToSend) + 1;
          } else {
            countToSend ??= 30; // fallback: 30 days if no end date
          }
          break;

        case "weekly":
          frequency = "weekly";
          intervalToSend = (intervalToSend == null || intervalToSend < 1)
              ? 1
              : intervalToSend;

          if (normalizedEndDate != null) {
            final totalWeeks =
                (normalizedEndDate.difference(effectiveDate).inDays ~/ 7) + 1;

            if (daysOfWeek != null && daysOfWeek.any((d) => d)) {
              final selectedDays = daysOfWeek.where((d) => d).length;
              countToSend = totalWeeks * selectedDays;
            } else {
              countToSend = totalWeeks;
            }
          } else {
            countToSend ??= 4; // default 4 weeks if no end date
          }
          break;

        case "monthly":
          frequency = "monthly";
          intervalToSend = (intervalToSend == null || intervalToSend < 1)
              ? 1
              : intervalToSend;

          if (dayOfMonth != null) {
            final daysInMonth = DateUtils.getDaysInMonth(
              effectiveDate.year,
              effectiveDate.month,
            );
            final dom = dayOfMonth.clamp(1, daysInMonth);
            effectiveDate = DateTime(
              effectiveDate.year,
              effectiveDate.month,
              dom,
            );
          }

          if (normalizedEndDate != null) {
            final months =
                (normalizedEndDate.year - effectiveDate.year) * 12 +
                (normalizedEndDate.month - effectiveDate.month);
            countToSend = (months ~/ intervalToSend) + 1;
          } else {
            countToSend ??= 12; // default: 12 months
          }
          break;

        case "yearly":
          frequency = "yearly";
          intervalToSend = (intervalToSend == null || intervalToSend < 1)
              ? 1
              : intervalToSend;

          if (normalizedEndDate != null) {
            final years = normalizedEndDate.year - effectiveDate.year;
            countToSend = (years ~/ intervalToSend) + 1;
          } else {
            countToSend ??= 5; // default: 5 years
          }
          break;
      }
    }
    return baseTask.copyWith(
      date: effectiveDate,
      frequency: frequency,
      interval: intervalToSend,
      count: countToSend,
      daysOfWeek: daysOfWeek,
    );
  }
}

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

/// =============================
/// Calendar Assistant Screen
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
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool _filtersExpanded = false;
  Set<String> _selectedTypes = {};
  Set<int> _selectedPatients = {};
  Map<int, String> patientNames = {};

  Map<DateTime, List<Task>> _filteredTasks = {};

  Map<DateTime, List<Task>> tasks = LinkedHashMap(
    equals: isSameDay,
    hashCode: (date) => date.day * 1000000 + date.month * 10000 + date.year,
  );
  void _applyFilters() {
    setState(() {
      _filteredTasks = {};
      tasks.forEach((day, dayTasks) {
        final keepers = dayTasks.where((task) {
          if (_selectedTypes.isNotEmpty &&
              !_selectedTypes.contains(task.taskType ?? "general")) {
            return false;
          }
          if (_selectedPatients.isNotEmpty &&
              (task.userId == null ||
                  !_selectedPatients.contains(task.userId))) {
            return false;
          }
          return true;
        }).toList();

        if (keepers.isNotEmpty) {
          _filteredTasks[day] = keepers;
        }
      });
    });
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

  /// Render a day cell with border + colored dots for tasks
  Widget _buildDayCell(DateTime day, List<Task> dayTasks, Color borderColor) {
    const maxVisibleDots = 5;
    final displayTasks = dayTasks.take(maxVisibleDots).toList();

    final taskDots = [
      for (var task in displayTasks)
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TaskTypeUtils.getColor(task.taskType ?? "general"),
          ),
        ),
      if (dayTasks.length > maxVisibleDots)
        Text(
          '+${dayTasks.length - maxVisibleDots}',
          style: const TextStyle(fontSize: 8),
        ),
    ];

    return SizedBox(
      height: 90,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("${day.day}"),
            const SizedBox(height: 4),
            Wrap(spacing: 2, runSpacing: 2, children: taskDots),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _loadTasksFromDb();
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
        allTasks.addAll(await _fetchTasksForPatient(user.id));
      } else if (user.isCaregiver) {
        patientNames.clear();
        final patientsResponse = await ApiService.getCaregiverPatients(user.id);
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

      setState(() {
        tasks = TaskUtils.groupTasksByDate(allTasks);
        _filteredTasks = Map.from(tasks); // initialize filters with everything
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

            // Expand recurrences
            final expanded = baseTask.expandOccurrences();
            tasks.addAll(expanded);
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

  /// Build fucntion to actual make the Calendar Assistant
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        drawer: const CommonDrawer(currentRoute: '/calendar'),
        appBar: AppBarHelper.createAppBar(context, title: 'Calendar Assistant'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Filters + Today button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collapsible Filter Panel
                    Flexible(
                      fit: FlexFit.tight,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Filters",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _filtersExpanded
                                          ? Icons.expand_more
                                          : Icons.chevron_right,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _filtersExpanded = !_filtersExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              if (_filtersExpanded) ...[
                                const Divider(),
                                // Filter by Type
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: TaskTypeUtils.getSortedTypes()
                                        .map((type) {
                                          return FilterChip(
                                            label: Text(
                                              type[0].toUpperCase() +
                                                  type.substring(1),
                                            ),
                                            selected: _selectedTypes.contains(
                                              type,
                                            ),
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _selectedTypes.add(type);
                                                } else {
                                                  _selectedTypes.remove(type);
                                                }
                                              });
                                              _applyFilters();
                                            },
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Filter by Patient (only if caregiver)
                                if (Provider.of<UserProvider>(
                                      context,
                                      listen: false,
                                    ).user?.isCaregiver ??
                                    false)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Patients"),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: patientNames.entries.map((
                                            entry,
                                          ) {
                                            return FilterChip(
                                              label: Text(entry.value),
                                              selected: _selectedPatients
                                                  .contains(entry.key),
                                              onSelected: (selected) {
                                                setState(() {
                                                  if (selected) {
                                                    _selectedPatients.add(
                                                      entry.key,
                                                    );
                                                  } else {
                                                    _selectedPatients.remove(
                                                      entry.key,
                                                    );
                                                  }
                                                });
                                                _applyFilters();
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.clear),
                                    label: const Text("Clear Filters"),
                                    onPressed: () {
                                      setState(() {
                                        _selectedTypes.clear();
                                        _selectedPatients.clear();
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Today Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.today),
                      label: const Text("Today"),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime.now();
                          _selectedDay = DateTime.now();
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Calendar
              TableCalendar<Task>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) =>
                    _filteredTasks[DateTime(day.year, day.month, day.day)] ??
                    [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                rowHeight: 100,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                calendarStyle: const CalendarStyle(markersMaxCount: 0),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalized = TaskUtils.normalizeDate(day);
                    final dayTasks = _filteredTasks[normalized] ?? [];
                    return _buildDayCell(day, dayTasks, Colors.grey);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final normalized = TaskUtils.normalizeDate(day);
                    final dayTasks = _filteredTasks[normalized] ?? [];
                    return _buildDayCell(day, dayTasks, Colors.blue);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final normalized = TaskUtils.normalizeDate(day);
                    final dayTasks = _filteredTasks[normalized] ?? [];
                    return _buildDayCell(day, dayTasks, Colors.green);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Legend
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 16,
                  children: TaskTypeUtils.taskTypeColors.entries
                      .map(
                        (e) => _buildLegendDot(
                          e.value,
                          e.key[0].toUpperCase() + e.key.substring(1),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Task list for selected day
              if (_selectedDay != null) ...[
                Builder(
                  builder: (_) {
                    final normalized = TaskUtils.normalizeDate(_selectedDay!);
                    final dayTasks = [...?_filteredTasks[normalized] ?? []];

                    if (dayTasks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No tasks for this day"),
                      );
                    }

                    // Sort chronologically by timeOfDay
                    dayTasks.sort((a, b) {
                      if (a.timeOfDay != null && b.timeOfDay != null) {
                        final aMinutes =
                            a.timeOfDay!.hour * 60 + a.timeOfDay!.minute;
                        final bMinutes =
                            b.timeOfDay!.hour * 60 + b.timeOfDay!.minute;
                        return aMinutes.compareTo(bMinutes);
                      }
                      if (a.timeOfDay != null) return -1;
                      if (b.timeOfDay != null) return 1;
                      return a.name.compareTo(b.name);
                    });

                    return Column(
                      children: dayTasks.map((task) {
                        final assignedName = task.userId != null
                            ? patientNames[task.userId] ?? "Unknown Patient"
                            : "Unassigned";

                        return ListTile(
                          leading: Icon(
                            TaskTypeUtils.getIcon(task.taskType),
                            color: TaskTypeUtils.getColor(task.taskType),
                          ),
                          title: Text(
                            task.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.timeOfDay != null
                                    ? " ${task.timeOfDay!.format(context)}"
                                    : " All day",
                              ),
                              if (assignedName.isNotEmpty &&
                                  assignedName != "Unassigned")
                                Text("👤 $assignedName"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Edit Task',
                                onPressed: () => _editTask(task),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Remove Task',
                                onPressed: () => _removeTask(task),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Select a day to view tasks"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// This fucntion is used to add a task to the CareConnect system
  Future<void> _addTask() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;
    // Preload patients if caregiver
    List<Map<String, dynamic>> patients = [];
    if (user.isCaregiver) {
      final response = await ApiService.getCaregiverPatients(user.id);
      if (response.statusCode == 200) {
        patients = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    }
    // Show dialog
    if (!mounted) return;
    final draftTask = await showDialog<Task>(
      context: context,
      builder: (_) => TaskFormDialog(
        isCaregiver: user.isCaregiver,
        patients: patients,
        defaultPatientId: user.isPatient ? user.id : null,
        initialDate: _selectedDay,
      ),
    );

    if (draftTask == null) return;
    final newTask = RecurrenceUtils.buildTask(baseTask: draftTask);
    try {
      final response = await ApiService.createTaskV2(
        newTask.userId!,
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

  /// This function is to edit tasks in the CareConnect system displayed by the Calendar Assistant
  Future<void> _editTask(Task task) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    // Refresh task from backend
    try {
      final freshResponse = await ApiService.getTaskByIdV2(task.id);
      if (freshResponse.statusCode == 200) {
        task = Task.fromJson(jsonDecode(freshResponse.body));
        task = task.copyWith(
          date: TaskUtils.normalizeDate(task.date.toLocal()),
        );
      }
    } catch (e) {
      debugPrint("Error refreshing task ${task.id}: $e");
    }

    // Preload patients if caregiver
    List<Map<String, dynamic>> patients = [];
    if (user.isCaregiver) {
      final response = await ApiService.getCaregiverPatients(user.id);
      if (response.statusCode == 200) {
        patients = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    }

    // Show edit form
    if (!mounted) return;
    final editedTask = await showDialog<Task>(
      context: context,
      builder: (_) => TaskFormDialog(
        initialTask: task,
        isCaregiver: user.isCaregiver,
        patients: patients,
        defaultPatientId: user.isPatient ? user.id : task.userId,
        initialDate: _selectedDay,
      ),
    );

    if (editedTask == null) return;

    //normalize recurrence
    final newTask = RecurrenceUtils.buildTask(baseTask: editedTask);
    try {
      final response = await ApiService.editTaskV2(
        newTask.id,
        newTask.toJson(),
      );

      if (response.statusCode == 200) {
        await _loadTasksFromDb();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task updated successfully")),
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

  /// This function is to remove tasks in the CareConnect system displayed by the Calendar Assistant
  Future<void> _removeTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: Text("Are you sure you want to delete '${task.name}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteTaskV2(task.id);

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _loadTasksFromDb();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Task '${task.name}' deleted")));
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

// =============================
// TaskFormDialog.dart
// =============================
/// Since Add and Edit use the same form for tasks that logic is broken up here into two forms one being the TaskFormDialog and the other being the RecurrenceForm.
/// This allows functionality of the forms to be chared across the code.
class TaskFormDialog extends StatefulWidget {
  final Task? initialTask;
  final bool isCaregiver;
  final List<Map<String, dynamic>> patients;
  final int? defaultPatientId;
  final DateTime? initialDate;

  const TaskFormDialog({
    super.key,
    this.initialTask,
    required this.isCaregiver,
    required this.patients,
    this.defaultPatientId,
    this.initialDate,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  TimeOfDay? selectedTime;
  int? selectedPatientId;
  String? selectedTaskType;
  // Pull task types directly here
  late final List<String> taskTypes = TaskTypeUtils.getSortedTypes();

  // Recurrence state
  bool isRecurring = false;
  String? recurrenceType;
  List<bool>? daysOfWeek;
  int? interval;
  int? count;
  DateTime? startDate;
  DateTime? endDate;
  int? dayOfMonth;

  @override
  void initState() {
    super.initState();

    final t = widget.initialTask;

    titleController = TextEditingController(text: t?.name ?? '');
    descriptionController = TextEditingController(text: t?.description ?? '');
    selectedTime = t?.timeOfDay;
    selectedPatientId = widget.defaultPatientId ?? t?.userId;
    //If editing and taskType is valid, keep it
    if (t != null &&
        t.taskType != null &&
        taskTypes.contains(t.taskType!.toLowerCase())) {
      selectedTaskType = t.taskType!.toLowerCase();
    } else {
      // Otherwise default to "general"
      selectedTaskType = taskTypes.contains("general")
          ? "general"
          : taskTypes.first;
    }
    // ensure Save button re-checks when text changes
    titleController.addListener(() => setState(() {}));

    if (t != null) {
      recurrenceType = _inferRecurrenceTypeFromTask(t);
      isRecurring = recurrenceType != null;
      daysOfWeek = t.daysOfWeek;
      interval = t.interval;
      count = t.count;
      startDate = t.date;
      if (recurrenceType == "Monthly") {
        dayOfMonth = t.date.day;
      }

      // compute end date if missing
      if (count != null &&
          count! > 0 &&
          startDate != null &&
          recurrenceType != null) {
        final iv = (interval == null || interval! < 1) ? 1 : interval!;
        switch (recurrenceType!.toLowerCase()) {
          case "daily":
            endDate = startDate!.add(Duration(days: (count! - 1) * iv));
            break;
          case "weekly":
            endDate = startDate!.add(Duration(days: (count! - 1) * 7 * iv));
            break;
          case "monthly":
            endDate = DateTime(
              startDate!.year,
              startDate!.month + (count! - 1) * iv,
              startDate!.day,
            );
            break;
          case "yearly":
            endDate = DateTime(
              startDate!.year + (count! - 1) * iv,
              startDate!.month,
              startDate!.day,
            );
            break;
        }
      }
    } else {
      // Use initialDate from the calendar if passed, otherwise fallback to now
      startDate = TaskUtils.normalizeDate(widget.initialDate ?? DateTime.now());
    }
  }

  String? _inferRecurrenceTypeFromTask(Task t) {
    if (t.daysOfWeek?.any((d) => d) ?? false) return "Weekly";
    switch (t.frequency?.toLowerCase()) {
      case "daily":
        return "Daily";
      case "weekly":
        return "Weekly";
      case "monthly":
        return "Monthly";
      case "yearly":
        return "Yearly";
      default:
        return null;
    }
  }

  /// validation logic of the form's save button
  bool get canSave {
    // Must have a name
    if (titleController.text.trim().isEmpty) return false;

    if (isRecurring) {
      // Must have a recurrence type
      if (recurrenceType == null || recurrenceType!.isEmpty) return false;
      // Weekly: require at least one day
      if (recurrenceType!.toLowerCase() == "weekly") {
        if (daysOfWeek == null || !daysOfWeek!.any((d) => d)) {
          return false;
        }
      }
      // Must have an end condition (endDate or count)
      if ((endDate == null || endDate!.isBefore(startDate ?? DateTime.now())) &&
          (count == null || count! <= 0)) {
        return false;
      }
    }

    return true;
  }

  ///Building the task form based on Add or Edit function
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? "Add Task" : "Edit Task"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Task Type",
                border: OutlineInputBorder(),
              ),
              initialValue:
                  selectedTaskType != null &&
                      ![
                        "daily",
                        "weekly",
                        "monthly",
                        "yearly",
                      ].contains(selectedTaskType!.toLowerCase())
                  ? selectedTaskType
                  : null,
              items: taskTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedTaskType = val),
            ),

            const SizedBox(height: 16),
            // Time picker
            Row(
              children: [
                const Text("Time: "),
                Text(
                  selectedTime != null
                      ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                      : "Not set",
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => selectedTime = picked);
                  },
                  child: const Text("Pick Time"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// If caregiver then allow assignment to patient. If patient always assigned to themseleves.
            // Caregiver dropdown
            if (widget.isCaregiver)
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: "Assign to Patient",
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                initialValue: selectedPatientId,
                items: widget.patients.map((p) {
                  return DropdownMenuItem<int>(
                    value: p['patient']?['id'],
                    child: Text(
                      "${p['patient']?['firstName']} ${p['patient']?['lastName']}",
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedPatientId = val),
              ),

            const SizedBox(height: 16),

            // Recurrence form
            RecurrenceForm(
              initialIsRecurring: isRecurring,
              initialRecurrenceType: recurrenceType,
              initialDaysOfWeek: daysOfWeek,
              initialInterval: interval,
              initialCount: count,
              initialStartDate: startDate,
              initialEndDate: endDate,
              initialDayOfMonth: dayOfMonth,
              onChanged:
                  ({
                    bool? isRecurring,
                    String? recurrenceType,
                    List<bool>? daysOfWeek,
                    int? interval,
                    int? count,
                    DateTime? startDate,
                    DateTime? endDate,
                    int? dayOfMonth,
                  }) {
                    setState(() {
                      this.isRecurring = isRecurring ?? false;
                      this.recurrenceType = recurrenceType;
                      this.daysOfWeek = daysOfWeek;
                      this.interval = interval;
                      this.count = count;
                      this.startDate = startDate ?? this.startDate;
                      this.endDate = endDate;
                      this.dayOfMonth = dayOfMonth;
                    });
                  },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: canSave
              ? () {
                  final rawTask = Task(
                    id: widget.initialTask?.id ?? -1,
                    name: titleController.text,
                    description: descriptionController.text,
                    date: startDate ?? DateTime.now(),
                    timeOfDay: selectedTime,
                    userId: selectedPatientId,
                    isComplete: widget.initialTask?.isComplete ?? false,
                    notifications: widget.initialTask?.notifications,
                    frequency: recurrenceType,
                    interval: interval,
                    count: count,
                    daysOfWeek: daysOfWeek,
                    taskType:
                        (selectedTaskType ??
                                widget.initialTask?.taskType ??
                                "general")
                            .toLowerCase(),
                  );

                  final finalTask = RecurrenceUtils.buildTask(
                    baseTask: rawTask,
                    isRecurring: isRecurring,
                    recurrenceType: recurrenceType,
                    daysOfWeek: daysOfWeek,
                    interval: interval,
                    count: count,
                    startDate: rawTask.date,
                    endDate: endDate,
                    dayOfMonth: dayOfMonth,
                  );

                  Navigator.pop(context, finalTask);
                }
              : null, //disabled if invalid
          child: const Text("Save"),
        ),
      ],
    );
  }
}

// =============================
// RecurrenceForm Widget
// =============================
///This widget allows mutiple places in the code to use the reoccurnce form portion, and ressue its functionality needed specifically for reoccurences.
class RecurrenceForm extends StatefulWidget {
  final void Function({
    bool? isRecurring,
    String? recurrenceType,
    List<bool>? daysOfWeek,
    int? interval,
    int? count,
    DateTime? startDate,
    DateTime? endDate,
    int? dayOfMonth,
  })
  onChanged;

  final bool initialIsRecurring;
  final String? initialRecurrenceType;
  final List<bool>? initialDaysOfWeek;
  final int? initialInterval;
  final int? initialCount;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? initialDayOfMonth;

  const RecurrenceForm({
    super.key,
    required this.onChanged,
    this.initialIsRecurring = false,
    this.initialRecurrenceType,
    this.initialDaysOfWeek,
    this.initialInterval,
    this.initialCount,
    this.initialStartDate,
    this.initialEndDate,
    this.initialDayOfMonth,
  });

  @override
  State<RecurrenceForm> createState() => _RecurrenceFormState();
}

class _RecurrenceFormState extends State<RecurrenceForm> {
  bool isRecurring = false;
  String? recurrenceType;
  List<bool>? daysOfWeek;
  int? interval;
  int? count;
  DateTime? startDate;
  DateTime? endDate;
  int? dayOfMonth;

  @override
  void initState() {
    super.initState();
    isRecurring = widget.initialIsRecurring;
    recurrenceType = widget.initialRecurrenceType;
    daysOfWeek = widget.initialDaysOfWeek ?? List.filled(7, false);
    interval = widget.initialInterval;
    count = widget.initialCount;
    //Normalize incoming dates
    startDate = widget.initialStartDate != null
        ? TaskUtils.normalizeDate(widget.initialStartDate!)
        : null;

    endDate = widget.initialEndDate != null
        ? TaskUtils.normalizeDate(widget.initialEndDate!)
        : null;
    dayOfMonth = widget.initialDayOfMonth;
  }

  //validation flags for inline error messages
  bool get isMissingType =>
      isRecurring && (recurrenceType == null || recurrenceType!.isEmpty);

  bool get isWeeklyInvalid =>
      recurrenceType == "Weekly" && !(daysOfWeek?.any((d) => d) ?? false);

  bool get isMissingEndCondition =>
      isRecurring &&
      ((endDate == null ||
              (startDate != null && endDate!.isBefore(startDate!))) &&
          (count == null || count! <= 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text("Recurring Task"),
          value: isRecurring,
          onChanged: (val) {
            setState(() => isRecurring = val ?? false);
            widget.onChanged(
              isRecurring: isRecurring,
              recurrenceType: recurrenceType,
              daysOfWeek: daysOfWeek,
              interval: interval,
              count: count,
              startDate: startDate,
              endDate: endDate,
              dayOfMonth: dayOfMonth,
            );
          },
        ),
        if (isRecurring) ...[
          const SizedBox(height: 8),
          // Recurrence type dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Recurrence Type",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            initialValue: recurrenceType,
            items: [
              "Daily",
              "Weekly",
              "Monthly",
              "Yearly",
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) {
              setState(() => recurrenceType = val);
              widget.onChanged(
                isRecurring: isRecurring,
                recurrenceType: recurrenceType,
                daysOfWeek: daysOfWeek,
                interval: interval,
                count: count,
                startDate: startDate,
                endDate: endDate,
                dayOfMonth: dayOfMonth,
              );
            },
          ),
          if (isMissingType)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "Please select a recurrence type",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          // Weekly days-of-week picker
          if (recurrenceType == "Weekly") ...[
            const SizedBox(height: 12),
            const Text("Select Days of Week"),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                return FilterChip(
                  label: Text(days[i]),
                  selected: daysOfWeek?[i] ?? false,
                  onSelected: (selected) {
                    setState(() => daysOfWeek?[i] = selected);
                    widget.onChanged(
                      isRecurring: isRecurring,
                      recurrenceType: recurrenceType,
                      daysOfWeek: daysOfWeek,
                      interval: interval,
                      count: count,
                      startDate: startDate,
                      endDate: endDate,
                      dayOfMonth: dayOfMonth,
                    );
                  },
                );
              }),
            ),
            if (isWeeklyInvalid)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  "Please select at least one day of the week",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],

          // Monthly → day-of-month picker
          if (recurrenceType == "Monthly") ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Day of Month:"),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: dayOfMonth,
                  hint: const Text("Select Day"),
                  items: List.generate(31, (i) => i + 1)
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => dayOfMonth = val);
                    widget.onChanged(
                      isRecurring: isRecurring,
                      recurrenceType: recurrenceType,
                      daysOfWeek: daysOfWeek,
                      interval: interval,
                      count: count,
                      startDate: startDate,
                      endDate: endDate,
                      dayOfMonth: dayOfMonth,
                    );
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Start date picker
          Row(
            children: [
              Text(
                startDate != null
                    ? "Starts: ${startDate!.toLocal().toString().split(' ')[0]}"
                    : "No start date set",
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(DateTime.now().year + 5),
                  );
                  if (picked != null) {
                    setState(() => startDate = TaskUtils.normalizeDate(picked));
                    widget.onChanged(
                      isRecurring: isRecurring,
                      recurrenceType: recurrenceType,
                      daysOfWeek: daysOfWeek,
                      interval: interval,
                      count: count,
                      startDate: startDate,
                      endDate: endDate,
                      dayOfMonth: dayOfMonth,
                    );
                  }
                },
                child: const Text("Pick Start Date"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // End date picker
          if (recurrenceType != "Yearly") ...[
            Row(
              children: [
                Text(
                  endDate != null
                      ? "Ends: ${endDate!.toLocal().toString().split(' ')[0]}"
                      : "No end date set",
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 5),
                    );
                    if (picked != null) {
                      setState(() => endDate = TaskUtils.normalizeDate(picked));
                      widget.onChanged(
                        isRecurring: isRecurring,
                        recurrenceType: recurrenceType,
                        daysOfWeek: daysOfWeek,
                        interval: interval,
                        count: count,
                        startDate: startDate,
                        endDate: endDate,
                        dayOfMonth: dayOfMonth,
                      );
                    }
                  },
                  child: const Text("Pick End Date"),
                ),
              ],
            ),
          ] else if (recurrenceType == "Yearly") ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Ends in Year:"),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: endDate?.year,
                  hint: const Text("Select Year"),
                  items: List.generate(10, (i) => DateTime.now().year + i)
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null && startDate != null) {
                      setState(() {
                        endDate = DateTime(
                          val,
                          startDate!.month,
                          startDate!.day,
                        );
                        count = (val - startDate!.year) + 1; // auto-calc count
                      });
                      widget.onChanged(
                        isRecurring: isRecurring,
                        recurrenceType: recurrenceType,
                        daysOfWeek: daysOfWeek,
                        interval: interval,
                        count: count,
                        startDate: startDate,
                        endDate: endDate,
                        dayOfMonth: dayOfMonth,
                      );
                    }
                  },
                ),
              ],
            ),
          ],

          if (isMissingEndCondition)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "Please provide an end date of the series",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }
}
