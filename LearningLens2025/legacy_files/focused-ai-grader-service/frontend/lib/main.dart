import 'package:flutter/material.dart';
import 'screens/code_editor_screen.dart';

void main() {
  runApp(const TeacherGradingApp());
}

class TeacherGradingApp extends StatelessWidget {
  const TeacherGradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusEd AI - Teacher Grading System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
        fontFamily: 'system-ui',
      ),
      home: const EnhancedCodeEditorScreen(),
    );
  }
}