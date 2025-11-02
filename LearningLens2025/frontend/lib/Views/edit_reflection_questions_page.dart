import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';

class EditReflectionQuestionsPage extends StatefulWidget {
  final String assignmentId;
  final String courseId;
  final List<String> initialQuestions;

  const EditReflectionQuestionsPage({
    Key? key,
    required this.assignmentId,
    required this.courseId,
    required this.initialQuestions,
  }) : super(key: key);

  @override
  State<EditReflectionQuestionsPage> createState() =>
      _EditReflectionQuestionsPageState();
}

class _EditReflectionQuestionsPageState
    extends State<EditReflectionQuestionsPage> {
  List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialQuestions
        .map((q) => TextEditingController(text: q))
        .toList();
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
  }

  void addQuestionField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void removeQuestionField(int index) {
    setState(() {
      _controllers.removeAt(index);
    });
  }

  Future<void> saveQuestions() async {
    if (!_formKey.currentState!.validate()) return;

    List<String> questions =
        _controllers.map((controller) => controller.text.trim()).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Questions saved successfully!')),
    );
    Navigator.pop(context, questions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Reflection Questions',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reflection Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              ..._controllers.asMap().entries.map(
                (entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Question ${index + 1}',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a question';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        if (_controllers.length > 1)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeQuestionField(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: addQuestionField,
                    icon: Icon(Icons.add),
                    label: Text('Add Question'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: saveQuestions,
                    child: Text('Save Questions'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
