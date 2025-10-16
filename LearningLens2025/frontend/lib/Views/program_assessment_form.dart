import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/program_assessment_service.dart';

class ProgramAssessmentForm extends StatefulWidget {
  final List<Course> courses;
  // Callback that is called when a new program evaluation is created successfully
  final Future<void> Function(
          Course course, Assignment assignment, String expectedOutput)?
      onEvaluationStarted;
  const ProgramAssessmentForm(
      {super.key, required this.courses, required this.onEvaluationStarted});

  @override
  _ProgramAssessmentFormState createState() =>
      _ProgramAssessmentFormState(courses, onEvaluationStarted);
}

class _ProgramAssessmentFormState extends State<ProgramAssessmentForm> {
  final lmsService = LmsFactory.getLmsService();
  final codeEvalUrl = LocalStorageService.getCodeEvalUrl();
  final _assessmentService = ProgramAssessmentService();

  List<Course> courses = [];

  /// Program arguments
  final TextEditingController argsController = TextEditingController();
  final TextEditingController outputController = TextEditingController();
  final Future<void> Function(
          Course course, Assignment assignment, String expectedOutput)?
      onEvaluationStarted;
  final List<String> languages = [ 'C', 'C++', 'Java', 'Python' ];

  Course? selectedCourse;
  Assignment? selectedAssignment;
  String? selectedLanguage;

  /// File containing the expected input
  PlatformFile? inputFile;

  /// File containing the expected output
  PlatformFile? outputFile;

  bool _isLoading = false;

  _ProgramAssessmentFormState(this.courses, this.onEvaluationStarted);

  // Helper to check if form is valid
  bool get isFormValid => selectedCourse != null && selectedAssignment != null;

  @override
  void initState() {
    // Listen to changes in the text field to update button state
    outputController.addListener(() {
      setState(() {}); // triggers rebuild to refresh button enabled/disabled
    });
    selectedLanguage = languages[0];
    super.initState();
  }

  @override
  void dispose() {
    outputController.dispose();
    super.dispose();
  }

  // Helper to show status messages
  void _showSnackBar(SnackBar snackBar) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  String _getFileContents(PlatformFile file) =>
      utf8.decode(file.bytes!.toList());

  Future<bool> isFilesValid() async{
    if (outputFile == null || outputFile?.bytes == null) return false;
    // Assumes file is utf-8 encoded
    if (inputFile != null) {
      final outputFileContent = _getFileContents(outputFile!);
      final inputFileContent = _getFileContents(inputFile!);
      final outputFileLineCount = outputFileContent.split('\n').length;
      final inputFileLineCount = inputFileContent.split('\n').length;
      if (outputFileLineCount != inputFileLineCount) {
        await _showLineCountMismatchDialog(context, inputFileLineCount, outputFileLineCount);
        return false;
      }
    }

    return true;
  }

  Future<void> _showLineCountMismatchDialog(BuildContext context, int inputFileLineCount, int outputFileLineCount) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Line Count Mismatch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'The number of lines in the expected input file ($inputFileLineCount) does not match '
            'the number of lines in the expected output file ($outputFileLineCount).',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startEvaluation(Course course, Assignment assignment,
      String input, String expectedOutput, String language) async {
    if (!(await isFilesValid())) return;

    final response = await _assessmentService.startEvaluation(
      course: course, 
      assignment: assignment, 
      input: input, 
      expectedOutput: expectedOutput, 
      language: language
    );
    
    if (response.statusCode != 200) {
      _showSnackBar(SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(
              'Unable to evaluate coding assignment: "${response.body}"')));

      debugPrint(response.body);
      return;
    }

    _showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      content:
          Text('Evaluation started successfully. Check back in a few minutes.'),
      duration: Duration(seconds: 8),
    ));

    if (onEvaluationStarted != null) {
      await onEvaluationStarted!(course, assignment, expectedOutput);
    }

    // Navigate back to previous page
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: CustomAppBar(
          title: 'New Assessment Job',
          userprofileurl: lmsService.profileImage ?? '',
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildForm(context)));
        }));
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Program Assessment", style: TextStyle(fontSize: 24)),
            // Courses Dropdown
            DropdownButtonFormField<Course>(
              decoration: InputDecoration(
                labelText: "Courses",
                border: OutlineInputBorder(),
              ),
              value: selectedCourse,
              items: courses.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Text(course.fullName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCourse = value;
                  selectedAssignment = null;
                });
              },
            ),
            // Assignments Dropdown
            DropdownButtonFormField<Assignment>(
              decoration: InputDecoration(
                labelText: "Assignments",
                border: OutlineInputBorder(),
              ),
              value: selectedAssignment,
              items: selectedCourse == null
                  ? []
                  : courses
                      .firstWhere((c) => c == selectedCourse)
                      .essays!
                      .map((assignment) {
                      return DropdownMenuItem(
                        value: assignment,
                        child: Text(assignment.name),
                      );
                    }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAssignment = value;
                });
              },
            ),
            // Language selection dropdown
            DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Language",
                  border: OutlineInputBorder(),
                ),
                value: languages[0],
                items: languages
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLanguage = value;
                  });
                }),
            Text(
              'Note that students MUST submit a .zip file with the entry point '
              'of the program being in a file named entry.(c, cpp, java, py).',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(spacing: 8, children: [
              // Expected input file upload
              ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Input File'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();
                    final file = result?.files.single;
                    if (file == null) return;

                    setState(() {
                      inputFile = file;
                    });
                  }),
              if (inputFile != null) Text(inputFile!.name),
            ]),
            Row(spacing: 8, children: [
              // Expected output file upload
              ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Expected Output File'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();
                    final file = result?.files.single;
                    if (file == null) return;

                    setState(() {
                      outputFile = file;
                    });
                  }),
              if (outputFile != null) Text(outputFile!.name)
            ]),
            SizedBox(height: 20),
            if (_isLoading)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16), // bigger size
                  textStyle: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold), // bigger text
                  backgroundColor: Colors.deepPurpleAccent, // primary color
                  foregroundColor: Colors.white, // text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded corners
                  ),
                  elevation: 5, // shadow for prominence
                ),
                onPressed: null,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16), // bigger size
                  textStyle: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold), // bigger text
                  backgroundColor: Colors.deepPurpleAccent, // primary color
                  foregroundColor: Colors.white, // text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded corners
                  ),
                  elevation: 5, // shadow for prominence
                ),
                onPressed: !isFormValid
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          await _startEvaluation(
                              selectedCourse!,
                              selectedAssignment!,
                              inputFile != null
                                  ? _getFileContents(inputFile!)
                                  : '',
                              _getFileContents(outputFile!),
                              selectedLanguage!);
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                child: Text("Create"),
              )
          ],
        ),
      ),
    );
  }
}
