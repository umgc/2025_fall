import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
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
  List<AiLog> logs = [];
  AiLogSource logSource = AiLogSource();
  int sortIndex = 0;
  bool sortAsc = true;
  String message = 'Select filters and press Filter to view AI logs.';
  bool isError = false;

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
    final String longText =
    """
    This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. This is long database text for testing. 
    """;
    if (selectedAssignment != null && selectedStudent != null) {
      print(await AILoggingSingleton().addLog(AiLog(selectedCourse!, selectedAssignment!, selectedStudent!, longText, longText, LlmType.CHATGPT)));
    }
    List<AiLog> newLogs = [];
    setState(() {
        logs = [];
        message = 'Loading logs...';
        isError = false;
        sortIndex = 0;
        sortAsc = true;
        logSource.setData(logs, sortIndex, sortAsc);
    });
    try {
      newLogs = await AILoggingSingleton().getLogs(selectedCourse!.id, selectedAssignment?.id, selectedStudent?.id, LocalStorageService.getSelectedClassroom().index);
       setState(() {
        if (newLogs.isEmpty) {
          message = 'No logs found for the selected filters.';
        }
        logs = newLogs;
        logSource.setData(logs, sortIndex, sortAsc);
    });
    } catch(e) {
      setState(() {
        isError = true;
        message = 'Error retrieving logs: $e';
      });
    }
  }
}

void sort(int col, bool ascending) {
  setState(() {
    sortIndex = col;
    sortAsc = ascending;
    logSource.setData(logs, sortIndex, sortAsc);
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'View AI Log',
          onRefresh: _loadCourses, // Refresh courses when the app bar is refreshed
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: Column(
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
                              onPressed: (selectedCourse == null && selectedAssignment == null && selectedStudent == null) ? null : _queryDatabase,
                              child: const Text('Filter'),
                            )
                          ]
                        )
                      )
                  ],
                  ),
                SizedBox(height: 20),
               Visibility(visible: logSource.sortedData.isNotEmpty, child:
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                child: Row(children: [Expanded(child: PaginatedDataTable(
                  sortColumnIndex: sortIndex,
                  sortAscending: sortAsc,
                  dataRowMaxHeight: double.infinity,
                  columns: [
                    DataColumn(columnWidth: FixedColumnWidth(150), label: Text('Student'), onSort: sort),
                    DataColumn(columnWidth: FixedColumnWidth(150), label: Text('Assignment'), onSort: sort),
                    DataColumn(columnWidth: FixedColumnWidth(150), label: Text('Course'), onSort: sort),
                    DataColumn(columnWidth: FixedColumnWidth(225), label: Text('Prompt'), onSort: sort),
                    DataColumn(columnWidth: FixedColumnWidth(225),label: Text('Response'), onSort: sort),
                    DataColumn(columnWidth: FixedColumnWidth(225), label: Text('Reflection'), onSort: sort),
                    DataColumn(columnWidth: FixedColumnWidth(150), label: Text('LLM'), onSort: sort),
                    DataColumn(label: Text('Timestamp'), onSort: sort),
                  ],
                  source: logSource,
                ))],),
                )
                  ,
                )),
                Visibility(visible: logSource.sortedData.isEmpty, child: Expanded(child: Align(child: Text(textAlign: TextAlign.center, style: isError ? TextStyle(color: Colors.red) : null, message))))],
            )
        );
  }
}

class AiLogSource extends DataTableSource {
  @override
  int get rowCount => sortedData.length;
  late List<AiLog> sortedData = [];
  void setData(List<AiLog> data, int sortCol, bool sortAscending) {
    sortedData = data.toList()..sort((AiLog a, AiLog b) {
      final Comparable cellA = a.getValueForColumn(sortCol);
      final Comparable cellB = b.getValueForColumn(sortCol);
      return (sortAscending ? 1 : -1) * cellA.compareTo(cellB);
    });
    notifyListeners();
  }

  DataCell cellFor(int row, int column) {
    return DataCell(Text(sortedData[row].getValueForColumn(column).toString(), softWrap: true, textAlign: TextAlign.start,));
  }

  @override
  DataRow? getRow(int index) {
    return DataRow(key: ObjectKey(sortedData[index].uuid), cells: <DataCell>[
      cellFor(index, 0),
cellFor(index, 1),
cellFor(index, 2),
cellFor(index, 3),
cellFor(index, 4),
cellFor(index, 5),
cellFor(index, 6),
cellFor(index, 7),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}