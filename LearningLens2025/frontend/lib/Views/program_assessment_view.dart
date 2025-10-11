import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/program_assessment_form.dart';
import 'package:learninglens_app/Views/program_assessment_results_view.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ProgramAssessmentView extends StatefulWidget {
  ProgramAssessmentView();
  @override
  ProgramAssessmentState createState() => ProgramAssessmentState();
}

class EvaluationDataSource extends DataTableSource {
  final BuildContext context;
  final List<dynamic> results;
  final List<Course> courses;
  final dynamic lmsService;

  EvaluationDataSource({
    required this.context,
    required this.results,
    required this.courses,
    required this.lmsService,
  });

  String _formatDateTime(String? dateString) {
    if (dateString == null) return '';

    // Parse the input string into a DateTime object
    final dateTime = DateTime.parse(dateString).toLocal();

    // Format date and time
    final datePart = DateFormat('MM/dd/yyyy').format(dateTime);
    final timePart = DateFormat('hh:mm a').format(dateTime);

    return '$datePart at $timePart';
  }

  @override
  DataRow? getRow(int index) {
    if (index >= results.length) return null;
    final result = results[index];

    final course =
        courses.firstWhere((c) => c.id.toString() == result['course_id']);
    final assignment = course.essays!
        .firstWhere((a) => a.id.toString() == result['assignment_id']);
    final jobStatus = result['status'];

    final startTime = _formatDateTime(result['start_time']);
    final finishTime = _formatDateTime(result['finish_time']);

    return DataRow(color: MaterialStatePropertyAll(Colors.white), cells: [
      DataCell(Text(course.fullName)),
      DataCell(Text(assignment.name)),
      DataCell(Text(result['language'])),
      DataCell(Text(result['status'])),
      DataCell(Text(startTime)),
      DataCell(Text(finishTime)),
      DataCell(Row(spacing: 8, children: [
        ElevatedButton(
          onPressed: jobStatus == 'JOB FINISHED'
              ? () async {
                  final participants = await lmsService
                      .getCourseParticipants(course.id.toString());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProgramAsessmentResultsView(
                        evaluation: result,
                        assignment: assignment,
                        course: course,
                        participants: participants,
                      ),
                    ),
                  );
                }
              : null,
          child: const Text("View"),
        ),
        // ElevatedButton(
        //   onPressed: jobStatus == 'JOB Started'
        //       ? () async {} : null,
        //   child: const Text("Refresh"),
        // ),
      ])),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => results.length;

  @override
  int get selectedRowCount => 0;
}

// --------------------- WIDGET ---------------------
class EvaluationTable extends StatelessWidget {
  final List<dynamic> evaluationResults;
  final List<Course> courses;
  final dynamic lmsService;

  const EvaluationTable({
    super.key,
    required this.evaluationResults,
    required this.courses,
    required this.lmsService,
  });

  @override
  Widget build(BuildContext context) {
    final dataSource = EvaluationDataSource(
      context: context,
      results: evaluationResults,
      courses: courses,
      lmsService: lmsService,
    );

    const headingStyle =
        TextStyle(fontWeight: FontWeight.bold, color: Colors.white);

    return PaginatedDataTable(
      // header: const Text('Program Evaluations'),
      headingRowColor: MaterialStatePropertyAll(Colors.deepPurpleAccent),
      showEmptyRows: false,
      columns: const [
        DataColumn(label: Text("Course", style: headingStyle)),
        DataColumn(label: Text("Assignment", style: headingStyle)),
        DataColumn(label: Text("Language", style: headingStyle)),
        DataColumn(label: Text("Status", style: headingStyle)),
        DataColumn(label: Text("Start Time", style: headingStyle)),
        DataColumn(label: Text("Finish Time", style: headingStyle)),
        DataColumn(label: Text("Action", style: headingStyle)),
      ],
      source: dataSource,
      rowsPerPage: 10,
      columnSpacing: 24,
      dataRowHeight: 64,
    );
  }
}

class ProgramAssessmentState extends State<ProgramAssessmentView> {
  final lmsService = LmsFactory.getLmsService();
  final codeEvalUrl = LocalStorageService.getCodeEvalUrl();
  List<Course> _courses = [];
  List<Assignment> assignments = [];
  List<dynamic> _evaluationResults = [];

  Course? selectedCourse;
  Assignment? selectedAssignment;

  static Future<void> createDb() async {
    final url =
        Uri.parse("${LocalStorageService.getCodeEvalUrl()}/?command=createDb");
    await http.get(url);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<List<Course>> _fetch() async {
    _courses = await lmsService.getUserCourses();
    return _courses;
  }

  // Gets code evaluations for all assignments in a course
  Future<List<dynamic>> _getEvaluations(String username) async {
    final response = await ApiService().httpGet(
      Uri.parse('$codeEvalUrl/?username=$username'),
    );

    if (response.statusCode != 200) return [];

    _evaluationResults = jsonDecode(response.body) as List<dynamic>;
    return _evaluationResults;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Program Assessment',
          userprofileurl: lmsService.profileImage ?? '',
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return FutureBuilder<List<dynamic>>(
              future: Future.wait(
                  [_fetch(), _getEvaluations(lmsService.userName!)]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return _buildMainLayout();
                }
              });
        }));
  }

  Widget _buildMainLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // First row with Create button aligned right
        ProgramAssessmentForm(
            courses: _courses,
            onEvaluationStarted: (course, assignment, expectedOutput) async {
              final results = await _getEvaluations(lmsService.userName!);
              setState(() {
                _evaluationResults = results;
              });
            }),
        const SizedBox(height: 16),
        // Second row with DataTable
        Padding(
          padding: EdgeInsets.all(12),
          child: EvaluationTable(
              evaluationResults: _evaluationResults,
              courses: _courses,
              lmsService: lmsService),
        )
      ],
    );
  }
}
