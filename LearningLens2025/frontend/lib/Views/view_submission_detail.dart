import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/moodle_rubric.dart';
import 'package:learninglens_app/Views/essays_view.dart';
import 'dart:math';
import 'package:learninglens_app/Views/view_reflection_page.dart';

import 'package:learninglens_app/beans/submission_with_grade.dart';
import 'package:learninglens_app/services/reflection_service.dart';

class SubmissionDetail extends StatefulWidget {
  final Participant participant;
  final SubmissionWithGrade submission;
  final String courseId;

  SubmissionDetail(
      {required this.participant,
      required this.submission,
      required this.courseId});

  @override
  SubmissionDetailState createState() => SubmissionDetailState();
}

class SubmissionDetailState extends State<SubmissionDetail> {
  MoodleRubric? rubric;
  List? scores;
  bool isLoading = true;
  String errorMessage = '';
  Map<int, int> selectedLevels = {}; // Map to store selected levels
  Map<int, String> remarks = {}; // Map to store remarks
  Map<int, TextEditingController> remarkControllers =
      {}; // Controllers for each remark
  double? calculatedGrade;

  // List to store reflections
  @override
  void initState() {
    super.initState();
    fetchRubric();
  }

  Future<void> fetchRubric() async {
    print(
        'Fetching Rubric for assignment ID: ${widget.submission.submission.assignmentId}');
    int? contextId = await LmsFactory.getLmsService().getContextId(
        widget.submission.submission.assignmentId, widget.courseId);
    if (contextId != null) {
      var fetchedRubric = await LmsFactory.getLmsService()
          .getRubric(widget.submission.submission.assignmentId.toString());
      print('Fetched Rubric: $fetchedRubric');
      var submissionScores = await LmsFactory.getLmsService().getRubricGrades(
          widget.submission.submission.assignmentId, widget.participant.id);
      print('Submission Scores: $submissionScores');

      setState(() {
        rubric = fetchedRubric;
        scores = submissionScores;
        // Populate selectedLevels and remarks from submissionScores
        for (var score in scores!) {
          selectedLevels[score['criterionid']] = score['levelid'];
          remarks[score['criterionid']] = score['remark'] ?? '';
          remarkControllers[score['criterionid']] =
              TextEditingController(text: remarks[score['criterionid']]);
        }
        isLoading = false;
        calculatedGrade = computeGradeFromSelections();
      });

      if (fetchedRubric == null) {
        setState(() {
          errorMessage = 'No rubric available for this assignment.';
        });
      }
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to retrieve context ID for the assignment.';
      });
    }
  }

  double? computeGradeFromSelections() {
    if (rubric == null || rubric!.criteria.isEmpty) {
      return null;
    }

    double totalAchieved = 0;
    double totalPossible = 0;

    for (final criterion in rubric!.criteria) {
      if (criterion.levels.isEmpty) continue;

      final maxScore = criterion.levels.last.score.toDouble();
      totalPossible += maxScore;

      final selectedLevelId = selectedLevels[criterion.id];
      if (selectedLevelId == null) continue;

      final matchingLevels =
          criterion.levels.where((level) => level.id == selectedLevelId);
      if (matchingLevels.isEmpty) continue;

      totalAchieved += matchingLevels.first.score.toDouble();
    }

    if (totalPossible == 0) {
      return null;
    }

    return (totalAchieved / totalPossible) * 100;
  }

  Future<List<List<String>>> fetchReflections() async {
    List<List<String>> reflectionsToReturn = [];
    final reflections = await ReflectionService().getReflectionsForAssignment(
        int.parse(widget.courseId), widget.submission.submission.assignmentId);
    for (Reflection r in reflections) {
      final resp = await ReflectionService()
          .getReflectionForSubmission(r.uuid!, widget.participant.id);
      reflectionsToReturn.add([r.question, resp?.response ?? ""]);
    }
    return reflectionsToReturn;
  }

  // Save updated submission scores and remarks as JSON
  void saveSubmissionScores() async {
    List<Map<String, dynamic>> updatedScores = [];
    selectedLevels.forEach((criterionid, levelid) {
      updatedScores.add({
        'criterionid': criterionid,
        'levelid': levelid,
        'remark': remarks[criterionid] ?? ''
      });
    });

    String jsonScores = jsonEncode(updatedScores);
    print('Updated Submission Scores and Remarks: $jsonScores');
    // Handle further actions like saving to a database or API here.
    // SubmissionListState? submissionListState = context.findAncestorStateOfType<SubmissionListState>();
    bool results = await LmsFactory.getLmsService().setRubricGrades(
        widget.submission.submission.assignmentId,
        widget.participant.id,
        jsonScores);
    print('Results: $results');
    if (mounted) {
      if (results) {
        final snackBar = SnackBar(
          content: Text('Grades updated successfully!'),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        await Future.delayed(snackBar.duration);
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EssaysView(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update grades.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Submission Details From here',
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User ID
                    Text(
                      widget.participant.fullname,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),

                    // Status
                    Text(
                      'Status: ${widget.submission.submission.status}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),

                    // Submission Time
                    Text(
                      'Submitted on: ${widget.submission.submission.submissionTime.toLocal()}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),

                    // Submitted Text
                    Text(
                      'Submitted Text:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    widget.submission.submission.onlineText.isNotEmpty
                        ? Text(
                            widget.submission.submission.onlineText
                                .replaceAll(RegExp(r"<[^>]*>"), ""),
                            style: TextStyle(fontSize: 16),
                          )
                        : Text(
                            'No content provided.',
                            style: TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                    SizedBox(height: 16),

                    // Submitted Grade
                    Text(
                      'Submission Grade:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    widget.submission.submission.onlineText.isNotEmpty
                        ? Text(
                            'Grade: ${calculatedGrade != null ? '${calculatedGrade!.round()}%' : widget.submission.grade != null ? widget.submission.grade!.grade.toString() : "Not graded yet"}',
                            style: TextStyle(fontSize: 16),
                          )
                        : Text(
                            'No content provided.',
                            style: TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                    SizedBox(height: 16),

                    // Rubric Section
                    rubric != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rubric:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  fetchReflections()
                                      .then((value) => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewReflectionPage(
                                                      participant:
                                                          widget.participant,
                                                      submission: widget
                                                          .submission
                                                          .submission,
                                                      reflections: value),
                                            ),
                                          ));
                                },
                                icon: Icon(Icons.note_alt_outlined),
                                label: Text('View Reflection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              SizedBox(height: 8),

                              // Rubric table (replace rubricTable with new table)
                              buildInteractiveRubricTable(),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: saveSubmissionScores,
                                child: Text('Save'),
                              ),
                            ],
                          )
                        : errorMessage.isNotEmpty
                            ? Text(
                                errorMessage,
                                style: TextStyle(
                                    fontSize: 50,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.red),
                              )
                            : Text(
                                'No rubric available.',
                                style: TextStyle(
                                    fontSize: 16, fontStyle: FontStyle.italic),
                              ),
                  ],
                ),
              ),
            ),
    );
  }

