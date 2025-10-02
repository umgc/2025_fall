import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
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
  Course? selectedCourse;

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
                final mainLayout = _buildMainLayout(snapshot.data!);
                // For mobile layout
                if(constraints.maxWidth < 600){
                  return Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      spacing: 8,
                      children: mainLayout,
                    )
                  );
                }

                return Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    spacing: 8,
                    children: mainLayout,
                  )
                );
              }
            }
          );
        }
      )
    );
  }

  List<Widget> _buildMainLayout(List<Course> courses){
    return [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: _buildCourseListView(courses)
          ),
        ),
        if(selectedCourse != null)
          if(_isLoading)
            Expanded(
              flex: 2,
              child: Center(child: CircularProgressIndicator())
            )
          else
            Expanded(
              flex: 2,
              child: _buildAssignmentTable(selectedCourse!)
            )
        else
          Expanded(
            flex: 2,
            child: Center(
              child: Text("Please select a course.")
            ),
          )
      ];
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