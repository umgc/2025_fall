import 'package:flutter/material.dart';
import 'assignment_generator_screen.dart';
class TeacherDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teacher Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssignmentGeneratorScreen())),
          child: Text('Generate Assignments & Rubrics'),
        ),
      ),
    );
  }
}
