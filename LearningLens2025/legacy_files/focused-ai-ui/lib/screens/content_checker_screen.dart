import 'package:flutter/material.dart';
import 'package:focused_ai_ui/widgets/composition_panel.dart';
import 'package:focused_ai_ui/widgets/content_logs_panel.dart';
import 'package:focused_ai_ui/widgets/header.dart';
import 'package:focused_ai_ui/widgets/navigation_panel.dart';
import 'package:focused_ai_ui/widgets/submission_panel.dart';

class ContentCheckerApp extends StatelessWidget {
  const ContentCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Content Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const ContentCheckerScreen(),
    );
  }
}

class ContentCheckerScreen extends StatefulWidget {
  const ContentCheckerScreen({super.key});

  @override
  State<ContentCheckerScreen> createState() => _ContentCheckerScreenState();
}

class _ContentCheckerScreenState extends State<ContentCheckerScreen> {
  String selectedCourse = '';
  String selectedAssignment = '';
  String selectedSubmission = '';

  void updateSelection(String course, String assignment, String submission) {
    setState(() {
      selectedCourse = course;
      selectedAssignment = assignment;
      selectedSubmission = submission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFa8d5a8),
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavigationPanel(
                  onSelectionChanged: updateSelection,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              SubmissionPanel(
                                submission: selectedSubmission,
                              ),
                              const SizedBox(height: 12),
                              CompositionPanel(
                                submission: selectedSubmission,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: LogsPanel(
                            submission: selectedSubmission,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}