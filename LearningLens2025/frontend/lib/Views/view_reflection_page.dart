import 'package:flutter/material.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/submission.dart';

class ViewReflectionPage extends StatelessWidget {
  final Participant participant;
  final Submission submission;

  const ViewReflectionPage({
    Key? key,
    required this.participant,
    required this.submission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example reflection data
    final Map<String, String> reflectionData = {
      'How did you approach this task before using AI support?':
          'I started by outlining the main points I wanted to cover before consulting AI tools.',
      'In what ways did AI assistance influence your thought process or decisions?':
          'AI helped me rephrase my arguments more clearly and provided feedback on structure.',
      'What challenges did you face while completing this task?':
          'It was difficult balancing my own ideas with AI suggestions without losing authenticity.',
      'How confident are you in your final submission and why?':
          'Fairly confident. I double-checked all content and ensured originality.',
      'What would you do differently next time to improve your work?':
          'Spend more time planning before using AI to ensure I stay in control of my ideas.'
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Reflection for ${participant.fullname}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: reflectionData.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: entry.value),
                    readOnly: true,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
