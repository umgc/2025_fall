import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:learninglens_app/services/reflection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Api
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';

// beans
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';

enum ReflectionStatus { notStarted, inProgress, submitted }

class StudentReflectionsPage extends StatefulWidget {
  @override
  State<StudentReflectionsPage> createState() => _StudentReflectionsPageState();
}

class _StudentReflectionsPageState extends State<StudentReflectionsPage> {
  List<Assignment> _essays = [];
  int _selectedSidebarIndex = -1;
  bool _isReloadingEssays = false;

  // Keep track of each essay’s reflection status
  final Map<String, ReflectionStatus> _essayStatus = {};

  // Track reflection answers for each essay
  final Map<String, Map<Reflection, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadEssays();
  }

  Future<void> _loadEssays({int? courseId}) async {
    setState(() => _isReloadingEssays = true);

    try {
      final allEssays = await getAllEssays(courseId);

      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId');
      final int? uidInt = uid != null ? int.tryParse(uid) : null;

      final filteredEssays = allEssays.where((a) => !_isOverdue(a)).toList()
        ..sort((a, b) {
          final ad = _effectiveDue(a);
          final bd = _effectiveDue(b);
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });

      for (var e in filteredEssays) {
        ReflectionStatus stat = ReflectionStatus.notStarted;
        final refs = await ReflectionService()
            .getReflectionsForAssignment(e.courseId, e.id);
        _controllers[e.id.toString()] = {};
        for (var r in refs) {
          ReflectionResponse? response;
          if (uidInt != null) {
            response = await ReflectionService()
                .getReflectionForSubmission(r.uuid!, uidInt);
            if (response != null) {
              stat = ReflectionStatus.submitted;
            }
          }
          setState(() {
            _controllers[e.id.toString()]![r] =
                TextEditingController(text: response?.response ?? "");
          });
        }
        setState(() {
          _essayStatus[e.id.toString()] = stat;
        });
      }

      setState(() {
        _essays = filteredEssays;
      });

      setState(() => _isReloadingEssays = false);
    } catch (e) {
      print("Error loading essays: $e");
    }
  }

  bool _isOverdue(Assignment a) =>
      a.dueDate != null && a.dueDate!.isBefore(DateTime.now());
  DateTime? _effectiveDue(Assignment a) => a.dueDate;

  String _formatDate(DateTime? date) {
    if (date == null) return 'No due date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _startReflection(Assignment essay) async {
    final id = essay.id.toString();
    setState(() {
      _essayStatus[id] = ReflectionStatus.inProgress;
    });
  }

  void _submitReflection(Assignment essay) async {
    final id = essay.id.toString();
    final controllers = _controllers[id];
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId');
    final int? uidInt = uid != null ? int.tryParse(uid) : null;
    if (controllers == null || uidInt == null) return;

    for (var c in controllers.entries) {
      await ReflectionService().completeReflection(ReflectionResponse(
          studentId: uidInt,
          response: c.value.text.trim(),
          reflectionId: c.key.uuid!));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reflection submitted.')),
    );

    setState(() {
      _essayStatus[id] = ReflectionStatus.submitted;
    });
  }

  Widget _statusChip(Assignment a) {
    final status = _essayStatus[a.id.toString()] ?? ReflectionStatus.notStarted;
    switch (status) {
      case ReflectionStatus.notStarted:
        return const Chip(label: Text('Not Started'));
      case ReflectionStatus.inProgress:
        return Chip(
            label: const Text('In Progress'),
            backgroundColor: Colors.amber.withOpacity(.2));
      case ReflectionStatus.submitted:
        return Chip(
            label: const Text('Submitted'),
            backgroundColor: Colors.green.withOpacity(.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEssay =
        _selectedSidebarIndex >= 0 ? _essays[_selectedSidebarIndex] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Reflections')),
      body: Row(
        children: [
          // Left Sidebar: Essay List
          SizedBox(
            width: 280,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Essay Assignments',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _isReloadingEssays
                      ? CircularProgressIndicator()
                      : Expanded(
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            itemCount: _essays.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final assignment = _essays[i];
                              final selected = _selectedSidebarIndex == i;
                              final dueText = _formatDate(assignment.dueDate);

                              return ListTile(
                                dense: true,
                                selected: selected,
                                selectedTileColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.08),
                                title: Text(assignment.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text('Due: $dueText'),
                                trailing: _statusChip(assignment),
                                onTap: () =>
                                    setState(() => _selectedSidebarIndex = i),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1),

          // Right Pane: Essay Details + Reflection
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: selectedEssay == null
                  ? const Center(
                      child: Text(
                        "Select an assignment to begin reflection.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assignment: ${selectedEssay.name}',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          Text('Course: ${selectedEssay.courseId}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 10),
                          Text('Due: ${_formatDate(selectedEssay.dueDate)}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 10),
                          const Text('Description:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Html(
                            data: selectedEssay.description,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                              ),
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildReflectionSection(selectedEssay),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionSection(Assignment essay) {
    final id = essay.id.toString();
    final status = _essayStatus[id] ?? ReflectionStatus.notStarted;

    if (status == ReflectionStatus.notStarted) {
      return ElevatedButton(
        onPressed: () => _startReflection(essay),
        child: const Text('Start Reflection'),
      );
    } else if (status == ReflectionStatus.inProgress) {
      final controllers = _controllers[id]!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reflection Questions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...controllers.keys.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.question,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controllers[q],
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter your response...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () => _submitReflection(essay),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text(
                'Submit Reflection',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Reflection submitted!',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      );
    }
  }
}

// Helper to fetch all essays from LMS
Future<List<Assignment>> getAllEssays(int? courseID) async {
  List<Assignment> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (courseID == 0 || courseID == null || c.id == courseID) {
      result.addAll(c.essays ?? []);
    }
  }
  return result;
}
