// Class: CalendarAssistantScreen
// Descritpion: Running the Calendar Assistant through notification and task systems of CareConnect

import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:care_connect_app/features/tasks/models/task_model.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/services/api_service.dart';
import 'package:care_connect_app/widgets/app_bar_helper.dart';
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarAssistantScreen extends StatefulWidget {
  const CalendarAssistantScreen({super.key});

  @override
  State<CalendarAssistantScreen> createState() =>
      _CalendarAssistantScreenState();
}

class _CalendarAssistantScreenState extends State<CalendarAssistantScreen> {
  //State variables for loading status and if errors have occured.
  bool isLoading = true;
  String? error;

  //Variables used throughout the  class for day selections of the user.
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  /// Store tasks grouped by day (with isSameDay logic)
  Map<DateTime, List<Task>> tasks = LinkedHashMap(
    equals: isSameDay,
    hashCode: (date) => date.day * 1000000 + date.month * 10000 + date.year,
  );

  // Map patientId -> patient name
  Map<int, String> patientNames = {};

  // Define task types and their colors
  final Map<String, Color> taskTypeColors = {
    'medication': Colors.red,
    'appointment': Colors.blue,
    'exercise': Colors.green,
    'general': Colors.deepOrange,
    'lab': Colors.purple,
    'pharmacy': Colors.teal,
    'medical': Colors.cyan,
  };

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _loadTasksFromDb();
  }

  //Function for making sure the Calendar displayed has updated DB information

  Future<void> _loadTasksFromDb() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    log("🛰️ Starting DB Query");

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
      if (user.isCaregiver) {
        // refresh patient name map each load
        patientNames.clear();
      }

      // Helper to normalize a raw map before Task.fromJson
      Map<String, dynamic> normalizeTaskMap(Map<String, dynamic> map) {
        // Normalize date string and keep it ISO-like
        if (map['date'] != null && map['date'] is String) {
          final d = map['date'] as String;
          // ensure ISO separator
          if (!d.contains('T')) {
            map['date'] = d.replaceFirst(' ', 'T');
          }
        }

        // Normalize daysOfWeek to List<bool>
        final dow = map['daysOfWeek'];
        if (dow == null || dow == "null") {
          map['daysOfWeek'] = [];
        } else if (dow is String) {
          try {
            map['daysOfWeek'] = List<bool>.from(jsonDecode(dow));
          } catch (_) {
            map['daysOfWeek'] = [];
          }
        }

        // Accept both 'isComplete' and 'completed'
        if (map['isComplete'] == null && map['completed'] != null) {
          map['isComplete'] = map['completed'];
        }

        return map;
      }

      // --- PATIENT FLOW ---
      if (user.isPatient) {
        print("🛰️ In the patient flow");
        final response = await ApiService.getPatientTasksV2(
          user.id,
        ).timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          for (final raw in data) {
            final map = normalizeTaskMap(Map<String, dynamic>.from(raw));
            try {
              final baseTask = Task.fromJson(map);
              // Ensure local time normalization
              baseTask.date = baseTask.date.toLocal();
              final expandedOccurrences = baseTask.expandOccurrences();
              print(
                "📅 Expanded ${baseTask.name}: ${expandedOccurrences.length} occurrences",
              );
              allTasks.addAll(expandedOccurrences);
            } catch (e) {
              log("Error parsing task: $e");
            }
          }
        }
      }
      // --- CAREGIVER FLOW ---
      else if (user.isCaregiver) {
        print("🛰️ In care giverflow");
        final patientsResponse = await ApiService.getCaregiverPatients(user.id);
        if (patientsResponse.statusCode == 200) {
          final List patients = json.decode(patientsResponse.body);

          for (final patient in patients) {
            final pid = patient['patient']?['id'];
            final firstName = patient['patient']?['firstName'] ?? '';
            final lastName = patient['patient']?['lastName'] ?? '';

            if (pid != null) {
              patientNames[pid] = "$firstName $lastName".trim();
            }
            if (pid == null) continue;

            final taskResponse = await ApiService.getPatientTasksV2(
              pid,
            ).timeout(const Duration(seconds: 30));
            if (taskResponse.statusCode == 200) {
              print("🛰️ Response body: ${taskResponse.body}");
              final List data = json.decode(taskResponse.body);
              for (final raw in data) {
                final map = normalizeTaskMap(Map<String, dynamic>.from(raw));
                try {
                  final task = Task.fromJson(map);
                  task.date = task.date.toLocal(); // UTC → local
                  final expanded = task.expandOccurrences();
                  print(
                    "📅 Expanded ${task.name}: ${expanded.length} occurrences",
                  );
                  for (var occ in expanded) {
                    print("   -> ${occ.date}");
                  }
                  allTasks.addAll(task.expandOccurrences());
                } catch (e) {
                  log("Error parsing caregiver task: $e");
                }
              }
            }
          }
        }
      }

      // --- GROUP TASKS BY DATE ---
      final grouped = LinkedHashMap<DateTime, List<Task>>(
        equals: isSameDay,
        hashCode: (date) => date.day * 1000000 + date.month * 10000 + date.year,
      );

      for (final task in allTasks) {
        final key = DateTime(task.date.year, task.date.month, task.date.day);
        print("📌 Grouping task ${task.name} on $key");
        grouped.putIfAbsent(key, () => []).add(task);
      }
      print("📊 Final grouped keys:");
      grouped.forEach((k, v) {
        print("   $k -> ${v.length} tasks");
      });

      if (!mounted) return;
      setState(() {
        tasks = grouped;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  //Things in UI functions succh as dart may need to be updated to match new UI requirements.
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        drawer: const CommonDrawer(currentRoute: '/calendar'),
        appBar: AppBarHelper.createAppBar(
          context,
          title: 'Calendar Assistant',
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Calendar ...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const CommonDrawer(currentRoute: '/calendar'),
      appBar: AppBarHelper.createAppBar(
        context,
        title: 'Calendar Assistant',
        centerTitle: true,
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
              TableCalendar<Task>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final key = DateTime(
                    day.year,
                    day.month,
                    day.day,
                  ); // normalize to midnight
                  return tasks[key] ?? [];
                },
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
                headerVisible: true,
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dayTasks = tasks[day] ?? [];
                    return _buildDayCell(day, dayTasks, Colors.grey);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final dayTasks = tasks[day] ?? [];
                    return _buildDayCell(day, dayTasks, Colors.blue);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final dayTasks = tasks[day] ?? [];
                    return _buildDayCell(day, dayTasks, Colors.green);
                  },
                ),
              ),

              const SizedBox(height: 16),
              // Task list with edit/remove buttons
              if (_selectedDay != null && tasks[_selectedDay] != null)
                ...tasks[_selectedDay]!.map((task) {
                  final assignedName = task.userId != null
                      ? patientNames[task.userId] ?? "Unknown Patient"
                      : "Unassigned";

                  return ListTile(
                    leading: const Icon(Icons.task),
                    title: Text(
                      "$assignedName: ${task.name}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Task',
                          onPressed: () => _editTask(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Remove Task',
                          onPressed: () => _removeTask(task),
                        ),
                      ],
                    ),
                  );
                })
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Select a day to view tasks"),
                ),

              const SizedBox(height: 16),

              // Legend
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 16,
                  children: taskTypeColors.entries
                      .map((e) => _buildLegendDot(e.value, e.key))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Function builds color legend based on available colors defined
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

  /// Map task type to color
  Color _getTaskColor(String type) {
    final key = type.toLowerCase();
    return taskTypeColors[key] ?? Colors.deepOrange;
  }

  /// Helper to render a day cell with border + task dots
  Widget _buildDayCell(DateTime day, List<Task> dayTasks, Color borderColor) {
    const maxVisibleDots = 5;
    List<Widget> taskDots = [];

    final displayTasks = dayTasks.take(maxVisibleDots).toList();
    for (var task in displayTasks) {
      taskDots.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getTaskColor(task.taskType ?? "general"),
          ),
        ),
      );
    }

    if (dayTasks.length > maxVisibleDots) {
      taskDots.add(
        Text(
          '+${dayTasks.length - maxVisibleDots}',
          style: const TextStyle(fontSize: 8),
        ),
      );
    }

    return SizedBox(
      height: 90, // taller cells
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
            Wrap(
              spacing: 2,
              runSpacing: 2,
              alignment: WrapAlignment.center,
              children: taskDots,
            ),
          ],
        ),
      ),
    );
  }

  //CRUD Fucntion for adding tasks through this display
  //Tasks can be added to the system through other features and will appear in the Calendar

  Future<void> _addTask() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;

    // Default to selected calendar day
    final selectedDate = DateTime(
      (_selectedDay ?? _focusedDay).year,
      (_selectedDay ?? _focusedDay).month,
      (_selectedDay ?? _focusedDay).day,
    );

    int? selectedPatientId = user.isPatient ? user.id : null;

    // Local holders for recurrence
    bool recIsRecurring = false;
    String? recType;
    List<bool>? recDaysOfWeek;
    DateTime? recStartDate;
    DateTime? recEndDate;
    int? recInterval;
    int? recCount;
    int? recDayOfMonth;

    // If caregiver, fetch patients for dropdown
    List<Map<String, dynamic>> patients = [];
    if (user.isCaregiver) {
      final response = await ApiService.getCaregiverPatients(user.id);
      if (response.statusCode == 200) {
        patients = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Add Task"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Task Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                          if (picked != null) {
                            setState(() => selectedTime = picked);
                          }
                        },
                        child: const Text("Pick Time"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Caregiver assignment dropdown
                  if (user.isPatient)
                    Text("Assigned to: ${user.name}")
                  else if (user.isCaregiver)
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Assign to Patient",
                        border: OutlineInputBorder(),
                      ),
                      value: selectedPatientId,
                      items: patients.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['patient']?['id'],
                          child: Text(
                            "${p['patient']?['firstName']} ${p['patient']?['lastName']}",
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedPatientId = val);
                      },
                    ),

                  const SizedBox(height: 16),

                  // Recurrence form
                  RecurrenceForm(
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
                            // update local state for validation
                            recIsRecurring = isRecurring ?? false;
                            recType = recurrenceType;
                          });

                          recType = recurrenceType;
                          recDaysOfWeek = daysOfWeek;
                          recInterval = interval;
                          recCount = count;
                          recStartDate = startDate;
                          recEndDate = endDate;
                          recDayOfMonth = dayOfMonth;
                        },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed:
                    (recIsRecurring && (recType == null || recType!.isEmpty))
                    ? null //disable if recurring but no type
                    : () {
                        if (user.isCaregiver && selectedPatientId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a patient"),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;
    DateTime effectiveDate = selectedDate;
    final patientId = user.isPatient ? user.id : selectedPatientId!;
    // Calculate recurrence fields if recurring
    if (recIsRecurring && recType != null && recEndDate != null) {
      switch (recType!.toLowerCase()) {
        case "daily":
          recInterval = (recInterval == null || recInterval! < 1)
              ? 1
              : recInterval;
          final DateTime baseStart = recStartDate ?? selectedDate;
          recCount ??=
              (recEndDate!.difference(baseStart).inDays ~/ recInterval!) + 1;
          break;
        case "weekly":
          recInterval = (recInterval == null || recInterval! < 1)
              ? 1
              : recInterval;
          if (recDaysOfWeek != null && recDaysOfWeek!.contains(true)) {
            int totalWeeks =
                recEndDate!.difference(selectedDate).inDays ~/ 7 + 1;
            int selectedDays = recDaysOfWeek!.where((d) => d).length;
            recCount ??= totalWeeks * selectedDays;
          } else {
            recCount ??= recEndDate!.difference(selectedDate).inDays ~/ 7 + 1;
          }
          break;

        case "monthly":
          recInterval = (recInterval == null || recInterval! < 1)
              ? 1
              : recInterval;
          int months =
              (recEndDate!.year - selectedDate.year) * 12 +
              (recEndDate!.month - selectedDate.month) +
              1;
          recCount ??= months;
          break;

        case "yearly":
          recInterval = (recInterval == null || recInterval! < 1)
              ? 1
              : recInterval;
          if (recStartDate != null && recEndDate != null) {
            // Use only the year difference regardless of month/day
            final startYear = recStartDate!.year;
            final endYear = recEndDate!.year;

            recCount = (endYear - startYear) + 1;

            // Ensure effectiveDate is set to the correct day/month from startDate
            effectiveDate = DateTime(
              startYear,
              recStartDate!.month,
              recStartDate!.day,
            );
          } else {
            recCount ??= 5; // fallback default
          }
          break;
      }
    }

    // Override base date if monthly recurrence specifies a day-of-month

    if (recStartDate != null) {
      effectiveDate = recStartDate!;
    }

    if (recType?.toLowerCase() == "monthly" && recEndDate != null) {
      final daysInMonth = DateUtils.getDaysInMonth(
        selectedDate.year,
        selectedDate.month,
      );
      final dom = recDayOfMonth!.clamp(1, daysInMonth);
      effectiveDate = DateTime(selectedDate.year, selectedDate.month, dom);
    }

    // Normalize recurrence fields
    String? frequencyToSend;
    String? taskTypeToSend;
    int? intervalToSend = recInterval;
    int? countToSend = recCount;

    if (recIsRecurring && recType != null) {
      switch (recType!.toLowerCase()) {
        case "daily":
          frequencyToSend = "daily";
          intervalToSend = 1;
          countToSend = (countToSend == null || countToSend < 1)
              ? ((recEndDate != null)
                    ? recEndDate!.difference(selectedDate).inDays + 1
                    : 30) // default 30
              : countToSend;
          taskTypeToSend = "frequency";
          break;

        case "weekly":
          frequencyToSend = "weekly";
          intervalToSend = (intervalToSend == null || intervalToSend < 1)
              ? 1
              : intervalToSend;
          countToSend ??= 4; // default 4 weeks
          taskTypeToSend =
              (recDaysOfWeek != null && recDaysOfWeek!.any((e) => e))
              ? "dayOfWeek"
              : "frequency";
          break;

        case "monthly":
          frequencyToSend = "monthly";
          intervalToSend = (intervalToSend == null || intervalToSend < 1)
              ? 1
              : intervalToSend;
          countToSend ??= 12;
          taskTypeToSend = "frequency";
          break;

        case "yearly":
          frequencyToSend = "yearly";
          intervalToSend = (intervalToSend == null || intervalToSend < 1)
              ? 1
              : intervalToSend;
          countToSend = (countToSend == null || countToSend < 1)
              ? 5
              : countToSend;
          taskTypeToSend = "frequency";
          break;
      }
    }
    // Build new task object
    final newTask = Task(
      id: -1,
      name: titleController.text,
      description: descriptionController.text,
      date: effectiveDate,
      timeOfDay: selectedTime,
      userId: patientId,
      isComplete: false,
      notifications: null,
      frequency: frequencyToSend,
      interval: intervalToSend,
      count: countToSend,
      daysOfWeek: recDaysOfWeek,
      taskType: taskTypeToSend,
    );
    print(
      "🧭 Creating task -> freq=$frequencyToSend interval=$intervalToSend count=$countToSend start=$effectiveDate",
    );
    try {
      print("🛰️ Response body:  ${jsonEncode(newTask.toJson())}");
      final response = await ApiService.createTaskV2(
        patientId,
        jsonEncode(newTask.toJson()),
      );

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

  /// helper function to calculate recurrence count
  int _calculateCount(
    String recurrenceType,
    int interval,
    DateTime startDate,
    DateTime endDate, {
    List<bool>? selectedDays,
  }) {
    switch (recurrenceType.toLowerCase()) {
      case "daily":
        return endDate.difference(startDate).inDays ~/ interval;
      case "weekly":
        if (selectedDays != null && selectedDays.contains(true)) {
          return _calculateWeeklyOccurrences(startDate, endDate, selectedDays);
        }
        return endDate.difference(startDate).inDays ~/ interval;
      case "monthly":
        return ((endDate.year - startDate.year) * 12 +
                endDate.month -
                startDate.month) ~/
            1;
      case "yearly":
        return endDate.year - startDate.year;
      default:
        return 1;
    }
  }

  /// helper function to calculate recurrence count per week
  int _calculateWeeklyOccurrences(
    DateTime startDate,
    DateTime endDate,
    List<bool> selectedDays, // [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
  ) {
    int count = 0;
    DateTime current = startDate;

    while (!current.isAfter(endDate)) {
      int weekdayIndex = current.weekday % 7;
      // Dart: Mon=1..Sun=7, so %7 shifts Sun to 0
      if (selectedDays[weekdayIndex]) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  //CRUD Fucntion for editing tasks through this display
  //Tasks can be edited to the system through other features and will appear in the Calendar

  Future<void> _editTask(Task task) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;
    // Refresh task from backend so we always use latest recurrence
    try {
      final freshResponse = await ApiService.getTaskByIdV2(task.id);
      if (freshResponse.statusCode == 200) {
        final freshTask = Task.fromJson(jsonDecode(freshResponse.body));
        task = freshTask; // replace with up-to-date task
      } else {
        print("⚠️ Failed to refresh task ${task.id}, using stale data");
      }
    } catch (e) {
      print("⚠️ Error refreshing task ${task.id}: $e");
    }
    // Controllers
    final titleController = TextEditingController(text: task.name);
    final descriptionController = TextEditingController(text: task.description);
    TimeOfDay? selectedTime = task.timeOfDay;
    int? selectedPatientId = task.userId;

    int? recDayOfMonth;

    // ----- Prefill recurrence -----
    // Is it recurring?
    bool isRecurringLocal =
        (task.frequency != null && task.frequency!.isNotEmpty) ||
        ((task.daysOfWeek?.any((e) => e)) ?? false) ||
        (task.taskType != null && task.taskType!.isNotEmpty);

    // Determine recurrence type to show
    String? recurrenceTypeLocal;
    if (task.daysOfWeek != null && task.daysOfWeek!.any((e) => e)) {
      recurrenceTypeLocal = 'Weekly';
    } else if (task.frequency != null && task.frequency!.isNotEmpty) {
      switch (task.frequency!.toLowerCase()) {
        case 'daily':
          recurrenceTypeLocal = 'Daily';
          break;
        case 'weekly':
          recurrenceTypeLocal = 'Weekly';
          break;
        case 'monthly':
          recurrenceTypeLocal = 'Monthly';
          break;
        case 'yearly':
          recurrenceTypeLocal = 'Yearly';
          break;
        default:
          recurrenceTypeLocal = null;
      }
    } else if (task.taskType != null) {
      final tt = task.taskType!.toLowerCase();
      if (tt == 'dayofweek') recurrenceTypeLocal = 'Weekly';
      if (tt == 'frequency')
        recurrenceTypeLocal = recurrenceTypeLocal ?? 'Daily';
    }

    // If monthly, pre-fill the day of month from the task.date
    if (recurrenceTypeLocal == 'Monthly') {
      recDayOfMonth = task.date.day;
    }

    List<bool>? daysOfWeekLocal = task.daysOfWeek;
    int? intervalLocal = task.interval;
    int? countLocal = task.count;
    DateTime? startDateLocal = task.date;
    DateTime?
    endDateLocal; // not persisted in v2 – only used for UI math if you want
    // ----- Caregiver: fetch patients for dropdown -----
    List<Map<String, dynamic>> patients = [];
    if (user.isCaregiver) {
      final response = await ApiService.getCaregiverPatients(user.id);
      if (response.statusCode == 200) {
        patients = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    }

    if (!mounted) return;

    if (task.count != null && task.frequency != null && task.count! > 0) {
      switch (task.frequency!.toLowerCase()) {
        case "daily":
          endDateLocal = task.date.add(
            Duration(days: (task.count! - 1) * (task.interval ?? 1)),
          );
          break;
        case "weekly":
          endDateLocal = task.date.add(Duration(days: (task.count! - 1) * 7));
          break;
        case "monthly":
          endDateLocal = DateTime(
            task.date.year,
            task.date.month + (task.count ?? 1) - 1,
            task.date.day,
          );
          break;
        case "yearly":
          endDateLocal = DateTime(
            task.date.year + (task.count ?? 1) - 1,
            task.date.month,
            task.date.day,
          );
          break;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) => AlertDialog(
            title: const Text("Edit Task"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Task Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                          if (picked != null) {
                            setInnerState(() => selectedTime = picked);
                          }
                        },
                        child: const Text("Pick Time"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Caregiver assignment dropdown
                  if (user.isPatient)
                    Text("Assigned to: ${user.name}")
                  else if (user.isCaregiver)
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Assign to Patient",
                        border: OutlineInputBorder(),
                      ),
                      value: selectedPatientId,
                      items: patients.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['patient']?['id'],
                          child: Text(
                            "${p['patient']?['firstName']} ${p['patient']?['lastName']}",
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setInnerState(() => selectedPatientId = val);
                      },
                    ),

                  const SizedBox(height: 16),

                  // Recurrence (reused component)
                  RecurrenceForm(
                    initialIsRecurring: isRecurringLocal,
                    initialRecurrenceType: recurrenceTypeLocal,
                    initialDaysOfWeek: daysOfWeekLocal,
                    initialInterval: intervalLocal,
                    initialCount: countLocal,
                    initialStartDate: startDateLocal,
                    initialEndDate: endDateLocal,
                    initialDayOfMonth: recDayOfMonth,
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
                          setInnerState(() {
                            // If recurrence type is set, force isRecurring = true
                            if (recurrenceType != null &&
                                recurrenceType.isNotEmpty) {
                              isRecurringLocal = true;
                            } else {
                              isRecurringLocal = isRecurring ?? false;
                            }
                            recurrenceTypeLocal = recurrenceType;
                            daysOfWeekLocal = daysOfWeek;
                            intervalLocal = interval;
                            countLocal = count;
                            startDateLocal = startDate;
                            endDateLocal = endDate;
                            recDayOfMonth = dayOfMonth;
                          });
                        },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed:
                    (isRecurringLocal &&
                        (recurrenceTypeLocal == null ||
                            recurrenceTypeLocal!.isEmpty))
                    ? null // disable if invalid
                    : () {
                        if (user.isCaregiver && selectedPatientId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a patient"),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    // Final patientId logic
    final patientId = user.isPatient ? user.id : selectedPatientId!;

    // Normalize recurrence for payload
    String? frequencyToSend;
    String? taskTypeToSend;
    List<bool>? daysToSend = daysOfWeekLocal;
    int? intervalToSend = intervalLocal;
    int? countToSend = countLocal;

    if (isRecurringLocal && (recurrenceTypeLocal != null)) {
      switch (recurrenceTypeLocal) {
        case 'Daily':
          frequencyToSend = 'daily';
          intervalToSend = intervalToSend ?? 1; // default
          taskTypeToSend = 'frequency';
          break;
        case 'Weekly':
          frequencyToSend = 'weekly';
          intervalToSend = intervalToSend ?? 7; // your chosen convention
          taskTypeToSend = (daysToSend != null && daysToSend.any((e) => e))
              ? 'dayOfWeek'
              : 'frequency';
          break;
        case 'Monthly':
          frequencyToSend = 'monthly';
          intervalToSend = intervalToSend ?? 1;
          taskTypeToSend = 'frequency';
          break;
        case 'Yearly':
          frequencyToSend = 'yearly';
          intervalToSend = intervalToSend ?? 365;
          taskTypeToSend = 'frequency';
          break;
      }
    } else {
      frequencyToSend = null;
      intervalToSend = null;
      countToSend = null;
      daysToSend = null;
      taskTypeToSend = 'task';
    }

    // Override date if monthly recurrence has a chosen day
    DateTime effectiveDate = startDateLocal ?? task.date;

    if (recurrenceTypeLocal?.toLowerCase() == 'monthly' &&
        recDayOfMonth != null) {
      final daysInMonth = DateUtils.getDaysInMonth(
        effectiveDate.year,
        effectiveDate.month,
      );
      final dom = recDayOfMonth!.clamp(1, daysInMonth);
      effectiveDate = DateTime(effectiveDate.year, effectiveDate.month, dom);
    }

    // Recompute count if start+end chosen
    if (startDateLocal != null &&
        endDateLocal != null &&
        recurrenceTypeLocal != null) {
      switch (recurrenceTypeLocal!.toLowerCase()) {
        case 'daily':
          countToSend =
              ((endDateLocal!.difference(startDateLocal!).inDays) ~/
                  (intervalToSend ?? 1)) +
              1;
          break;
        case 'weekly':
          countToSend =
              ((endDateLocal!.difference(startDateLocal!).inDays) ~/ 7) + 1;
          break;
        case 'monthly':
          countToSend =
              ((endDateLocal!.year - startDateLocal!.year) * 12 +
                  (endDateLocal!.month - startDateLocal!.month)) +
              1;
          break;
        case 'yearly':
          countToSend = (endDateLocal!.year - startDateLocal!.year) + 1;
          break;
      }
    }
    print(
      "🧭 Final effectiveDate = $effectiveDate "
      "(start=$startDateLocal, end=$endDateLocal, dom=$recDayOfMonth)",
    );
    // Build updated Task (Task.toJson already includes patientId)
    final updatedTask = Task(
      id: task.id,
      name: titleController.text,
      description: descriptionController.text,
      date: effectiveDate, // keep same date unless you add a date picker
      timeOfDay: selectedTime,
      userId: patientId,
      isComplete: task.isComplete,
      notifications: task.notifications,
      frequency: frequencyToSend,
      interval: intervalToSend,
      count: countToSend,
      daysOfWeek: daysToSend,
      taskType: taskTypeToSend,
    );

    try {
      print("🚀 Sending edit payload: ${jsonEncode(updatedTask.toJson())}");
      final response = await ApiService.editTaskV2(
        task.id,
        updatedTask.toJson(),
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
          SnackBar(content: Text("Failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  //CRUD Fucntion for removing tasks through this display
  //Tasks can be removed to the system through other features and will appear in the Calendar
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
      //Removal message sent if good response then make sure the class updates from DB
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _loadTasksFromDb();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Task '${task.name}' removed")));
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
// RecurrenceForm Widget
// =============================
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
    daysOfWeek = widget.initialDaysOfWeek;
    interval = widget.initialInterval;
    count = widget.initialCount;
    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;
    dayOfMonth = widget.initialDayOfMonth;
  }

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

          // Recurrence Type Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Recurrence Type"),
            value: recurrenceType,
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
          // Inline warning message
          if (isRecurring &&
              (recurrenceType == null || recurrenceType!.isEmpty))
            const Padding(
              padding: EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(
                "⚠ Please select a recurrence type",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),

          // Weekly → day-of-week picker
          if (recurrenceType == "Weekly") ...[
            const Text("Select Days of Week"),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                return FilterChip(
                  label: Text(days[index]),
                  selected: (daysOfWeek ?? List.filled(7, false))[index],
                  onSelected: (selected) {
                    setState(() {
                      daysOfWeek ??= List.filled(7, false);
                      daysOfWeek![index] = selected;
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
                  },
                );
              }),
            ),
          ],

          // Monthly → day-of-month picker
          if (recurrenceType == "Monthly") ...[
            const SizedBox(height: 16),
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
          // Start Date Picker
          Row(
            children: [
              Text(
                startDate != null
                    ? (recurrenceType == "Yearly"
                          // If yearly, clarify this is the day/month
                          ? "Occurs: ${startDate!.month}/${startDate!.day}"
                          : "Starts: ${startDate!.toLocal().toString().split(' ')[0]}")
                    : (recurrenceType == "Yearly"
                          ? "No yearly day/month set"
                          : "No start date set"),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2000), // allow past
                    lastDate: DateTime(DateTime.now().year + 5),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                    widget.onChanged(
                      isRecurring: isRecurring,
                      recurrenceType: recurrenceType,
                      daysOfWeek: daysOfWeek,
                      interval: interval,
                      count: count,
                      endDate: endDate,
                      dayOfMonth: dayOfMonth,
                      startDate: startDate,
                    );
                  }
                },
                child: Text(
                  recurrenceType == "Yearly"
                      ? "Pick Day/Month"
                      : "Pick Start Date",
                ),
              ),
            ],
          ),

          // End Date OR End Year Picker
          const SizedBox(height: 16),
          if (recurrenceType == "Yearly") ...[
            Row(
              children: [
                Text(
                  endDate != null
                      ? "Ends in Year: ${endDate!.year}"
                      : "No end year set",
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  hint: const Text("Select End Year"),
                  value: endDate?.year,
                  items:
                      List.generate(
                        10, // next 10 years
                        (i) => DateTime.now().year + i,
                      ).map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      // Store as Jan 1 of that year (you only care about year)
                      setState(() => endDate = DateTime(val, 1, 1));
                      widget.onChanged(
                        isRecurring: isRecurring,
                        recurrenceType: recurrenceType,
                        daysOfWeek: daysOfWeek,
                        interval: interval,
                        count: count,
                        endDate: endDate,
                        startDate: startDate,
                        dayOfMonth: dayOfMonth,
                      );
                    }
                  },
                ),
              ],
            ),
          ] else ...[
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
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 5),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                      widget.onChanged(
                        isRecurring: isRecurring,
                        recurrenceType: recurrenceType,
                        daysOfWeek: daysOfWeek,
                        interval: interval,
                        count: count,
                        endDate: endDate,
                        startDate: startDate,
                        dayOfMonth: dayOfMonth,
                      );
                    }
                  },
                  child: const Text("Pick End Date"),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
