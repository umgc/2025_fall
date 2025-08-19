import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'views/auth_selection.dart';

void main() {
  runApp(FocusEdAIApp());
}

class FocusEdAIApp extends StatelessWidget {
  const FocusEdAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusEd AI',
      theme: AppTheme.lightTheme,
      home: AuthSelectionScreen(),
    );
  }
}
