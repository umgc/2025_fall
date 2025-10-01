// =============================
// CalendarAssistantScreen
// =============================

import 'dart:collection';
import 'dart:convert';

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
import 'package:table_calendar/table_calendar.dart';

import 'widgets/task_form_dialog.dart';

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

  /// Apply current filters (task types, patients) to the full task set
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
              (task.assignedPatientId == null ||
                  !_selectedPatients.contains(task.assignedPatientId))) {
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

              // ==========================
              // CALENDAR
              // ==========================
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

              // ==========================
              // LEGEND (task type dots)
              // ==========================
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

              // ==========================
              // TASK LIST (for selected day)
              // ==========================
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
                        final assignedName = task.assignedPatientId != null
                            ? patientNames[task.assignedPatientId] ??
                                  "Unknown Patient"
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
