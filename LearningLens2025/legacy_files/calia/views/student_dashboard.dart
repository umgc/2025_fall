import 'package:flutter/material.dart';
import 'ai_chat_screen.dart';
class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatScreen())),
          child: Text('Start AI Assistant'),
        ),
      ),
    );
  }
}
