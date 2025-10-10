import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/program_assessment_form.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ProgramAssessmentView extends StatefulWidget{
  ProgramAssessmentView();
  @override
  ProgramAssessmentState createState() => ProgramAssessmentState();
}

class ProgramAssessmentState extends State<ProgramAssessmentView>{
  final lmsService = LmsFactory.getLmsService();
  final codeEvalUrl = LocalStorageService.getCodeEvalUrl();
  List<Course> _courses = [];
  List<Assignment> assignments = [];
  List<dynamic> _evaluationResults = [];
  
  Course? selectedCourse;
  Assignment? selectedAssignment;

  static Future<void> createDb() async{
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
  Future<List<dynamic>> _getEvaluations(String username) async{
    final response = await ApiService().httpGet(
      Uri.parse('$codeEvalUrl/?username=$username'),
    );

    if(response.statusCode != 200) return [];

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
      body: LayoutBuilder(
        builder: (context, constraints){
          return FutureBuilder<List<dynamic>>(
            future: Future.wait([
              _fetch(),
              _getEvaluations(lmsService.userName!)
            ]),
            builder: (context, snapshot) {
              if(snapshot.connectionState == ConnectionState.waiting){
                return Center(child: CircularProgressIndicator());
              }
              else if(snapshot.hasError){
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              else{
                return _buildMainLayout();
              }
            }
          );
        }
      )
    );
  }

  Widget _buildMainLayout(){
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row with Create button aligned right
          CourseForm(
            courses: _courses,
            onEvaluationStarted: (course, assignment, expectedOutput) async {
              final results = await _getEvaluations(lmsService.userName!);
              setState(() {
                _evaluationResults = results;
              });
            }
          ),
          const SizedBox(height: 16),
          // Second row with DataTable
          _buildDataTable(),
        ],
      );
  }

  // Creates a row in the table
  DataRow _createDataRow(dynamic result){
    final course = _courses.firstWhere((c) => c.id.toString() == result['course_id']);
    final assignment = course.essays!.firstWhere((a) => a.id.toString() == result['assignment_id']);
    return DataRow(cells: [
      DataCell(Text(course.fullName)),
      DataCell(Text(assignment.name)),
      DataCell(Text(result['status'])),
      DataCell(
        ElevatedButton(
          onPressed: () {
            print('HANDLE VIEW ACTION');
          },
          child: const Text("View"),
        )
      ),
    ]);
  }

  Widget _buildDataTable(){
    return Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Course")),
                  DataColumn(label: Text("Assignment")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Action")),
                ],
                rows: _evaluationResults.map(_createDataRow).toList(),
              ),
            ),
          );
  }
}