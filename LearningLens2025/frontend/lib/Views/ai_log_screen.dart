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
  List<AiLog> logs = [];
  late _AiLogSource logSource;
  int sortIndex = 7;
  bool sortAsc = false;
  String message = 'Select filters and press Filter to view AI logs.';
  bool isError = false;
  bool isLoading = false;
  DateTime? startDate;
  DateTime? endDate;

  int? selected;

  @override
  void initState() {
    super.initState();
    logSource = _AiLogSource(this);
    _loadCourses(); // Load courses when the widget initializes
  }

  Future<void> _loadCourses() async {
    selectedCourse = null;
    try {
      var userCourses = await LmsFactory.getLmsService().getUserCourses();
      setState(() {
        courses = userCourses; // Update the state with fetched courses
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        message = 'Error loading courses: $e';
      });
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
      participants = await LmsFactory.getLmsService()
          .getCourseParticipants(selectedCourse!.id.toString());
    } else {
      participants = [];
    }
    setState(() {
      this.participants = participants;
    });
  }

  String normalizeText(String text) {
    return text
        .replaceAll('â',
            "'") // Replace garbled curly apostrophe with a plain apostrophe
        .replaceAll('’',
            "'") // Replace Unicode curly apostrophe with a plain apostrophe
        .replaceAll('“', '"') // Replace Unicode left double quotation mark
        .replaceAll('”', '"') // Replace Unicode right double quotation mark
        .replaceAll('‘', "'") // Replace Unicode left single quotation mark
        .replaceAll('’', "'"); // Replace Unicode right single quotation mark
  }

  void _queryDatabase() async {
    // For now just test adding data, get data
    if (selectedCourse != null) {
      final String testString = "This is a test string for a prompt.";
      final String replyString = "This is a test string for a reply.";
      final String reflectionString = "This is a test reflection.";
      if (selectedAssignment != null && selectedStudent != null) {
        await AILoggingSingleton().addLog(AiLog(
            selectedCourse!,
            selectedAssignment!,
            selectedStudent!,
            testString,
            replyString,
            LlmType.CHATGPT,
            reflectionString));
      }
      List<AiLog> newLogs = [];
      setState(() {
        logs = [];
        isLoading = true;
        message = 'Loading AI logs...';
        isError = false;
        sortIndex = 7;
        sortAsc = false;
        logSource.setData(logs, sortIndex, sortAsc);
      });
      try {
        newLogs = await AILoggingSingleton().getLogs(
            selectedCourse!,
            selectedAssignment,
            selectedStudent,
            LocalStorageService.getSelectedClassroom().index,
            startDate,
            endDate);
        setState(() {
          isLoading = false;
          if (newLogs.isEmpty) {
            message = 'No logs found for the selected filters.';
          }
          logs = newLogs;
          logSource.setData(logs, sortIndex, sortAsc);
        });
      } catch (e) {
        setState(() {
          isLoading = false;
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

  void selectionChanged(int? index) {
    setState(() {
      if (index == selected) {
        selected = null;
      } else {
        selected = index;
      }
      logSource.selectedChanged();
    });
  }

  void _exportLogs() async {
    String defaultName =
        '${selectedCourse?.fullName.replaceAll(" ", "")}_${selectedAssignment == null ? "AllAssignments" : selectedAssignment?.name.replaceAll(" ", "")}_${selectedStudent == null ? "AllStudents" : selectedStudent?.fullname}${startDate != null ? "_After_${getDateString(startDate!)}" : ""}${endDate != null ? "_Before_${getDateString(endDate!)}" : ""}.xlsx';
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
            content: Text('Report exported to Excel via browser download.')),
      );
    } else if (Platform.isAndroid || Platform.isIOS) {
      try {
        List<int> bytes = await _exportReportAsExcel();
        var dir = await getApplicationDocumentsDirectory();
        File(path.join('${dir.path}/$defaultName'))
          ..createSync(recursive: true)
          ..writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to Excel at:\n$dir')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e')),
        );
      }
    } else {
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
    if (logSource.sortedData.isNotEmpty) {
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
      for (var log in logSource.sortedData) {
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
            onRefresh:
                _loadCourses, // Refresh courses when the app bar is refreshed
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
                          child: DropdownButtonFormField<Course?>(
                        value: selectedCourse,
                        items: List.empty(growable: true)
                          ..add(DropdownMenuItem<Course?>(
                              value: null, child: Text('Select Course')))
                          ..addAll(
                              courses.map<DropdownMenuItem<Course?>>((course) {
                            return DropdownMenuItem<Course?>(
                              value: course,
                              child: Text(course.fullName),
                            );
                          })),
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
                          child: Opacity(
                              opacity: selectedCourse == null ? .5 : 1,
                              child: DropdownButtonFormField<Assignment?>(
                                decoration: InputDecoration(
                                    labelText: 'Select Assignment',
                                    border: OutlineInputBorder(),
                                    disabledBorder: null,
                                    enabled: selectedCourse != null),
                                value: selectedAssignment,
                                items: selectedCourse == null
                                    ? null
                                    : List.empty(growable: true)
                                  ?..add(DropdownMenuItem<Assignment?>(
                                      value: null,
                                      child: Text('Select Assignment')))
                                  ..addAll(assignments
                                      .map<DropdownMenuItem<Assignment?>>(
                                          (assignment) {
                                    return DropdownMenuItem<Assignment?>(
                                      value: assignment,
                                      child: Text(assignment.name),
                                    );
                                  })),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedAssignment = newValue;
                                  });
                                },
                              ))),
                      SizedBox(width: 10),
                      Expanded(
                          child: Opacity(
                              opacity: selectedCourse == null ? .5 : 1,
                              child: DropdownButtonFormField<Participant?>(
                                decoration: InputDecoration(
                                    labelText: 'Select Student',
                                    border: OutlineInputBorder(),
                                    disabledBorder: null,
                                    enabled: selectedCourse != null),
                                value: selectedStudent,
                                dropdownColor: selectedCourse == null
                                    ? Colors.grey.shade400
                                    : null,
                                items: selectedCourse == null
                                    ? null
                                    : List.empty(growable: true)
                                  ?..add(DropdownMenuItem<Participant?>(
                                      value: null,
                                      child: Text('Select Student')))
                                  ..addAll(participants
                                      .map<DropdownMenuItem<Participant?>>(
                                          (participant) {
                                    return DropdownMenuItem<Participant?>(
                                      value: participant,
                                      child: Text(participant.fullname),
                                    );
                                  })),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedStudent = newValue;
                                  });
                                },
                              ))),
                      SizedBox(width: 10),
                      Expanded(
                              child: ElevatedButton(
                                onPressed: selectedCourse == null ? null : _selectStartDate,
                                child: startDate == null ? Text("Select Start Date") : Text("Start Date: ${getDateString(startDate!)}"),
                              )),
                      SizedBox(width: 10),
                      Expanded(
                              child: ElevatedButton(
                                onPressed: selectedCourse == null ? null : _selectEndDate,
                                child: endDate == null ? Text("Select End Date") : Text("End Date: ${getDateString(endDate!)}"),
                              )),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: (selectedCourse == null)
                            ? null
                            : _queryDatabase,
                        child: const Text('Filter'),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed:
                            logSource.sortedData.isEmpty ? null : _exportLogs,
                        child: const Text('Export Logs'),
                      ),
                    ]))
              ],
            ),
            SizedBox(height: 20),
            Visibility(
                visible: logSource.sortedData.isNotEmpty,
                child: Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Row(
                      children: [
                        Expanded(
                            child: PaginatedDataTable(
                          showCheckboxColumn: false,
                          sortColumnIndex: sortIndex,
                          sortAscending: sortAsc,
                          dataRowMaxHeight: double.infinity,
                          columns: [
                            DataColumn(
                                columnWidth: FixedColumnWidth(150),
                                label: Text(AiLog.getHeaderForColumn(0)),
                                onSort: sort),
                            DataColumn(
                                columnWidth: FixedColumnWidth(150),
                                label: Text(AiLog.getHeaderForColumn(1)),
                                onSort: sort),
                            DataColumn(
                                columnWidth: FixedColumnWidth(150),
                                label: Text(AiLog.getHeaderForColumn(2)),
                                onSort: sort),
                            DataColumn(
                                columnWidth: FixedColumnWidth(225),
                                label: Text(AiLog.getHeaderForColumn(3)),
                                onSort: sort),
                            DataColumn(
                                columnWidth: FixedColumnWidth(225),
                                label: Text(AiLog.getHeaderForColumn(4)),
                                onSort: sort),
                            DataColumn(
                                columnWidth: FixedColumnWidth(225),
                                label: Text(AiLog.getHeaderForColumn(5)),
                                onSort: sort),
                            DataColumn(
                                columnWidth: FixedColumnWidth(150),
                                label: Text(AiLog.getHeaderForColumn(6)),
                                onSort: sort),
                            DataColumn(
                                label: Text(AiLog.getHeaderForColumn(7)),
                                onSort: sort),
                          ],
                          source: logSource,
                        ))
                      ],
                    ),
                  ),
                )),
            Visibility(
                visible: isLoading,
                child: Align(child: CircularProgressIndicator())),
            Visibility(
                visible: logSource.sortedData.isEmpty,
                child: Expanded(
                    child: Align(
                        child: Text(
                            textAlign: TextAlign.center,
                            style:
                                isError ? TextStyle(color: Colors.red) : null,
                            message))))
          ],
        ));
  }
  
  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      cancelText: "Clear",
      context: context,
      initialDate: endDate == null ? DateTime.now() : endDate!,
      firstDate: DateTime(2025, 9),
      lastDate: endDate == null ? DateTime.now() : endDate!,
    );
    
    setState(() {
      startDate = picked == null ? null : DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      cancelText: "Clear",
      context: context,
      initialDate: DateTime.now(),
      firstDate: startDate == null ? DateTime(2025, 9) : startDate!,
      lastDate: DateTime.now(),
    );
    
    setState(() {
      endDate = picked == null ? null : DateTime(picked.year, picked.month, picked.day);
    });
  }

  String getDateString(DateTime date) {
    return date.toLocal().toString().split(' ')[0];
  }
}

