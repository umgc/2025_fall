import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learninglens_app/Api/database/ai_logging_singleton.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Views/assessments_view.dart';
import 'package:learninglens_app/Views/program_assessment_view.dart';
import 'package:learninglens_app/Views/user_settings.dart';
import 'package:learninglens_app/notifiers/login_notifier.dart';
import 'package:learninglens_app/notifiers/theme_notifier.dart';
import 'package:learninglens_app/services/gamification_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/program_assessment_service.dart';
import 'package:learninglens_app/services/reflection_service.dart';
import 'package:provider/provider.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'Views/dashboard.dart';
import 'Views/edit_questions.dart';
import 'Views/essay_generation.dart';
import 'Views/gamification_view.dart';
import 'Views/quiz_generator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load();
  // runApp(MyApp());
  await LocalStorageService.init(); // Initialize SharedPreferences
  await AILoggingSingleton().createDb();
  await AILoggingSingleton().clearOldDatabaseEntries();
  await ProgramAssessmentService.createDb();
  await GamificationService.createDb();
  await ReflectionService.createDb();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeNotifier()), // Theme provider
        ChangeNotifierProvider(
            create: (_) => LoginNotifier()), // Login provider
      ],
      child: MyApp(),
    ),
  );
}

//click and drag for intuitiveness
class CustomScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

//below is an app builder, leave it here for now
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<LoginNotifier>(context);

    // used to determine which dashboard to show based on the local storage system
    var selectedClassroom = LocalStorageService.getSelectedClassroom();
    var home = selectedClassroom == LmsType.MOODLE
        ? TeacherDashboard()
        : TeacherDashboard(); //GoogleTeacherDashboard();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Learning Lens",
      home: home,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Provider.of<ThemeNotifier>(context).primaryColor),
      ),
      scrollBehavior: CustomScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate, // <-- required for Quill
      ],
      supportedLocales: const [
        Locale('en'), // add more if you support multiple languages
      ],
      routes: {
        // '/EssayEditPage': (context) => EssayEditPage(jsonData),
        // '/Content': (context) => ViewCourseContents(),
        '/EssayGenerationPage': (context) =>
            EssayGeneration(title: 'Essay Generation'),
        '/QuizGenerationPage': (context) => CreateAssessment(),
        '/EditQuestions': (context) => EditQuestions(''),
        // '/create': (context) => const CreatePage(),
        '/dashboard': (context) => TeacherDashboard(),
        '/user': (context) => UserSettings(),
        //'/send_essay_to_moodle': (context) => EssayAssignmentSettings(''),
        '/assessments': (context) => AssessmentsView(),
        // '/viewExams': (context) => const View Exam Page(),
        // '/settings': (context) => Setting(themeModeNotifier: _themeModeNotifier)
        '/gamification': (context) => GamificationView(),
        '/evaluate': (context) => ProgramAssessmentView()
      },
    );
  }
}

class DevLaunch extends StatefulWidget {
  @override
  State createState() {
    return _DevLaunch();
  }
}

class _DevLaunch extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Dev Launch Page')),
        body: Column(children: [
          ElevatedButton(
              child: const Text('dashboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                );
              }),
          // ElevatedButton(
          //     child: const Text('Open Edit Essay'),
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => EssayEditPage(jsonData)),
          //       );
          //     }),
          // ElevatedButton(
          //     child: const Text('Open Contents Carousel'),
          //     onPressed: () async {
          //       if (MoodleApiSingleton().isLoggedIn()){
          //         MainController().selectCourse(0);
          //       }
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //             builder: (context) => ViewCourseContents()),
          //       );
          //     }),
          ElevatedButton(
              child: const Text('Open Essay Generation'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EssayGeneration(title: 'Essay Generation')),
                );
              }),
          ElevatedButton(
              child: const Text('Teacher Dashboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                );
              }),
          // ElevatedButton(
          //     child: const Text('Send essay to Moodle'),
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //             builder: (context) => EssayAssignmentSettings(tempRubricXML)),
          //       );
          //     }),
          ElevatedButton(
            child: const Text('Quiz Generator'),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CreateAssessment()));
            },
          ),
          ElevatedButton(
            child: const Text('Edit Questions'),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EditQuestions('')));
            },
          ),
          ElevatedButton(
              child: const Text('View Quizzes'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AssessmentsView()));
              }),
          ElevatedButton(
            child: const Text('Gamification Page'),
            onPressed: () {
              Navigator.pushNamed(context, '/gamification');
            },
          ),
        ]));
  }
}
