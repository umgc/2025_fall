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
  //This will be more required once the endpoint provides needed information.
  Map<int, String> patientNames = {};

  // Define task types and their colors, also requires endpoint for more use.
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

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) {
        setState(() {
          error = "User not logged in.";
          isLoading = false;
        });
        return;
      }
      List<Task> allTasks = [];
      //Branching point if patient then you see your own event,
      //if caregiver then you see your patients events
      // --- PATIENT FLOW ---
      if (user.isPatient) {
        final response = await ApiService.getPatientTasks(
          user.id,
        ).timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          for (var raw in data) {
            final map = Map<String, dynamic>.from(raw);

            if (map['date'] != null && map['date'] is String) {
              String d = map['date'];
              if (!d.contains("T")) {
                map['date'] = d.replaceFirst(" ", "T");
              }
            }

            if (map['daysOfWeek'] == null || map['daysOfWeek'] == "null") {
              map['daysOfWeek'] = [];
            }

            try {
              final task = Task.fromJson(map);
              allTasks.add(task);
            } catch (e) {
              log("Error: $e");
            }
          }
        }
      }
      // --- CAREGIVER FLOW ---
      else if (user.isCaregiver) {
        final patientsResponse = await ApiService.getCaregiverPatients(user.id);
        if (patientsResponse.statusCode == 200) {
          final List patients = json.decode(patientsResponse.body);
          //Need name information for assignements. This is to be refactored when endpoint is updated.
          for (var patient in patients) {
            final patientId = patient['patient']?['id'];
            final firstName = patient['patient']?['firstName'] ?? '';
            final lastName = patient['patient']?['lastName'] ?? '';

            if (patientId != null) {
              // Save the patient name for later lookup
              patientNames[patientId] = "$firstName $lastName";
            }

            //Skipping patient with null id
            if (patientId == null) {
              continue;
            }

            final taskResponse = await ApiService.getPatientTasks(
              patientId,
            ).timeout(const Duration(seconds: 30));
            if (taskResponse.statusCode == 200) {
              final List data = json.decode(taskResponse.body);
              for (var raw in data) {
                final map = Map<String, dynamic>.from(raw);

                if (map['date'] != null && map['date'] is String) {
                  String d = map['date'];
                  if (!d.contains("T")) {
                    map['date'] = d.replaceFirst(" ", "T");
                  }
                }
                if (map['daysOfWeek'] == null || map['daysOfWeek'] == "null") {
                  map['daysOfWeek'] = [];
                }

                try {
                  final task = Task.fromJson(map);
                  allTasks.add(task);
                } catch (e) {
                  log("Error: $e");
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

      for (var task in allTasks) {
        final dateKey = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
        );
        grouped.putIfAbsent(dateKey, () => []);
        grouped[dateKey]!.add(task);
      }
      setState(() {
        tasks = grouped;
        isLoading = false;
      });
    } catch (e) {
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
                eventLoader: (day) => tasks[day] ?? [],
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
                  /* final assignedName = task.userId != null
                      ? patientNames[task.userId] ?? "Unknown Patient"
                      : "Unassigned";*/

                  return ListTile(
                    leading: const Icon(Icons.task),
                    title: Text(
                      //"$assignedName: ${task.name}", Will encoperate once endpoint is updated
                      task.name,
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

              // Legend: needs refactoring based on update to taskType
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

  /// Map task type to color, need clear taskType before logic returns anything but general color.
  Color _getTaskColor(String type) {
    final key = type.toLowerCase();
    return taskTypeColors[key] ?? Colors.deepOrange;
  }

  /// Helper to render a day cell with border + task dots
  Widget _buildDayCell(DateTime day, List<Task> dayTasks, Color borderColor) {
    const maxVisibleDots = 5;
    List<Widget> taskDots = [];

    final displayTasks = dayTasks.take(maxVisibleDots).toList();
    for (var _ in displayTasks) {
      taskDots.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            //TODO Need to figure out better system for checking colors if needed.
            color: _getTaskColor("general"),
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
    //Pop Up form for basic information to make a task
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            //Padding and sizing set for control of viewable pop up space and to ensre
            //form fields are not spawened  to top of each other.
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Task Title"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        selectedTime != null
                            ? "Time: ${selectedTime!.format(context)}"
                            : "Time: Not set",
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: const Text("Pick Time"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final patientId = user.id;

    final newTaskJson = {
      'id': -1,
      'name': titleController.text,
      'description': descriptionController.text,
      'date': (_selectedDay ?? DateTime.now()).toIso8601String(),
      'timeOfDay': selectedTime != null
          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
          : null,
      //For now this is ignored until the endpoint is updated
      'userId': patientId,
    };

    try {
      final response = await ApiService.createTask(
        patientId,
        jsonEncode(newTaskJson),
      );
      //Add message sent if good response then make sure the class updates from DB
      if (response.statusCode == 200 || response.statusCode == 201) {
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

  //CRUD Fucntion for editing tasks through this display
  //Tasks can be edited to the system through other features and will appear in the Calendar
  Future<void> _editTask(Task task) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    final titleController = TextEditingController(text: task.name);
    final descriptionController = TextEditingController(text: task.description);
    TimeOfDay? selectedTime = task.timeOfDay;

    int? selectedPatientId = task.userId;

    // If caregiver, fetch their patients for dropdown
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
            title: const Text("Edit Task"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Task Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  // Description field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextField(
                      controller: descriptionController,
                      maxLines:
                          3, //Allows multiline so text doesn’t get cramped
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
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
                            setState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: const Text("Pick Time"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Caregiver can reassign task
                  if (user.isPatient)
                    Text("Assigned to: ${user.name}")
                  else if (user.isCaregiver)
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Assign to Patient",
                        border: OutlineInputBorder(),
                      ),
                      //This portion of the create menu is blocked by limitations of the endpoint for now.
                      initialValue: selectedPatientId,
                      items: patients.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['patient']?['id'],
                          child: Text(
                            "${p['patient']?['firstName']} ${p['patient']?['lastName']}",
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedPatientId = val;
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
                onPressed: () {
                  if (user.isCaregiver && selectedPatientId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a patient")),
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
    // deciding logic for patient id based on user
    final patientId = user.isPatient ? user.id : selectedPatientId!;

    // Build updated task object
    final updatedTask = Task(
      id: task.id,
      name: titleController.text,
      description: descriptionController.text,
      date: task.date,
      timeOfDay: selectedTime,
      userId: patientId,
      isComplete: task.isComplete,
      notifications: task.notifications,
      frequency: task.frequency,
      interval: task.interval,
      count: task.count,
      daysOfWeek: task.daysOfWeek,
    );

    try {
      final response = await ApiService.editTask(task.id, updatedTask.toJson());

      //Edit message sent if good response then make sure the class updates from DB
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
            content: Text("Failed to edit task: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error editing task: $e")));
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
      final response = await ApiService.deleteTask(task.id);
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