// Interactive rubric table with dynamic width expansion
  Widget buildInteractiveRubricTable() {
    if (rubric == null) {
      return Container(); // No rubric, return an empty container
    }

    List<TableRow> tableRows = [];

    // First row: Header row with scores and remarks
    tableRows.add(
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        children: [
          TableCell(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Criteria',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Weight',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ...rubric!.criteria.first.levels.map((level) {
            return TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    '${level.score / (rubric!.criteria.first.levels.last.score / 100)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            );
          }),
          TableCell(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Remarks',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );

    // Add rows for each criterion
    for (var criterion in rubric!.criteria) {
      tableRows.add(
        TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  criterion.description,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
            TableCell(
              // Weight
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '${criterion.levels.last.score / 100}%',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ...criterion.levels.map((level) {
              bool isSelected = selectedLevels[criterion.id] == level.id;
              return TableCell(
                verticalAlignment: TableCellVerticalAlignment.fill,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedLevels[criterion.id] = level.id;
                      calculatedGrade = computeGradeFromSelections();
                    });
                  },
                  child: Container(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        : Colors.transparent,
                    padding: EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        level.description,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
              );
            }),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: remarkControllers[criterion.id],
                  onChanged: (text) {
                    remarks[criterion.id] = text;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter remark',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 4,
                  maxLines: 6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double minWidth = 800;
        double tableWidth = max(minWidth, constraints.maxWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.vertical, // Enable vertical scrolling
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enable horizontal scrolling
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableWidth),
              child: Table(
                border: TableBorder.all(
                    color: Colors.black,
                    width: 1.0), // Outer border for the table
                columnWidths: {
                  0: FlexColumnWidth(.5), // Criteria column
                  1: FlexColumnWidth(.5),
                  for (int i = 2;
                      i < 2 + rubric!.criteria.first.levels.length;
                      i++)
                    i: FlexColumnWidth(1), // Score columns
                  2 + rubric!.criteria.first.levels.length:
                      FlexColumnWidth(1.8), // Remarks column
                },
                children: tableRows,
              ),
            ),
          ),
        );
      },
    );
  }
}
