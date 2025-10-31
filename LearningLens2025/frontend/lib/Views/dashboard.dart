import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/about_page.dart';
import 'package:learninglens_app/Views/analytics_page.dart';
import 'package:learninglens_app/Views/assessments_view.dart';
import 'package:learninglens_app/Views/course_list.dart';
import 'package:learninglens_app/Views/essay_assistant.dart';
import 'package:learninglens_app/Views/essays_view.dart';
import 'package:learninglens_app/Views/g_lesson_plan.dart';
import 'package:learninglens_app/Views/iep_page.dart';
import 'package:learninglens_app/Views/lesson_plans.dart';
import 'package:learninglens_app/Views/nav_card.dart';
import 'package:learninglens_app/Views/program_assessment_view.dart';
import 'package:learninglens_app/Views/student_reflections_page.dart';
import 'package:learninglens_app/Views/user_settings.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool canAccessApp = canUserAccessApp(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Learning Lens',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          if (!canAccessApp)
            Container(
              color: Colors.red[700],
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This application requires an LMS to be logged in and an LLM Key to function properly.",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildDesktopLayout(context, constraints);
                } else {
                  return _buildMobileLayout(context, constraints);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutPage()),
                  );
                },
                child: const Text("About Learning Lens"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool canUserAccessApp(BuildContext context) {
    return LocalStorageService.canUserAccessApp();
  }

  UserRole getUserRole() {
    return LmsFactory.getLmsService().role ?? UserRole.student;
  }

  String getClassroom() {
    return LocalStorageService.getClassroom();
  }

  bool isMoodle() {
    return LocalStorageService.isMoodle();
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    double middleButtonSize = baseButtonSize * 1.2;
    double middleButtonFontSize = baseButtonFontSize * 1.2;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.1;

    baseButtonSize = baseButtonSize.clamp(80.0, 150.0);
    baseButtonFontSize = baseButtonFontSize.clamp(12.0, 18.0);
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(12.0, 18.0);

    middleButtonSize = middleButtonSize.clamp(96.0, 180.0);
    middleButtonFontSize = middleButtonFontSize.clamp(14.0, 20.0);
    middleDescriptionFontSize = middleDescriptionFontSize.clamp(13.0, 20.0);

    double titleFontSize = screenWidth * 0.03;
    titleFontSize = titleFontSize.clamp(20.0, 32.0);

    bool canAccessApp = canUserAccessApp(context);
    if (!canAccessApp) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please Sign In to Continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28, // Large text
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Space between text and button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserSettings()),
                );
              },
              child: const Text("Click to Sign In"),
            ),
          ],
        ),
      );
    }

    UserRole role = getUserRole();
    String headerTxt = role == UserRole.teacher ? 'Teacher' : 'Student';

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$headerTxt ${getClassroom()} Dashboard',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome, ${LmsFactory.getLmsService().firstName ?? 'User'}',
                style: TextStyle(
                  fontSize: titleFontSize * 0.7,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildGridLayout(context, constraints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    double baseButtonSize = screenWidth * 0.35; // Reduced from 0.4
    double baseButtonFontSize = screenWidth * 0.04; // Reduced from 0.045
    double baseDescriptionFontSize = screenWidth * 0.035; // Reduced from 0.04

    double middleButtonSize = baseButtonSize * 1.1;
    double middleButtonFontSize = baseButtonFontSize * 1.1;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.05;

    baseButtonSize = baseButtonSize.clamp(70.0, 120.0); // Reduced max size
    baseButtonFontSize =
        baseButtonFontSize.clamp(10.0, 14.0); // Reduced max size
    baseDescriptionFontSize =
        baseDescriptionFontSize.clamp(10.0, 14.0); // Reduced max size

    middleButtonSize = middleButtonSize.clamp(77.0, 132.0);
    middleButtonFontSize = middleButtonFontSize.clamp(11.0, 16.0);
    middleDescriptionFontSize = middleDescriptionFontSize.clamp(11.0, 15.0);

    double titleFontSize = screenWidth * 0.06;
    titleFontSize = titleFontSize.clamp(16.0, 22.0); // Reduced max size

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced from 16.0
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Teacher Dashboard',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8), // Reduced from 12
              Text(
                'Welcome, ${LmsFactory.getLmsService().firstName ?? 'User'}',
                style: TextStyle(
                  fontSize: titleFontSize * 0.7,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12), // Reduced from 20
              _buildGridLayout(context, constraints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    baseButtonSize = baseButtonSize.clamp(70.0, 130.0); // Reduced max size
    baseButtonFontSize =
        baseButtonFontSize.clamp(10.0, 16.0); // Reduced max size
    baseDescriptionFontSize =
        baseDescriptionFontSize.clamp(10.0, 16.0); // Reduced max size

    UserRole role = getUserRole();
    bool isMoodleSelected = isMoodle();

    List<Map<String, dynamic>> buttonData = [
      {
        'title': 'Courses',
        'description': 'View available courses.',
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CourseList()),
            ),
        'icon': Icons.school_outlined
      },
      {
        'title': 'Essays',
        'description': 'View or grade essays.',
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EssaysView()),
            ),
        'icon': Icons.grade_outlined
      },
      {
        'title': 'Individualized Education Plan',
        'description': 'Manage Individualized Education Plans.',
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => IepPage()),
            ),
        'icon': Icons.architecture_outlined
      },
      {
        'title': 'Actionable Analytics',
        'description':
            "View AI-powered insights into student performance and potential action items.",
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnalyticsPage()),
            ),
        'icon': Icons.analytics_outlined
      },
      {
        'title': 'Lesson Plan',
        'description': 'Create and manage lesson plans.',
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    !isMoodleSelected ? GoogleLessonPlans() : LessonPlans(),
              ),
            ),
        'icon': Icons.book_outlined
      },
      {
        'title': 'Assessments',
        'description': 'Create or view assessments.',
        'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AssessmentsView()),
            ),
        'icon': Icons.quiz_outlined
      },
      {
        'title': 'Create Game',
        'description': 'Create games for students to learn while having fun.',
        'onPressed': () => Navigator.pushNamed(context, '/gamification'),
        'icon': Icons.videogame_asset_outlined
      },
      {
        'title': 'Program Assessment',
        'description': isMoodle()
            ? 'Automatically evaluate student programming assignments.'
            : 'Not implemented for Google Classroom',
        'onPressed': isMoodle()
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProgramAssessmentView()),
                )
            : null,
        'icon': Icons.terminal_outlined
      },
    ];

    if (role == UserRole.student) {
      buttonData = [
        {
          'title': 'Essay Assistant',
          'description': 'Utilize AI to help complete essay assignments.',
          'onPressed': () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => EssayAssistant())),
          'icon': Icons.assistant_outlined
        },
        {
          'title': 'Roleplay Assignment',
          'description': 'Complete AI-based roleplay assignments.',
          'onPressed': null,
          'icon': Icons.smart_toy_outlined
        },
        {
          'title': 'Games',
          'description': 'Participate in games assigned to you.',
          'onPressed': () => Navigator.pushNamed(context, '/gamification'),
          'icon': Icons.videogame_asset_outlined
        },
        {
          'title': 'Reflections',
          'description': 'Reflect on your use of AI for your assignments.',
          'onPressed': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => StudentReflectionsPage())),
          'icon': Icons.note_add_outlined
        },
      ];
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 1200),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: buttonData
            .map((data) => SizedBox(
                width: 350,
                height: 140,
                child: NavigationCard(
                    title: data['title'],
                    icon: data['icon'],
                    description: data['description'],
                    onPressed: data['onPressed'])))
            .toList(),
      ),
    );
  }
}
