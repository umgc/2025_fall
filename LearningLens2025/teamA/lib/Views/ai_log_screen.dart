import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

import 'package:learninglens_app/stub/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
  List<AiLog> aiLogs = [];

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
    List<AiLog> fetchedLogs = await AILoggingSingleton().getLogs(selectedCourse!.id, selectedAssignment?.id, selectedStudent?.id, LocalStorageService.getSelectedClassroom().index);
    setState(() {
      aiLogs = fetchedLogs;
    });
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

  void _exportLogs() async {
    String defaultName = '${selectedCourse?.fullName.replaceAll(" ", "")}_${selectedAssignment == null ? "AllAssignments" : selectedAssignment?.name.replaceAll(" ", "")}_${selectedStudent == null ? "AllStudents" : selectedStudent?.fullname}.xlsx';
    if (kIsWeb) {
      // Build bytes.
      List<int> bytes = await _exportReportAsExcel();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = defaultName;
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Report exported to Excel via browser download.')),
      );
    } else if (Platform.isAndroid || Platform.isIOS) { 
      try {
        List<int> bytes = await _exportReportAsExcel();
        var dir = await getApplicationDocumentsDirectory();
        File(path.join('${dir.path}/$defaultName'))..createSync(recursive: true)..writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to Excel at:\n$dir')),
        );
        } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e')),
        );
      }
    }
    else {
      final savePath = await _pickFileLocation(defaultName);
      if (savePath == null) return;
      try {
        List<int> bytes = await _exportReportAsExcel();
        final file = File(savePath);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to Excel at:\n$savePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e')),
        );
      }
    }
  }

  Future<String?> _pickFileLocation(String defaultName) async {
    if (kIsWeb) return null;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: defaultName,
    );
    return result;
  }

  Future<List<int>> _exportReportAsExcel() async {
var excel = Excel.createExcel();
    // Dynamic export for student breakdown.
    Sheet studentSheet = excel['AI Logs'];
    if (aiLogs.isNotEmpty) {
      // Get headers dynamically from the first map.
      var studentHeaders = [
        AiLog.getHeaderForColumn(0),
        AiLog.getHeaderForColumn(1),
        AiLog.getHeaderForColumn(2),
        AiLog.getHeaderForColumn(3),
        AiLog.getHeaderForColumn(4),
        AiLog.getHeaderForColumn(5),
        AiLog.getHeaderForColumn(6),
        AiLog.getHeaderForColumn(7),
      ];
      studentSheet.appendRow(studentHeaders);
      // Append each student row by mapping the values to strings.
      for (var log in aiLogs) {
        studentSheet.appendRow(
            [
              log.getValueForColumn(0),
              log.getValueForColumn(1),
              log.getValueForColumn(2),
              log.getValueForColumn(3),
              log.getValueForColumn(4),
              log.getValueForColumn(5),
              log.getValueForColumn(6),
              log.getValueForColumn(7).toString(),
            ],
        );
      }
    }
    return excel.encode()!;
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
                            ),
                            Spacer(),
                            ElevatedButton(
                              onPressed: aiLogs.isEmpty ? null : _exportLogs,
                              child: const Text('Export Logs'),
                            ),
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