import 'package:flutter/material.dart';
import 'constants/app_routes.dart';
import 'constants/app_strings.dart';
import 'screens/teacher_caila_screen.dart';
import 'screens/error_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CailaApp());
}

class CailaApp extends StatelessWidget {
  const CailaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.lightTheme,
      // Since authentication is handled externally, go directly to teacher screen
      initialRoute: AppRoutes.teacherCaila,
      routes: {
        AppRoutes.teacherCaila: (context) => const TeacherCailaScreen(),
        AppRoutes.error: (context) => const ErrorScreen(),
      },
      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const ErrorScreen(
            errorMessage: 'Page not found',
            errorCode: '404',
          ),
        );
      },
    );
  }
}