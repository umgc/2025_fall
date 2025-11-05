import 'package:flutter/material.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/submission.dart';

class ViewReflectionPage extends StatelessWidget {
  final Participant participant;
  final Submission submission;
  final List<List<String>> reflections;

  const ViewReflectionPage(
      {super.key,
      required this.participant,
      required this.submission,
      required this.reflections});

  @override
  Widget build(BuildContext context) {
    // Example reflection data
    return Scaffold(
      appBar: AppBar(
        title: Text('Reflection for ${participant.fullname}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: reflections.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry[0],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: entry[1]),
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
