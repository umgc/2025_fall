import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user_role.dart';
import 'screens/error_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_code_compiler_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/teacher_code_compiler_screen.dart';
import 'screens/teacher_home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the AuthService, which in turn initializes GoogleSignIn
  // Await this call to ensure GoogleSignIn is ready before the UI renders.
  await authService.initializeAuth();

  runApp(
    ChangeNotifierProvider(
      create: (context) =>
          authService, // Use the already initialized singleton instance
      child: const FocusEdAIApp(),
    ),
  );
}

class FocusEdAIApp extends StatelessWidget {
  const FocusEdAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusEd AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const RoleHomeScreen(),
        '/student/home': (context) => const StudentHomeScreen(),
        '/teacher/home': (context) => const TeacherHomeScreen(),
        '/student/code-compiler': (context) => const StudentCodeCompilerScreen(),
        '/teacher/code-compiler': (context) => const TeacherCodeCompilerScreen(),
        // Add other routes here
        '/error': (context) => const ErrorScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show a loading screen while authentication is initializing
        // OR while the user's role is being determined after Google Sign-in.
        if (!authService.isLoggedIn && authService.currentUser == null) {
          // This check handles the initial state before any user is known or if authService.initializeAuth() is still setting up.
          return const LoginScreen();
        }

        // Show a loading indicator specifically for role determination
        if (authService.isLoggedIn && authService.isRoleDetermining) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Determining your role...'),
                ],
              ),
            ),
          );
        }

        // Redirect based on login status and determined role
        if (authService.isLoggedIn &&
            authService.currentUser?.role != UserRole.unknown) {
          return const RoleHomeScreen(); // User is logged in and role determined
        } else if (authService.isLoggedIn &&
            authService.currentUser?.role == UserRole.unknown) {
          // Logged in but role couldn't be determined (e.g., not teacher/student)
          return const ErrorScreen(); // Show error screen for unknown role
        } else {
          return const LoginScreen(); // Not logged in
        }
      },
    );
  }
}

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Ensure user is logged in
        if (!authService.isLoggedIn || authService.currentUser == null) {
          return const LoginScreen(); // Should not happen if AuthWrapper works correctly
        }

        // Route based on user role
        switch (authService.currentUser!.role) {
          case UserRole.teacher:
            return const TeacherHomeScreen();
          case UserRole.student:
            return const StudentHomeScreen();
          default:
            // This case should ideally be caught by AuthWrapper's unknown role check
            return const ErrorScreen();
        }
      },
    );
  }
}