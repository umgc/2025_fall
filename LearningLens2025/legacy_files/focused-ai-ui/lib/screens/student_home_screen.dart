import 'package:flutter/material.dart';
import 'package:focused_ai_ui/screens/error_screen.dart';
import 'package:focused_ai_ui/screens/student_caila_screen.dart';
import 'package:focused_ai_ui/screens/student_code_compiler_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../components/app_navbar.dart';
import '../components/dashboard_button.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Check auth status and redirect if not logged in
        if (!authService.isLoggedIn || authService.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authService.currentUser;
        final displayName = user?.email ?? user?.username ?? 'Student';

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          appBar: AppNavbar(
            title: 'FocusEd AI',
            showUserMenu: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Student Dashboard',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome, $displayName!',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                
                DashboardButton(
                  label: 'CAILA',
                  icon: Icons.psychology,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StudentCailaScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                DashboardButton(
                  label: 'Code Compiler',
                  icon: Icons.code,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StudentCodeCompilerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}