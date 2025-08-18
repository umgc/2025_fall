// lib/widgets/navigation_panel.dart
import 'package:flutter/material.dart';
import 'nav_section.dart';

// Ensure these are imported from your constants file or defined here
// Remove these definitions if already present in constants.dart:
final courses = <String>['Course 1', 'Course 2'];
final Map<String, List<String>> courseAssignments = {
  'Course 1': ['Assignment 1', 'Assignment 2'],
  'Course 2': ['Assignment 3', 'Assignment 4'],
};
final Map<String, List<String>> assignmentSubmissions = {
  'Assignment 1': ['Submission 1', 'Submission 2'],
  'Assignment 2': ['Submission 3'],
  'Assignment 3': ['Submission 4'],
  'Assignment 4': ['Submission 5'],
};

// Ensure these are imported from your constants file or defined here
// Example definitions (remove if already defined in constants.dart):
// final List<String> courses = ['Course 1', 'Course 2'];
// final Map<String, List<String>> courseAssignments = {'Course 1': ['Assignment 1'], 'Course 2': ['Assignment 2']};
// final Map<String, List<String>> assignmentSubmissions = {'Assignment 1': ['Submission 1'], 'Assignment 2': ['Submission 2']};

class NavigationPanel extends StatefulWidget {
  final Function(String, String, String) onSelectionChanged;

  const NavigationPanel({super.key, required this.onSelectionChanged});

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  String selectedCourse = '';
  String selectedAssignment = '';
  String selectedSubmission = '';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white.withOpacity(0.9),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search courses, assignments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  NavSection(
                    title: '📚 Courses',
                    items: courses
                        .where((course) => course
                            .toLowerCase()
                            .contains(searchQuery))
                        .toList(),
                    onItemSelected: (item) {
                      setState(() {
                        selectedCourse = item;
                        selectedAssignment = '';
                        selectedSubmission = '';
                      });
                      widget.onSelectionChanged(
                          selectedCourse, selectedAssignment, selectedSubmission);
                    },
                  ),
                  NavSection(
                    title: '📝 Assignments',
                    items: selectedCourse.isNotEmpty
                        ? courseAssignments[selectedCourse]!
                            .where((assignment) => assignment
                                .toLowerCase()
                                .contains(searchQuery))
                            .toList()
                        : ['Select a course first'],
                    disabled: selectedCourse.isEmpty,
                    onItemSelected: (item) {
                      if (selectedCourse.isNotEmpty) {
                        setState(() {
                          selectedAssignment = item;
                          selectedSubmission = '';
                        });
                        widget.onSelectionChanged(
                            selectedCourse, selectedAssignment, selectedSubmission);
                      }
                    },
                  ),
                  NavSection(
                    title: '📄 Submissions',
                    items: selectedAssignment.isNotEmpty &&
                            assignmentSubmissions.containsKey(selectedAssignment)
                        ? assignmentSubmissions[selectedAssignment]!
                            .where((submission) => submission
                                .toLowerCase()
                                .contains(searchQuery))
                            .toList()
                        : ['Select an assignment first'],
                    disabled: selectedAssignment.isEmpty,
                    onItemSelected: (item) {
                      if (selectedAssignment.isNotEmpty) {
                        setState(() {
                          selectedSubmission = item;
                        });
                        widget.onSelectionChanged(
                            selectedCourse, selectedAssignment, selectedSubmission);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}