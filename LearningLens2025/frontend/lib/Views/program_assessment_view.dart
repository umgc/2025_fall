import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ProgramAssessmentView extends StatefulWidget{
  ProgramAssessmentView();
  @override
  ProgramAssessmentState createState() => ProgramAssessmentState();
}

class CodingAssignment {
  final int id;
  final String name;
  final String evaluationStatus;
  final Future<void> Function() onPressed;

  CodingAssignment({
    required this.id,
    required this.name,
    required this.evaluationStatus,
    required this.onPressed,
  });
}

class CodingAssignmentDataSource extends DataTableSource {
  final List<CodingAssignment> assignments;

  CodingAssignmentDataSource(this.assignments);

  @override
  DataRow getRow(int index) {
    if (index >= assignments.length) return const DataRow(cells: []);
    final assignment = assignments[index];

    return DataRow(
      cells: [
        DataCell(Text(assignment.name)),
        DataCell(
          Text(assignment.evaluationStatus, style: TextStyle(fontWeight: FontWeight.bold),)
          ),
        DataCell(
          ElevatedButton(
            onPressed: assignment.onPressed,
            child: const Text("Assess"),
          ),
        ),
      ],
    );
  }
  
  @override
  bool get isRowCountApproximate => false;
  
  @override
  int get rowCount => assignments.length;
  
  @override
  int get selectedRowCount => 0;
}

class ProgramAssessmentState extends State<ProgramAssessmentView>{
  final lmsService = LmsFactory.getLmsService();
  final codeEvalUrl = LocalStorageService.getCodeEvalUrl();
  bool _isLoading = false;
  List<dynamic> _evaluationResults = [];
  late Future<List<Course>> _courses;
  List<Assignment> assignments = [];
  Course? selectedCourse;
  Assignment? selectedAssignment;

  @override
  void initState() {
    super.initState();
    _courses = _fetch();
  }
  
  void _showSnackBar(SnackBar snackBar){
      if(mounted){
        ScaffoldMessenger.of(context)
        .showSnackBar(snackBar);
      }
  }

  Future<List<Course>> _fetch() async => await lmsService.getUserCourses();
  
  // Gets code evaluations for all assignments in a course
  Future<List<dynamic>> _getEvaluationsForCourse(String courseId) async{
    final response = await ApiService().httpGet(
      Uri.parse('$codeEvalUrl/?courseId=$courseId'),
    );

    if(response.statusCode != 200) return [];

    final evaluationResults = jsonDecode(response.body) as List<dynamic>;

    setState(() {
      _isLoading = false;
      _evaluationResults = evaluationResults;
    });

    return evaluationResults;
  }
  // Gets the code evaluation for a specific assignment
  dynamic _getEvalStatusForAssignment(String courseId, String assignmentId){
    return _evaluationResults
      .firstWhereOrNull(
        (result) => result['course_id'] == courseId && result['assignment_id'] == assignmentId
      );
  }

