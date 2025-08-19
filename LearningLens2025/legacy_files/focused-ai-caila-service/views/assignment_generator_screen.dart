import 'package:flutter/material.dart';
import 'package:focused_ai_app/services/ai_service.dart';

class AssignmentGeneratorScreen extends StatefulWidget {
  @override
  _AssignmentGeneratorScreenState createState() => _AssignmentGeneratorScreenState();
}

class _AssignmentGeneratorScreenState extends State<AssignmentGeneratorScreen> {
  final promptController = TextEditingController();
  final followUpController = TextEditingController();
  String aiResponse = '';
  String followUpResponse = '';
  TextSelection? selection;

  void generateRubric() async {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      aiResponse = 'Loading...';
      followUpResponse = '';
    });

    try {
      final result = await AIService.generateRubric(prompt);
      setState(() => aiResponse = result);
    } catch (e) {
      setState(() => aiResponse = 'Error: ${e.toString()}');
    }
  }

  void askFollowUp() async {
    final selectedText = selection != null && selection!.start < selection!.end
        ? aiResponse.substring(selection!.start, selection!.end)
        : '';

    final followUpPrompt = followUpController.text.trim();
    if (selectedText.isEmpty || followUpPrompt.isEmpty) return;

    final fullPrompt = 'Regarding this excerpt: "$selectedText"\n$followUpPrompt';

    setState(() => followUpResponse = 'Loading...');

    try {
      final reply = await AIService.generateRubric(fullPrompt);
      setState(() => followUpResponse = reply);
    } catch (e) {
      setState(() => followUpResponse = 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assignment & Rubric Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: promptController,
                decoration: InputDecoration(
                  labelText: 'Enter assignment topic or goal',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: generateRubric,
                child: Text('Generate Assignment & Rubric'),
              ),
              SizedBox(height: 24),
              Text('AI Response:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              GestureDetector(
                onLongPressStart: (_) => FocusScope.of(context).unfocus(),
                child: SelectableText(
                  aiResponse,
                  showCursor: true,
                  cursorWidth: 2,
                  cursorColor: Colors.blue,
                  toolbarOptions: ToolbarOptions(copy: true),
                  onSelectionChanged: (selection, cause) {
                    setState(() {
                      this.selection = selection;
                    });
                  },
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: followUpController,
                decoration: InputDecoration(
                  labelText: 'Ask a follow-up about selected text...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: askFollowUp,
                child: Text('Ask AI'),
              ),
              if (followUpResponse.isNotEmpty) ...[
                SizedBox(height: 24),
                Text('Follow-up Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                SelectableText(followUpResponse),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
