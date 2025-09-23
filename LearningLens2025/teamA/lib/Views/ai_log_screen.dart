import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/database/ai_logging_singleton.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/ai_log.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class AiLogScreen extends StatefulWidget {
  @override
  State createState() => _AiLogScreenState();
}

class _AiLogScreenState extends State<AiLogScreen> {
  List<Course> courses = [];
  Course? selectedCourse;
  List<Assignment> assignments = [];
  Assignment? selectedAssignment;
  List<Participant> participants = [];
  Participant? selectedStudent;

  @override
  void initState() {
    super.initState();
    _loadCourses(); // Load courses when the widget initializes
  }

  Future<void> _loadCourses() async {
    selectedCourse = null;
    try {
      var userCourses = LmsFactory.getLmsService().courses;
      setState(() {
        if (userCourses != null) {
          courses = userCourses; // Update the state with fetched courses
        }
        else {
          courses = [];
        }
      });
    } catch (e) {
      print("Error loading courses: $e");
    }
  }

  void _fetchAssignments() async {
    selectedAssignment = null;
    List<Assignment> assignments = [];
    if (selectedCourse != null) {
      if (selectedCourse!.essays != null) {
        assignments = selectedCourse!.essays!;
      }
    }
    setState(() {
      this.assignments = assignments;
    });
  }

  void _fetchParticipants() async {
    selectedStudent = null;
    List<Participant> participants = [];
    if (selectedCourse != null) {
     participants = await LmsFactory.getLmsService().getCourseParticipants(selectedCourse!.id.toString());
    }
    else {
      participants = [];
    }
    setState(() {
      this.participants = participants;
    });
  }

  String normalizeText(String text) {
  return text
      .replaceAll('â', "'") // Replace garbled curly apostrophe with a plain apostrophe
      .replaceAll('’', "'")   // Replace Unicode curly apostrophe with a plain apostrophe
      .replaceAll('“', '"')   // Replace Unicode left double quotation mark
      .replaceAll('”', '"')   // Replace Unicode right double quotation mark
      .replaceAll('‘', "'")   // Replace Unicode left single quotation mark
      .replaceAll('’', "'");  // Replace Unicode right single quotation mark
}

void _queryDatabase() async {
  // For now just test adding data, get data
  if (selectedCourse != null) {
    if (selectedAssignment != null && selectedStudent != null) {
      print(await AILoggingSingleton().addLog(AiLog(selectedCourse!, selectedAssignment!, selectedStudent!, "prompt", "response", LlmType.CHATGPT)));
    }
    print(await AILoggingSingleton().getLogs(selectedCourse!.id, selectedAssignment?.id, selectedStudent?.id, LocalStorageService.getSelectedClassroom().index));
  }
}


  String _convertTextToHtml(String text) {
    return "<p>${text.replaceAll('\n\n', '</p><p>').replaceAll('\n', '<br>')}</p>";
  }

  String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<p[^>]*>'), '\n\n')
        .replaceAll(RegExp(r'</p>'), '')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'View AI Log',
          onRefresh: _loadCourses, // Refresh courses when the app bar is refreshed
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isNarrowScreen = constraints.maxWidth <= 805; // Breakpoint for narrow screens
            bool isMediumScreen = constraints.maxWidth > 805 && constraints.maxWidth <= 1170; // Breakpoint for medium screens

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                // Add New Lesson Plan Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                            child: DropdownButtonFormField<Course>(
                              value: selectedCourse,
                              items: courses.map<DropdownMenuItem<Course>>((course) {
                                    return DropdownMenuItem<Course>(
                                      value: course,
                                      child: Text(course.fullName),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCourse = value;
                                  _fetchParticipants();
                                  _fetchAssignments();
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Select Course',
                                border: OutlineInputBorder(),
                              ),
                            )),
                            SizedBox(width: 10),
                                                        Expanded(
                            child: DropdownButtonFormField<Assignment>(
                              decoration: const InputDecoration(
                                labelText: 'Select Assignment',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedAssignment,
                              items: assignments.map<DropdownMenuItem<Assignment>>((assignment) {
                                    return DropdownMenuItem<Assignment>(
                                      value: assignment,
                                      child: Text(assignment.name),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedAssignment = newValue;
                                });
                              },
                            )),
                            SizedBox(width: 10),
                            Expanded(
                            child: DropdownButtonFormField<Participant>(
                              decoration: const InputDecoration(
                                labelText: 'Select Student',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedStudent,
                              items: participants.map<DropdownMenuItem<Participant>>((participant) {
                                    return DropdownMenuItem<Participant>(
                                      value: participant,
                                      child: Text(participant.fullname),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedStudent = newValue;
                                });
                              },
                            )),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _queryDatabase,
                              child: const Text('Filter'),
                            )
                          ]
                        )
                      )
                  ],
                  ),
                
              ],
            );
          },
        ),
      ),
    );
  }
}