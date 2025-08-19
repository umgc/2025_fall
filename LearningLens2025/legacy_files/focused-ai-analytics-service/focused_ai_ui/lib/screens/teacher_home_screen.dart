import 'package:flutter/material.dart';
import 'package:focused_ai_ui/models/course.dart';
import 'package:focused_ai_ui/models/lms.dart';
import 'package:focused_ai_ui/services/google_classroom_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/moodle_service.dart';
import '../constants/app_strings.dart';
import '../screens/analytics_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  List<Course> _courses = [];
  bool _showCourses = false;
  bool _isLoading = false;

Future<void> _fetchCourses() async {
  if (!mounted) return;
  setState(() {
    _isLoading = true;
  });

  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      throw Exception('No user logged in');
    }

    List<Course> courses;

    switch (user.lmsType) {
      case LMS.moodle:
        courses = await MoodleService().getCourses();
        break;
      case LMS.googleClassroom:
        final googleService = GoogleClassroomService();
        courses = await googleService.getCourses();
        break;
      default:
        throw Exception('Unsupported LMS type: ${user.lmsType}');
    }

    if (mounted) {
      setState(() {
        _courses = courses;
        _showCourses = true;
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading courses: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}



  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherDashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${AppStrings.homeWelcomeMessage} ${user?.username ?? user?.email ?? AppStrings.defaultUserDisplayName}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'You are logged in as a ${user?.role.name.toUpperCase()}!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'LMS: ${user?.lmsType.name.toUpperCase()}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchCourses,
              child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Show My Courses'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherAnalyticsScreen(),
                  ),
                );
              },
              child: const Text('Go to Analytics'),
            ),
            const SizedBox(height: 20),
            if (_showCourses) ...[
              const Text('Your Courses:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return ListTile(
                      title: Text(course.shortName),
                      subtitle: Text('ID: ${course.id}'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}