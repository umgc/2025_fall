import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/program_assessment_view.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';

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

  final lmsService = LmsFactory.getLmsService();

  // For expansion tiles
  List<bool> expandedTiles = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Evaluation for ${assignment.name}',
          userprofileurl: lmsService.profileImage ?? '',
        ),
        body: SingleChildScrollView(child: _buildMainLayout()));
  }

  Widget _buildMainLayout() {
    List<dynamic> resultsJson = evaluation.resultsJson;
    final children = resultsJson.mapIndexed(_buildPanel).toList();

    return ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            expandedTiles[index] = isExpanded;
          });
        },
        children: children);
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

  ExpansionPanel _buildPanel(int idx, dynamic result) {
    List<dynamic> outputs = result['outputs'];

    final student = participants
        .firstWhere((p) => p.id.toString() == result['studentId'].toString());
    final allOutputCorrectness = outputs.map(_isOutputCorrect);

    List<Widget> children = [];

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
                labelText: 'Feeback',
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

      final outputIsCorrect = _isOutputCorrect(entry);

      children.addAll([
        Row(
          spacing: 6,
          children: [
            Text(
              "Result: ${outputIsCorrect ? 'PASS' : 'FAIL'}",
              style: TextStyle(fontSize: 18),
            ),
            _getIcon(outputIsCorrect)
          ],
        ),
        if (error)
          Text('Program encountered error during compilation or runtime')
        else if (outputIsCorrect)
          Text('Actual output matched what was expected')
        else
          Text('Actual output did not match what was expected'),
        Wrap(
          spacing: 12,
          children: [
            _codeOutput('Input', input),
            _codeOutput('Expected Output', expectedOutput),
            _codeOutput('Actual Output', actualOutput)
          ],
        ),
        SizedBox(height: 4)
      ]);
    }

    // set state for expansion tile
    expandedTiles.add(false);

    return ExpansionPanel(
        headerBuilder: (context, isExpanded) {
          return ListTile(
              leading: _getIcon(
                  allOutputCorrectness.every((correct) => correct == true)),
              title: Text(
                student.fullname,
                style: TextStyle(fontWeight: FontWeight.bold),
              ));
        },
        body: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: children),
        ),
        isExpanded: expandedTiles[idx]);
  }
}
