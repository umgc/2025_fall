import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/program_assessment_form.dart';
import 'package:learninglens_app/Views/program_assessment_results_view.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/program_assessment_service.dart';

class ProgramAssessmentView extends StatefulWidget {
  ProgramAssessmentView();
  @override
  ProgramAssessmentState createState() => ProgramAssessmentState();
}

class EvaluationDataSource extends DataTableSource {
  final BuildContext context;
  final List<ProrgramAssessmentJob> results;
  final List<Course> courses;
  final dynamic lmsService;
  final Future<void> Function(
      Course course, Assignment assignment, ProrgramAssessmentJob job) onDelete;

  EvaluationDataSource({
    required this.context,
    required this.results,
    required this.courses,
    required this.lmsService,
    required this.onDelete,
  });

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    dateTime = dateTime.toLocal();

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
        courses.firstWhere((c) => c.id.toString() == result.courseId);
    final assignment = course.essays!
        .firstWhere((a) => a.id.toString() == result.assignmentId);

    final startTime = _formatDateTime(result.startTime);
    final finishTime = _formatDateTime(result.finishTime);

    final bool thirtySecondsPassed =
        DateTime.now().difference(result.startTime).inSeconds >= 30;

    return DataRow(color: MaterialStatePropertyAll(Colors.white), cells: [
      DataCell(Text(course.fullName)),
      DataCell(Text(assignment.name)),
      DataCell(Text(result.language)),
      DataCell(Text(result.status)),
      DataCell(Text(startTime)),
      DataCell(Text(finishTime)),
      DataCell(Row(spacing: 8, children: [
        ElevatedButton(
          onPressed: result.status == 'JOB FINISHED'
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // red background
            foregroundColor: Colors.white, // white text and icon
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // Enable the delete button only if the job is finished or 30 seconds have passed
          onPressed: result.status == 'JOB FINISHED' || thirtySecondsPassed
              ? () async {
                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: Text(
                            'Are you sure you want to delete the evaluation for assignment "${assignment.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmDelete == true) {
                    await onDelete(course, assignment, result);
                  }
                }
              : null,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Delete"),
              SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.white),
            ],
          ),
        ),
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

class EvaluationTable extends StatelessWidget {
  final List<ProrgramAssessmentJob> evaluationResults;
  final List<Course> courses;
  final dynamic lmsService;
  final Future<void> Function(
      Course course, Assignment assignment, ProrgramAssessmentJob job) onDelete;

  const EvaluationTable({
    super.key,
    required this.evaluationResults,
    required this.courses,
    required this.lmsService,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dataSource = EvaluationDataSource(
        context: context,
        results: evaluationResults,
        courses: courses,
        lmsService: lmsService,
        onDelete: onDelete);

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
      rowsPerPage: 5,
      columnSpacing: 24,
      dataRowHeight: 82,
    );
  }
}

class ProgramAssessmentState extends State<ProgramAssessmentView> {
  final lmsService = LmsFactory.getLmsService();
  final codeEvalUrl = LocalStorageService.getCodeEvalUrl();
  final _assessmentService = ProgramAssessmentService();

  List<Course> _courses = [];
  List<Assignment> assignments = [];
  List<ProrgramAssessmentJob> _evaluationResults = [];

  Course? selectedCourse;
  Assignment? selectedAssignment;

  @override
  void initState() {
    super.initState();
  }

  Future<List<Course>> _fetch() async {
    _courses = await lmsService.getUserCourses();
    return _courses;
  }

  // Gets code evaluations for all assignments in a course
  Future<List<ProrgramAssessmentJob>> _getEvaluations(String username) async {
    _evaluationResults =
        await _assessmentService.getEvaluations(lmsService.userName!);
    return _evaluationResults;
  }

  Future<void> _refreshEvaluations() async {
    await _getEvaluations(lmsService.userName!);
    // To get view to reload
    setState(() {});
  }

  // Helper to show status messages (should probably make a service)
  void _showSnackBar(SnackBar snackBar) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
                  return Padding(
                      padding: EdgeInsets.all(12), child: _buildMainLayout());
                }
              });
        }));
  }

  Widget _buildCreateButton(VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors
            .deepPurpleAccent, // Use Theme.of(context).colorScheme.primary for dynamic theming
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      label: const Text(
        'New Assessment Job',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: const Icon(Icons.add, size: 20),
      iconAlignment:
          IconAlignment.end, // ensures icon is on the right (Flutter 3.16+)
    );
  }

  Widget _buildMainLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCreateButton(() {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProgramAssessmentForm(
                          evaluationResults: _evaluationResults,
                          courses: _courses,
                          onEvaluationStarted:
                              (course, assignment, expectedOutput) async {
                            final results = await _assessmentService
                                .getEvaluations(lmsService.userName!);
                            setState(() {
                              _evaluationResults = results;
                            });
                          })));
            }),
            ElevatedButton(
              onPressed: _refreshEvaluations,
              child: Text("Refresh"),
            )
          ],
        ),
        const SizedBox(height: 16),
        // Second row with DataTable
        EvaluationTable(
          evaluationResults: _evaluationResults,
          courses: _courses,
          lmsService: lmsService,
          onDelete: (course, assignment, job) async {
            final deleteSuccessful = await ProgramAssessmentService()
                .deleteEvaluation(
                    course: course,
                    assignment: assignment,
                    username: LmsFactory.getLmsService().userName!);

            if (deleteSuccessful) {
              _showSnackBar(SnackBar(
                  backgroundColor: Colors.green[700],
                  content: Text('Evaluation removed successfully')));
            } else {
              _showSnackBar(SnackBar(
                  backgroundColor: Colors.red[700],
                  content: Text('Unable to remove evaluation')));
            }

            await _refreshEvaluations();
          },
        ),
      ],
    );
  }
}
