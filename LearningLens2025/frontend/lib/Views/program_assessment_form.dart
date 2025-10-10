import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ProgramAssessmentForm extends StatefulWidget {
  final List<Course> courses;
  // Callback that is called when a new program evaluation is created successfully
  final Future<void> Function(
          Course course, Assignment assignment, String expectedOutput)?
      onEvaluationStarted;
  const ProgramAssessmentForm(
      {super.key, required this.courses, required this.onEvaluationStarted});

  @override
  _ProgramAssessmentFormState createState() =>
      _ProgramAssessmentFormState(courses, onEvaluationStarted);
}

class _ProgramAssessmentFormState extends State<ProgramAssessmentForm> {
  final lmsService = LmsFactory.getLmsService();
  final codeEvalUrl = LocalStorageService.getCodeEvalUrl();

  List<Course> courses = [];
  final TextEditingController outputController = TextEditingController();
  final Future<void> Function(
          Course course, Assignment assignment, String expectedOutput)?
      onEvaluationStarted;
  final List<String> languages = [ 'C', 'C++', 'Java', 'Python' ];

  Course? selectedCourse;
  Assignment? selectedAssignment;
  String? selectedLanguage;


  _ProgramAssessmentFormState(this.courses, this.onEvaluationStarted);

  // Helper to check if form is valid
  bool get isFormValid =>
      selectedCourse != null &&
      selectedAssignment != null &&
      outputController.text.trim().isNotEmpty;

  @override
  void initState() {
    // Listen to changes in the text field to update button state
    outputController.addListener(() {
      setState(() {}); // triggers rebuild to refresh button enabled/disabled
    });
    selectedLanguage = languages[0];
    super.initState();
  }

  @override
  void dispose() {
    outputController.dispose();
    super.dispose();
  }

  // Helper to show status messages
  void _showSnackBar(SnackBar snackBar) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _startEvaluation(
    Course course, Assignment assignment, String expectedOutput, String language) async {
    final response = await ApiService().httpPost(Uri.parse(codeEvalUrl),
        body: jsonEncode({
          'courseId': course.id,
          'assignmentId': assignment.id.toString(),
          'expectedOutput': expectedOutput,
          'username': lmsService.userName,
          'language': language
        }));

    if (response.statusCode != 200) {
      _showSnackBar(SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(
              'Unable to evaluate coding assignment: status code ${response.statusCode}')));

      debugPrint(response.body);
      return;
    }

    _showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text('Evaluation started successfully')));

    if (onEvaluationStarted != null) {
      await onEvaluationStarted!(course, assignment, expectedOutput);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row with 3 inputs
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Courses Dropdown
                Expanded(
                  child: DropdownButtonFormField<Course>(
                    decoration: InputDecoration(
                      labelText: "Courses",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCourse,
                    items: courses.map((course) {
                      return DropdownMenuItem(
                        value: course,
                        child: Text(course.fullName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourse = value;
                        selectedAssignment = null;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),

                // Assignments Dropdown
                Expanded(
                  child: DropdownButtonFormField<Assignment>(
                    decoration: InputDecoration(
                      labelText: "Assignments",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedAssignment,
                    items: selectedCourse == null
                        ? []
                        : courses
                            .firstWhere((c) => c == selectedCourse)
                            .essays!
                            .map((assignment) {
                            return DropdownMenuItem(
                              value: assignment,
                              child: Text(assignment.name),
                            );
                          }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAssignment = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),

                // Language selection dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Language",
                      border: OutlineInputBorder(),
                    ),
                    value: languages[0],
                    items: languages.map((lang) => 
                      DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      )
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value;
                      });
                    }
                  )
                ),
                SizedBox(width: 12),

                // Expected Output TextField
                Expanded(
                  child: TextFormField(
                    controller: outputController,
                    decoration: InputDecoration(
                      labelText: "Expected Output",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16), // bigger size
                textStyle: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold), // bigger text
                backgroundColor: Colors.deepPurpleAccent, // primary color
                foregroundColor: Colors.white, // text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // rounded corners
                ),
                elevation: 5, // shadow for prominence
              ),
              onPressed: !isFormValid
                  ? null
                  : () async {
                      await _startEvaluation(
                        selectedCourse!,
                        selectedAssignment!, 
                        outputController.text,
                        selectedLanguage!
                      );

                      debugPrint("Course: $selectedCourse");
                      debugPrint("Assignment: $selectedAssignment");
                      debugPrint("Expected Output: ${outputController.text}");
                    },
              child: Text("Create"),
            )
          ],
        ),
      ),
    );
  }
}