  Future<void> _startEvaluation(String courseId, String assignmentId) async{
    final response = await ApiService().httpPost(
      Uri.parse(codeEvalUrl),
      body: jsonEncode({
        'courseId': courseId,
        'assignmentId': assignmentId
      }),
    );
  
    if(response.statusCode != 200){
      _showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Unable to evaluate coding assignment: status code ${response.statusCode}')
        )
      );
      return;
    }

    _showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Evaluation started successfully')
      )
    );

    // Reload table with new data
    await _getEvaluationsForCourse(courseId);
  }

  void _onCourseChanged(Course? course) {
    if (course == null) return;
    setState(() {
      selectedCourse = course;
    });
  }

  void _openCreateDialog(List<Course> courses) {
    selectedCourse = null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Assignment"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course dropdown
              DropdownButtonFormField<Course>(
                decoration: const InputDecoration(labelText: "Course"),
                items: courses
                    .map((course) => DropdownMenuItem(
                          value: course,
                          child: Text(course.fullName),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCourse = value!;
                    selectedAssignment = null; // reset assignment when course changes
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Assignment dropdown
              DropdownButtonFormField<Assignment>(
                // value: selectedAssignment,
                decoration: const InputDecoration(labelText: "Assignment"),
                items: selectedCourse == null
                    ? []
                    : selectedCourse!.essays!
                        .map((assignment) => DropdownMenuItem(
                              value: assignment,
                              child: Text(assignment.name),
                            ))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAssignment = value;
                  });
                },
              ),
              // const SizedBox(height: 16),

              // Expected Output text area
              // TextFormField(
              //   controller: expectedOutputController,
              //   decoration: const InputDecoration(
              //     labelText: "Expected Output",
              //     border: OutlineInputBorder(),
              //   ),
              //   maxLines: 3,
              // ),
              // const SizedBox(height: 16),

              // // Disabled max time limit input
              // TextFormField(
              //   decoration: const InputDecoration(
              //     labelText: "Maximum Time Limit (seconds)",
              //     border: OutlineInputBorder(),
              //   ),
              //   initialValue: "30",
              //   enabled: false,
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle form submission here
              // print("Course: $selectedCourse");
              // print("Assignment: $selectedAssignment");
              // print("Expected Output: ${expectedOutputController.text}");
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Program Assessment',
        userprofileurl: lmsService.profileImage ?? '',
      ),
      body: LayoutBuilder(
        builder: (context, constraints){
          return FutureBuilder<List<Course>>(
            future: _courses,
            builder: (context, snapshot) {
              if(snapshot.connectionState == ConnectionState.waiting){
                return Center(child: CircularProgressIndicator());
              }
              else if(snapshot.hasError){
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              else{
                return _buildMainLayout(snapshot.data!);
              }
            }
          );
        }
      )
    );
  }

  Widget _buildMainLayout(List<Course> courses){
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row with Create button aligned right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                    _openCreateDialog(courses);
                  // Handle create action
                },
                child: const Text("Create"),
              ),
              const SizedBox(width: 16), // some spacing from edge
            ],
          ),

          const SizedBox(height: 16),

          // Second row with DataTable
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Course")),
                  DataColumn(label: Text("Assignment")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Action")),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text("Math 101")),
                    const DataCell(Text("Homework 1")),
                    const DataCell(Text("Pending")),
                    DataCell(
                      ElevatedButton(
                        onPressed: () {
                          // Handle view action
                        },
                        child: const Text("View"),
                      ),
                    ),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("History 202")),
                    const DataCell(Text("Essay")),
                    const DataCell(Text("Completed")),
                    DataCell(
                      ElevatedButton(
                        onPressed: () {
                          // Handle view action
                        },
                        child: const Text("View"),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildCourseListView(List<Course> courses){
    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return ListTile(
          title: Text(course.fullName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${course.shortName}${course.courseId}'),
              Text(
                '${Course.dateFormatted(course.startdate)} - ${Course.dateFormatted(course.enddate)}'
              ),
            ],
          ),
          tileColor: selectedCourse == course
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.1)
              : null,
          onTap: () {
            setState(() {
              selectedCourse = course;
              _isLoading = true;
              _evaluationResults = [];
            });
            _getEvaluationsForCourse(course.courseId);
          },
        );
      },
    );
  }

  Widget _buildAssignmentTable(Course selectedCourse) {
    final assignments = 
    (selectedCourse.essays ?? [])
    .map((assignment) {
      final courseId = selectedCourse.courseId;
      final assignmentId = assignment.id.toString();
      dynamic evalStatus = _getEvalStatusForAssignment(courseId, assignmentId);

      return CodingAssignment(
          id: assignment.id,
          name: assignment.name,
          evaluationStatus: evalStatus != null ? evalStatus['status'] : 'Not Started',
          onPressed: () async => await _startEvaluation(courseId, assignmentId)
        );
      }
    )
    .toList();

    if(assignments.isEmpty){
      return Center(
        child: Text("Course has no assignments."),
      );
    }

    TextStyle boldFont = TextStyle(fontWeight: FontWeight.bold);

    final table = PaginatedDataTable(
      header: const Text("Assignments"),
      columns: [
        DataColumn(label: Text("Assignment Name", style: boldFont)),
        DataColumn(label: Text("Evaluation Status", style: boldFont)),
        DataColumn(label: Text("Action", style: boldFont)),
      ],
      source: CodingAssignmentDataSource(assignments),
      rowsPerPage: 5, // Adjust as needed
    );

   final container = Container(
        decoration: BoxDecoration(
        color: Colors.white, // background color
        borderRadius: BorderRadius.circular(12), // rounded corners
        border: Border.all(
          color: Colors.grey, // border color
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2), // subtle shadow
          ),
        ],
      ),
      child: table,
    );

    return container;
  }
}