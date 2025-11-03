import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/database/ai_logging_singleton.dart';
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
  final DateTime earliestPossibleDate = DateTime(2025, 9, 1);
  final DateTime lastPossibleDate = DateTime(DateTime.now().year,
      DateTime.now().month, DateTime.now().day, 23, 59, 59, 999, 999);

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
            startDate ?? earliestPossibleDate,
            endDate ?? lastPossibleDate);
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
      selected = index;
      logSource.selectedChanged();
      _showDetailsDialog(context);
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
    excel.rename('Sheet1', 'AI Logs');
    // Dynamic export for student breakdown.
    Sheet studentSheet = excel['AI Logs'];
    if (logSource.sortedData.isNotEmpty) {
      // Get headers dynamically from the first map.
      var studentHeaders = [
        TextCellValue(AiLog.getHeaderForColumn(0)),
        TextCellValue(AiLog.getHeaderForColumn(1)),
        TextCellValue(AiLog.getHeaderForColumn(2)),
        TextCellValue(AiLog.getHeaderForColumn(3)),
        TextCellValue(AiLog.getHeaderForColumn(4)),
        TextCellValue(AiLog.getHeaderForColumn(5)),
        TextCellValue(AiLog.getHeaderForColumn(6)),
        TextCellValue(AiLog.getHeaderForColumn(7)),
      ];
      studentSheet.appendRow(studentHeaders);
      // Append each student row by mapping the values to strings.
      for (var log in logSource.sortedData) {
        studentSheet.appendRow(
          [
            TextCellValue(log.getStringForColumn(0)),
            TextCellValue(log.getStringForColumn(1)),
            TextCellValue(log.getStringForColumn(2)),
            TextCellValue(log.getStringForColumn(3)),
            TextCellValue(log.getStringForColumn(4)),
            TextCellValue(log.getStringForColumn(5)),
            TextCellValue(log.getStringForColumn(6)),
            TextCellValue(log.getStringForColumn(7)),
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
                        isExpanded: true,
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
                                isExpanded: true,
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
                                isExpanded: true,
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
                        onPressed:
                            selectedCourse == null ? null : _selectStartDate,
                        child: startDate == null
                            ? Text("Select Start Date",
                                maxLines: 3, textAlign: TextAlign.center)
                            : Text("Start Date: ${getDateString(startDate!)}",
                                maxLines: 3, textAlign: TextAlign.center),
                      )),
                      SizedBox(width: 10),
                      Expanded(
                          child: ElevatedButton(
                        onPressed:
                            selectedCourse == null ? null : _selectEndDate,
                        child: endDate == null
                            ? Text("Select End Date",
                                maxLines: 3, textAlign: TextAlign.center)
                            : Text("End Date: ${getDateString(endDate!)}",
                                maxLines: 3, textAlign: TextAlign.center),
                      )),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed:
                            (selectedCourse == null) ? null : _queryDatabase,
                        child: const Text('Filter', maxLines: 1),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed:
                            logSource.sortedData.isEmpty ? null : _exportLogs,
                        child: const Text('Export Logs',
                            maxLines: 2, textAlign: TextAlign.center),
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
                          dataRowMaxHeight: 70,
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
      initialDate: startDate ?? (endDate ?? lastPossibleDate),
      firstDate: earliestPossibleDate,
      lastDate: endDate ?? lastPossibleDate,
    );

    setState(() {
      startDate = picked == null
          ? null
          : DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      cancelText: "Clear",
      context: context,
      initialDate: lastPossibleDate,
      firstDate: endDate ?? (startDate ?? earliestPossibleDate),
      lastDate: lastPossibleDate,
    );

    setState(() {
      endDate = picked == null
          ? null
          : DateTime(
              picked.year, picked.month, picked.day, 23, 59, 59, 999, 999);
    });
  }

  String getDateString(DateTime date) {
    return DateFormat.yMd().format(date.toLocal());
  }

  // Function to show details in a dialog
  void _showDetailsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("AI Interaction"),
            content: SingleChildScrollView(
                child: Column(children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 6, 0, 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SelectionArea(
                          child: Text(
                        logSource.sortedData[selected!].getStringForColumn(3),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )))),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 6, 20, 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: MarkdownBody(
                        data: logSource.sortedData[selected!]
                            .getStringForColumn(4),
                        selectable: true,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          em: const TextStyle(fontStyle: FontStyle.italic),
                          a: const TextStyle(
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ))),
              Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 6, 20, 6),
                      padding: const EdgeInsets.all(14),
                      decoration: logSource.sortedData[selected!]
                              .getStringForColumn(5)
                              .isEmpty
                          ? null
                          : BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                      child: MarkdownBody(
                        data: logSource.sortedData[selected!]
                                .getStringForColumn(5)
                                .isEmpty
                            ? "There was no micro-reflection for this AI prompt."
                            : logSource.sortedData[selected!]
                                .getStringForColumn(5),
                        selectable: true,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: TextStyle(
                              fontSize: 16,
                              color: logSource.sortedData[selected!]
                                      .getStringForColumn(5)
                                      .isEmpty
                                  ? Colors.grey
                                  : Colors.white,
                              fontStyle: logSource.sortedData[selected!]
                                      .getStringForColumn(5)
                                      .isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          em: const TextStyle(fontStyle: FontStyle.italic),
                          a: const TextStyle(
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )))
            ])),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Close"),
              ),
            ],
          );
        });
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
    return DataCell(AiLog.isMarkdown(column)
        ? Wrap(
            clipBehavior: Clip.hardEdge,
            direction: Axis.horizontal,
            children: [
                MarkdownBody(
                  data: sortedData[row].getStringForColumn(column),
                  shrinkWrap: true,
                  softLineBreak: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(parentState.context))
                      .copyWith(
                    p: const TextStyle(
                        color: Colors.black87, overflow: TextOverflow.ellipsis),
                    strong: const TextStyle(fontWeight: FontWeight.bold),
                    em: const TextStyle(fontStyle: FontStyle.italic),
                    a: const TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ])
        : Text(
            sortedData[row].getStringForColumn(column),
            softWrap: true,
            textAlign: TextAlign.start,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
