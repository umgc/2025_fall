import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';

class ProgramAssessmentView extends StatefulWidget{
  ProgramAssessmentView();
  @override
  ProgramAssessmentState createState() => ProgramAssessmentState();
}

class ProgramAssessmentState extends State<ProgramAssessmentView>{
  final lmsService = LmsFactory.getLmsService();
  late Future<List<Assignment>> _data;

  @override
  void initState() {
    super.initState();
    _data = _fetch();
  }
  
  Future<List<Assignment>> _fetch() async {
    List<Course> courses = await lmsService.getUserCourses();
    List<Assignment> assignments = [];

    for (var c in courses) {
      assignments.addAll(c.essays ?? []);
    }

    return assignments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Program Assessment',
        userprofileurl: lmsService.profileImage ?? '',
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _data,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          }
          else if(snapshot.hasError){
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          else{
            return Center(child: Text(snapshot.data!.toString()));
          }
        },
      ),
    );
  }
}