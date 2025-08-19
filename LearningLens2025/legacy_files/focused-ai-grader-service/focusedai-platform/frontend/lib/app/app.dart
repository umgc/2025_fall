// lib/app/app.dart - Updated with CourseProvider
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/theme.dart';
import '../core/models/assignment.dart';
import '../core/models/course.dart';
import '../core/models/submission.dart';
import '../features/grading/providers/course_provider.dart';
import '../features/grading/providers/grading_provider.dart';
import '../features/code_execution/providers/execution_provider.dart';
import '../features/grading/screens/grading_interface_screen.dart';

class CodeGradingApp extends StatelessWidget {
  const CodeGradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ExecutionProvider()),
        ChangeNotifierProvider(create: (_) => GradingProvider()),
      ],
      child: MaterialApp(
        title: 'Code Grading Interface',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const GradingInterfaceScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/grading': (context) => const GradingInterfaceScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const GradingInterfaceScreen(),
          );
        },
      ),
    );
  }
}

// Integration Widget for Parent Applications
class CodeGradingInterface extends StatelessWidget {
  final String? backendUrl;
  final Map<String, String>? authHeaders;
  final List<Course>? courses;
  final List<Assignment>? assignments;
  final List<Submission>? submissions;
  final Function(Map<String, dynamic>)? onGradeSubmitted;
  final Function(String)? onAssignmentSelected;
  final Function(String)? onCourseSelected;
  final VoidCallback? onError;

  const CodeGradingInterface({
    super.key,
    this.backendUrl,
    this.authHeaders,
    this.courses,
    this.assignments,
    this.submissions,
    this.onGradeSubmitted,
    this.onAssignmentSelected,
    this.onCourseSelected,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = CourseProvider(
              backendUrl: backendUrl,
              authHeaders: authHeaders,
            );
            
            // Set initial courses if provided
            if (courses != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.setCourses(courses!);
              });
            }
            
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ExecutionProvider(
            backendUrl: backendUrl,
            authHeaders: authHeaders,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = GradingProvider(
              backendUrl: backendUrl,
              authHeaders: authHeaders,
              onGradeSubmitted: onGradeSubmitted,
            );
            
            // Set initial submissions if provided
            if (submissions != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.setSubmissions(submissions!);
              });
            }
            
            return provider;
          },
        ),
      ],
      child: Material(
        child: GradingInterfaceScreen(
          onAssignmentSelected: onAssignmentSelected,
          onError: onError,
        ),
      ),
    );
  }
}

// Integration Usage Example:
/*
class ParentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CodeGradingInterface(
          backendUrl: 'http://localhost:8080',
          authHeaders: {'Authorization': 'Bearer your-token'},
          courses: yourCoursesList,
          submissions: yourSubmissionsList,
          onGradeSubmitted: (gradeData) {
            print('Grade submitted: $gradeData');
            // Handle grade submission in your parent app
          },
          onAssignmentSelected: (assignmentId) {
            print('Assignment selected: $assignmentId');
            // Handle assignment selection in your parent app
          },
          onError: () {
            print('Error occurred in grading interface');
            // Handle errors in your parent app
          },
        ),
      ),
    );
  }
}
*/