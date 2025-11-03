import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/services/program_assessment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgramAsessmentResultsView extends StatefulWidget {
  final ProrgramAssessmentJob evaluation;
  final Course course;
  final Assignment assignment;
  final List<Participant> participants;

  ProgramAsessmentResultsView(
      {required this.evaluation,
      required this.course,
      required this.assignment,
      required this.participants});

  @override
  _ProgramAsessmentResultsViewState createState() =>
      _ProgramAsessmentResultsViewState(
          evaluation: evaluation,
          course: course,
          assignment: assignment,
          participants: participants);
}

class _ProgramAsessmentResultsViewState
    extends State<ProgramAsessmentResultsView> {
  final ProrgramAssessmentJob evaluation;
  final Course course;
  final Assignment assignment;
  final List<Participant> participants;
  late List<Map<String, dynamic>> _submissionAttachments;

  final lmsService = LmsFactory.getLmsService();

  _ProgramAsessmentResultsViewState(
      {required this.evaluation,
      required this.course,
      required this.assignment,
      required this.participants});

  @override
  void initState() {
    super.initState();
  }

  Future<void> _publishGrade(
      Participant student, String grade, String feedback) async {
    final moodleLms = LmsFactory.getLmsServiceMoodle();
    bool publishedSuccessfully = await moodleLms.publishGrade(
        assignment.id.toString(), student.id.toString(), feedback, grade);

    SnackBar snackbar;
    if (publishedSuccessfully) {
      snackbar = SnackBar(
        backgroundColor: Colors.green,
        content: Text('Grade for ${student.fullname} published successfully.'),
        duration: Duration(seconds: 8),
      );
    } else {
      snackbar = SnackBar(
        backgroundColor: Colors.red[700],
        content: Text('Unable to publish grade for ${student.fullname}'),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  Future<List<Map<String, dynamic>>> _getAssignmentAttachments() async {
    return await lmsService.getSubmissionAttachments(assignId: assignment.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Evaluation for ${assignment.name}',
        userprofileurl: lmsService.profileImage ?? '',
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAssignmentAttachments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading submissions: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No submissions found.'),
            );
          } else {
            // Assign the result once loaded (optional, if you use it later)
            _submissionAttachments = snapshot.data!;
            return SingleChildScrollView(
              child: _buildMainLayout(),
            );
          }
        },
      ),
    );
  }

  Widget _buildMainLayout() {
    List<dynamic> resultsJson = evaluation.resultsJson;
    final children = resultsJson.mapIndexed(_buildPanel).toList();

    return Column(
      children: children,
    );
  }

  bool _isOutputCorrect(dynamic entry) {
    bool error = entry['error'];
    final expectedOutput = entry['expectedOutput'].toString().trimRight();
    final actualOutput = entry['output'].toString().trimRight();

    return !error && expectedOutput == actualOutput;
  }

  Icon _getIcon(bool isOutputCorrect) {
    if (!isOutputCorrect) {
      return Icon(Icons.error, color: Colors.red);
    }

    return Icon(Icons.check_circle, color: Colors.green);
  }

  Widget _codeOutput(String header, String output) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(header, style: TextStyle(fontWeight: FontWeight.bold)),
        SingleChildScrollView(
          child: Container(
              width: 350,
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: Text(output)),
        )
      ],
    );
  }

  Widget _buildViewSubmissionLink(String submissionUrl) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(submissionUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Could not launch $submissionUrl');
        }
      },
      child: const Text(
        'View Submission',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPanel(int idx, dynamic result) {
    List<dynamic> outputs = result['outputs'];

    final student = participants
        .firstWhere((p) => p.id.toString() == result['studentId'].toString());

    final studentSubmission = _submissionAttachments.firstWhere(
      (entry) => entry['userid'].toString() == student.id.toString(),
    );

    final allOutputCorrectness = outputs.map(_isOutputCorrect);

    List<Widget> children = [];

    // Add link to view the student's submission
    children.addAll([
      _buildViewSubmissionLink(studentSubmission['submissionUrl']),
      SizedBox(height: 4)
    ]);

    final suggestedGrade = allOutputCorrectness.where((o) => o == true).length /
        allOutputCorrectness.length;

    final gradeController = TextEditingController();
    gradeController.text = (suggestedGrade * 100).toInt().toString();
    final feedbackController = TextEditingController();
    // Add UI for submitting suggested grade
    children.add(ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300),
      child: Column(
        spacing: 8,
        children: [
          TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Only allows digits
                FilteringTextInputFormatter.allow(RegExp(
                    r'^[1-9][0-9]*$|^0$')) // Allows only positive nubmers and zero
              ],
              decoration: InputDecoration(
                labelText: 'Suggested Grade',
                border: OutlineInputBorder(),
              )),
          TextField(
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              controller: feedbackController,
              decoration: InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
              )),
          ElevatedButton(
            onPressed: () async {
              if (int.parse(gradeController.text) > 100 && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.red[700],
                  content: Text('Grade cannot be more than 100%'),
                ));
              }

              await _publishGrade(
                  student, gradeController.text, feedbackController.text);
            },
            child: Text("Publish"),
          )
        ],
      ),
    ));

    for (dynamic entry in outputs) {
      final actualOutput = entry['output'].toString();
      final expectedOutput = entry['expectedOutput'].toString();
      final input = entry['input'].toString();
      bool error = entry['error'];
      bool timedout = entry['timedout'];

      final outputIsCorrect = _isOutputCorrect(entry);

      children.addAll([
        Row(
          spacing: 6,
          children: [
            if (timedout)
              Text(
                "Result: TIMED OUT",
                style: TextStyle(fontSize: 18),
              )
            else
              Text(
                "Result: ${outputIsCorrect ? 'PASS' : 'FAIL'}",
                style: TextStyle(fontSize: 18),
              ),
            _getIcon(outputIsCorrect)
          ],
        ),
        if (timedout)
          Text('Program ran for too long')
        else if (error)
          Text('Program encountered error during compilation or runtime')
        else if (outputIsCorrect)
          Text('Actual output matched what was expected')
        else
          Text('Actual output did not match what was expected'),
        Wrap(
          spacing: 12,
          children: [
            if (input.trim().isNotEmpty) _codeOutput('Input', input),
            _codeOutput('Expected Output', expectedOutput),
            _codeOutput('Actual Output', actualOutput)
          ],
        ),
        SizedBox(height: 4)
      ]);
    }

    return ExpansionTile(
      title: Text(
        student.fullname,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading:
          _getIcon(allOutputCorrectness.every((correct) => correct == true)),
      children: [
        Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: children),
        )
      ],
    );
  }
}