class _AiLogSource extends DataTableSource {
  @override
  int get rowCount => sortedData.length;
  _AiLogScreenState parentState;
  late List<AiLog> sortedData = [];
  _AiLogSource(this.parentState);
  void selectedChanged() {
    notifyListeners();
  }

  void setData(List<AiLog> data, int sortCol, bool sortAscending) {
    sortedData = data.toList()
      ..sort((AiLog a, AiLog b) {
        final Comparable cellA = a.getValueForColumn(sortCol);
        final Comparable cellB = b.getValueForColumn(sortCol);
        return (sortAscending ? 1 : -1) * cellA.compareTo(cellB);
      });
    notifyListeners();
  }

  DataCell cellFor(int row, int column) {
    return DataCell(Text(
      sortedData[row].getValueForColumn(column).toString(),
      softWrap: true,
      textAlign: TextAlign.start,
      maxLines: row == parentState.selected ? null : 3,
      overflow: row == parentState.selected ? null : TextOverflow.ellipsis,
    ));
  }

  @override
  DataRow? getRow(int index) {
    return DataRow(
        onSelectChanged: (value) => {parentState.selectionChanged(index)},
        selected: index == parentState.selected,
        color:
            WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(parentState.context)
                .colorScheme
                .primary
                .withOpacity(0.15);
          }
          if (states.contains(WidgetState.hovered)) {
            return Theme.of(parentState.context)
                .colorScheme
                .primary
                .withOpacity(0.25);
          }
          return index % 2 == 0
              ? Theme.of(parentState.context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(.55)
              : null; // Use the default value.
        }),
        key: ObjectKey(sortedData[index].uuid),
        cells: <DataCell>[
          cellFor(index, 0),
          cellFor(
            index,
            1,
          ),
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
  int get selectedRowCount {
    return parentState.selected != null ? 1 : 0;
  }
}
