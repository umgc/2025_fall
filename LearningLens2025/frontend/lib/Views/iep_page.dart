import 'dart:convert';

import 'package:collection/collection.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import 'package:learninglens_app/Controller/html_converter.dart';
import 'package:learninglens_app/beans/assessment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/override.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class IepPage extends StatefulWidget {
  IepPage();

  @override
  State createState() {
    return _IepPageState();
  }
}

class _IepPageState extends State<IepPage> {
  TextEditingController _dueController = TextEditingController();
  TextEditingController _deadlineController = TextEditingController();
  bool? isChecked1 = false;
  bool? isChecked2 = false;
  String? selectedCourse;
  String? selectedEssay;
  int? userId;
  int? newEndTime;
  String selectedDate = 'Select a Date';
  Future<List<Participant>>? participants;
  Future<List<Assessment>>? assignments;
  Assessment? selectedAssignment;
  double? epochTime;
  double? epochTime2;
  int attempts = 1;
  List<Override>? overrides = [];
  TextEditingController _attemptsController = TextEditingController();
  TextEditingController iepSummaryController = TextEditingController();
  TextEditingController recommendationsController = TextEditingController();
  bool _isAIRecommending = false;

  LlmType? selectedLLM;

  @override
  void initState() {
    super.initState();
    overrides = MoodleLmsService().overrides;
    selectedLLM = LlmType.values
        .firstWhereOrNull((llm) => LocalStorageService.userHasLlmKey(llm));
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: epochTime != null
          ? DateTime.fromMillisecondsSinceEpoch(epochTime!.toInt() * 1000)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dueController.value =
            TextEditingValue(text: "${picked.toLocal()}".split(' ')[0]);
        epochTime = picked.millisecondsSinceEpoch / 1000.round();
      });
    }
  }

  void _selectCutOffDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: epochTime2 != null
          ? DateTime.fromMillisecondsSinceEpoch(epochTime2!.toInt() * 1000)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _deadlineController.value =
            TextEditingValue(text: "${picked.toLocal()}".split(' ')[0]);
        epochTime2 = picked.millisecondsSinceEpoch / 1000.round();
      });
    }
  }

  // void _getAssignmentOverride() async { ***** Not used *****
  //   await MoodleLmsService().getAssignmentOverrides();
  // }

  // Function to show details in a dialog
  void _showDetailsDialog(BuildContext context, Override override) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Details"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Student Name: ${override.fullname}"),
                Text("Course Name: ${override.courseName}"),
                Text(
                    "Assignment: ${override.type}: ${override.assignmentName}"),
                Text(
                    "Extended Due Date: ${formatDate(override.endTime?.toString())}"),
                Text(
                    "Cut Off Date: ${formatDate(override.cutoffTime?.toString())}"),
                Text("Attempts: ${override.attempts?.toString() ?? 'N/A'}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Individual Education Plans',
        onRefresh: () {
          // _loadCourses();
        },
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Individual Education Plan Page',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Enroll Student in New IEP',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    DropdownMenu(
                      label: Text('Course'),
                      // helperText: 'Course',
                      hintText: 'Select Course',
                      width: 350,
                      dropdownMenuEntries:
                          (getAllCourses() ?? []).map((Course course) {
                        return DropdownMenuEntry<String>(
                          value: course.id.toString(),
                          label: course.fullName,
                        );
                      }).toList(),
                      onSelected: (String? selectedValue) {
                        setState(() {
                          selectedCourse = selectedValue;
                        });
                        participants = handleSelection(selectedValue);
                        if (selectedValue != null) {
                          assignments = handleAssessmentSelection(
                              int.parse(selectedValue));
                        } else {
                          print('Selected Value is Null');
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    FutureBuilder<List<Participant>>(
                        future: participants,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Participant>> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            List<DropdownMenuEntry<String>> dropdownEntries =
                                snapshot.data?.map((Participant participant) {
                                      return DropdownMenuEntry<String>(
                                        value: participant.id.toString(),
                                        label: participant.fullname,
                                      );
                                    }).toList() ??
                                    [];
                            return DropdownMenu(
                              enabled: snapshot.hasData,
                              label: Text('Participants'),
                              // helperText: 'Participants',
                              hintText: 'Select Participants',
                              width: 350,
                              dropdownMenuEntries: dropdownEntries,
                              onSelected: (String? selectedParticipant) {
                                setState(() {
                                  if (selectedParticipant != null) {
                                    userId = int.parse(selectedParticipant);
                                  } else {
                                    print('No Participants were selected');
                                  }
                                });
                              },
                            );
                          }
                        }),
                    SizedBox(height: 10),
                    FutureBuilder<List<Assessment>>(
                        future: assignments,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Assessment>> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            List<DropdownMenuEntry<Assessment>>
                                dropdownEntries =
                                snapshot.data?.map((Assessment assignment) {
                                      return DropdownMenuEntry<Assessment>(
                                        value: assignment,
                                        label:
                                            "${assignment.name} (${assignment.type.toUpperCase()})",
                                      );
                                    }).toList() ??
                                    [];
                            return DropdownMenu(
                              enabled: snapshot.hasData,
                              label: Text('Assignment'),
                              // helperText: 'Essays',
                              hintText: 'Select Assignment',
                              width: 350,
                              dropdownMenuEntries: dropdownEntries,
                              onSelected: (Assessment? selectedAssessment) {
                                setState(() {
                                  if (selectedAssessment != null) {
                                    selectedAssignment = selectedAssessment;
                                    if (selectedAssessment.type == "essay") {
                                      _attemptsController.value =
                                          TextEditingValue(
                                              text: attempts.toString());
                                    }
                                  } else {
                                    print('Assessment was Null');
                                  }
                                });
                              },
                            );
                          }
                        }),
                    SizedBox(height: 10),
                    SizedBox(
                        width: 350,
                        child: TextField(
                          enabled: selectedAssignment != null,
                          decoration: InputDecoration(
                              alignLabelWithHint: true,
                              labelText: "IEP Summary",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          controller: iepSummaryController,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          minLines: 10,
                          maxLines: 10,
                        )),
                    SizedBox(height: 10),
                    SizedBox(
                        width: 350,
                        child: Align(
                            alignment: AlignmentGeometry.topRight,
                            child: Text("LLM: "))),
                    SizedBox(
                        width: 350,
                        child: Align(
                            alignment: AlignmentGeometry.topRight,
                            child: DropdownButton<LlmType>(
                                value: selectedLLM,
                                onChanged: (LlmType? newValue) {
                                  setState(() {
                                    selectedLLM = newValue;
                                  });
                                },
                                items: LlmType.values.map((LlmType llm) {
                                  return DropdownMenuItem<LlmType>(
                                    value: llm,
                                    enabled:
                                        LocalStorageService.userHasLlmKey(llm),
                                    child: Text(
                                      llm.displayName,
                                      style: TextStyle(
                                        color:
                                            LocalStorageService.userHasLlmKey(
                                                    llm)
                                                ? Colors.black87
                                                : Colors.grey,
                                      ),
                                    ),
                                  );
                                }).toList()))),
                    SizedBox(
                        width: 350,
                        child: Align(
                            alignment: AlignmentGeometry.topRight,
                            child: ElevatedButton(
                                onPressed: selectedAssignment != null &&
                                        selectedLLM != null
                                    ? () => recommendIEP(selectedAssignment!,
                                        iepSummaryController.value.text)
                                    : null,
                                child: _isAIRecommending
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text('Recommend IEP')))),
                    SizedBox(
                        width: 350,
                        child: TextField(
                          decoration: InputDecoration(
                              alignLabelWithHint: true,
                              enabled: recommendationsController
                                  .value.text.isNotEmpty,
                              labelText: "IEP Recommendations",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          readOnly: true,
                          controller: recommendationsController,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          minLines: 10,
                          maxLines: 10,
                        )),
                    SizedBox(height: 10),
                    SizedBox(
                        width: 350,
                        child: TextField(
                          controller: _attemptsController,
                          onChanged: (value) => setState(() {
                            int? val = int.tryParse(value);
                            if (val != null && (val < 0 || val > 10)) {
                              _attemptsController.value = TextEditingValue(
                                  text: val.clamp(0, 10).toString());
                              return;
                            }
                            attempts = int.tryParse(value)?.clamp(0, 10) ?? 1;
                          }),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          enabled: selectedAssignment?.type == "quiz",
                          decoration: InputDecoration(
                              alignLabelWithHint: true,
                              labelText: "Attempts (0 for Unlimited to 10)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          textAlignVertical: TextAlignVertical.top,
                        )),
                    SizedBox(height: 10),
                    // SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Opacity(
                                opacity: selectedAssignment != null ? 1 : .5,
                                child: Container(
                                  width: 250,
                                  margin: EdgeInsets.only(right: 20),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Text(
                                    _dueController.value.text,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                )),
                            SizedBox(
                                width: 180,
                                child: ElevatedButton(
                                  onPressed: selectedAssignment != null
                                      ? () => _selectDate(context)
                                      : null, // Correct usage of named parameter `onTap`
                                  child: Text(
                                    'Select Due Date',
                                  ),
                                )),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Opacity(
                                opacity: selectedAssignment != null ? 1 : .5,
                                child: Container(
                                  width: 250,
                                  margin: EdgeInsets.only(right: 20),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Text(
                                    _deadlineController.value.text,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                )),
                            SizedBox(
                                width: 180,
                                child: ElevatedButton(
                                  onPressed: selectedAssignment != null
                                      ? () => _selectCutOffDate(context)
                                      : null, // Correct usage of named parameter `onTap`
                                  child: Text(
                                    'Select Deadline Date',
                                  ),
                                )),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Cutoff Date: Last day it can be submitted late',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.only(top: 10, left: 160, bottom: 20),
                      child: ElevatedButton(
                        onPressed: selectedAssignment != null &&
                                epochTime != null &&
                                epochTime2 != null
                            ? () {
                                if (selectedAssignment?.type == 'quiz') {
                                  quizOver(epochTime, selectedAssignment?.id,
                                      userId, attempts);
                                } else if (selectedAssignment?.type ==
                                    'essay') {
                                  essayOver(epochTime, selectedAssignment?.id,
                                      userId, epochTime2);
                                }
                              }
                            : null,
                        child: Text('Submit'),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Existing IEPs',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 20),
                        width: constraints.maxWidth * 0.7,
                        height: 830,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(0.0),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: screenWidth < 1024
                                ? _buildSimplifiedTable(context)
                                : _buildFullTable(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build the simplified table for smaller screens
  DataTable _buildSimplifiedTable(BuildContext context) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(
          Theme.of(context).colorScheme.primary.withOpacity(.3)),
      columns: [
        DataColumn(
            label: Text('Student Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        DataColumn(
            label: Text('Course Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        DataColumn(
            label: Text('Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      ],
      rows: (overrides ?? [])
          .asMap()
          .map((index, override) {
            return MapEntry(
                index,
                DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                    return index % 2 == 0
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(.55)
                        : null; // Use the default value.
                  }),
                  cells: [
                    DataCell(Text(override.fullname)),
                    DataCell(Text(override.courseName)),
                    DataCell(
                      ElevatedButton(
                        onPressed: () => _showDetailsDialog(context, override),
                        child: Text("View"),
                      ),
                    ),
                  ],
                ));
          })
          .values
          .toList(),
    );
  }

  // Build the full table for larger screens
  DataTable _buildFullTable(BuildContext context) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(
          Theme.of(context).colorScheme.primary.withOpacity(.3)),
      columns: [
        DataColumn(
            label: Text('Student Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        DataColumn(
            label: Text('Course Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        DataColumn(
            label: Text('Assignment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        DataColumn(
            label: Text('Due Dates',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        DataColumn(
            label: Text('Attempts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      ],
      rows: (overrides ?? [])
          .asMap()
          .map((index, override) {
            return MapEntry(index, buildDataRow(override, index));
          })
          .values
          .toList(),
    );
  }

  List<Course>? getAllCourses() {
    List<Course>? result;
    result = MoodleLmsService().courses;
    return result;
  }

  Future<List<Participant>>? getAllParticipants(String courseID) async {
    List<Participant>? participants;
    participants = await MoodleLmsService().getCourseParticipants(courseID);
    return participants;
  }

  Future<List<Participant>> handleSelection(String? courseID) async {
    if (courseID != null) {
      List<Participant>? participants = await getAllParticipants(courseID);
      if (participants == null) {
        return [];
      } else {
        return participants;
      }
    } else {
      print('Course ID was Null.');
      return [];
    }
  }

  Future<List<Assessment>> handleAssessmentSelection(int? courseID) async {
    if (courseID != null) {
      List<Assignment> essayList = await MoodleLmsService().getEssays(courseID);
      // Fetch quizzes (if available).
      List<Quiz> quizList = [];
      try {
        quizList = await MoodleLmsService().getQuizzes(courseID);
      } catch (e) {
        print("getQuizzes not available or failed: $e");
      }
      // Combine them into one list
      List<Assessment> assessments = [
        ...essayList.map((a) => Assessment(assessment: a, type: "essay")),
        ...quizList.map((q) => Assessment(assessment: q, type: "quiz"))
      ];
      if (assessments.isNotEmpty) {
        return assessments;
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

  void quizOver(epochTime, quizId, userId, attempts) async {
    await MoodleLmsService().refreshOverrides();
    setState(() {
      overrides = MoodleLmsService().overrides;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Successfully created quiz IEP.")),
    );
  }

  void essayOver(epochTime, essayId, userId, epochTime2) async {
    await MoodleLmsService().addEssayOverride(
        assignid: essayId,
        userId: userId,
        dueDate: epochTime,
        cutoffDate: epochTime2);
    await MoodleLmsService().refreshOverrides();
    setState(() {
      overrides = MoodleLmsService().overrides;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Successfully created essay IEP.")),
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null) {
      return 'N/A';
    }
    DateFormat dateFormat = DateFormat('MMM d yyyy hh:mm a');
    return dateFormat.format(DateTime.parse(dateString));
  }

  DataRow buildDataRow(Override override, int index) {
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        return index % 2 == 0
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(.55)
            : null; // Use the default value.
      }),
      cells: [
        DataCell(Text(override.fullname)),
        DataCell(Text(override.courseName)),
        DataCell(
          Text(
            "${override.assignmentName} (${override.type.toUpperCase()})",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Extended: ${formatDate(override.endTime?.toString())}",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                "Cut off: ${formatDate(override.cutoffTime?.toString())}",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        DataCell(Text(override.attempts?.toString() ?? 'N/A')),
      ],
    );
  }

  Future<void> recommendIEP(Assessment selectedAssignment, String text) async {
    if (selectedLLM == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "No AI credentials found. Please log in to an AI platform.")),
      );
      return;
    }
    setState(() {
      _isAIRecommending = true;
    });
    dynamic aiModel;
    if (selectedLLM == LlmType.CHATGPT) {
      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
    } else if (selectedLLM == LlmType.GROK) {
      aiModel = GrokLLM(LocalStorageService.getGrokKey());
    } else if (selectedLLM == LlmType.DEEPSEEK) {
      aiModel = DeepseekLLM(LocalStorageService.getDeepseekKey());
    } else {
      aiModel = PerplexityLLM(LocalStorageService.getPerplexityKey());
    }
    String prompt =
        'Perform an analysis on a student individualized education plan to customize the provided assignment for a student with accomodations.\n'
        'Student Accomadations: "$text"\n'
        'Assignment Name: "${selectedAssignment.name}"\n'
        'Assignment Summary: "${selectedAssignment.description}"\n'
        'Assignment Type: "${selectedAssignment.type}"\n'
        'Assignment Due Date: "${selectedAssignment.dueDate}"\n'
        'Provide a textual summary. Additionally, suggest a number of attempts to provide the student, from 0 to 10, with 0 representing there is no limit on the number of attempts. '
        'Finally, suggest both a new Due Date and Final Deadline based on the original due date and the necessary accomodations. '
        'Format dates in the format "MM/DD/YYYY". '
        'Return your analysis as a JSON array where the textual summary is an object with key "Summary". '
        'The suggested number of attempts should be returned as an object with key "Attempts". '
        'The suggested Due Date should be returned as an object with key "Due Date". '
        'The suggested Deadline should be returned as an object with key "Deadline". '
        'An example of a properly formatted JSON array is:\n'
        '[\n'
        '{\n'
        '"Summary": "A textual summary of the analysis."\n'
        '},\n'
        '{\n'
        '"Attempts": 5\n'
        '},\n'
        '{\n'
        '"Due Date": "10/31/2025"\n'
        '},\n'
        '{\n'
        '"Deadline": "11/07/2025"\n'
        '}\n'
        ']\n';

    String summary = "";
    DateTime due = DateTime.now();
    DateTime deadline = DateTime.now();
    int attempts = 1;

    try {
      var result = await aiModel.postToLlm(HtmlConverter.convert(prompt));
      String normalizedResult = result.trim();
      // Remove markdown code block wrappers if present.
      if (normalizedResult.startsWith("```json")) {
        normalizedResult = normalizedResult.substring(7);
      }
      if (normalizedResult.endsWith("```")) {
        normalizedResult =
            normalizedResult.substring(0, normalizedResult.length - 3);
      }
      normalizedResult = normalizedResult.trim();
      print(normalizedResult);
      var jsonData = json.decode(normalizedResult);
      List<Map<String, dynamic>>? jsonList;
      if (jsonData is List) {
        jsonList = List<Map<String, dynamic>>.from(jsonData);
        if (jsonList.isNotEmpty && jsonList[0].containsKey("Summary")) {
          summary = jsonList[0]["Summary"].toString();
        }
        if (jsonList.length > 1 &&
            selectedAssignment.type == "quiz" &&
            jsonList[1].containsKey("Attempts")) {
          attempts = jsonList[1]["Attempts"];
        }
        if (jsonList.length > 2 && jsonList[2].containsKey("Due Date")) {
          due = DateFormat.yMd().tryParse(jsonList[2]["Due Date"]) ??
              DateTime.now();
        }
        if (jsonList.length > 3 && jsonList[3].containsKey("Deadline")) {
          deadline = DateFormat.yMd().tryParse(jsonList[3]["Deadline"]) ??
              DateTime.now();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("AI analysis did not return a valid JSON array.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during AI analysis: $e")),
      );
    }
    setState(() {
      _isAIRecommending = false;
      setState(() {
        recommendationsController.value = TextEditingValue(text: summary);
        _attemptsController.value = TextEditingValue(text: attempts.toString());
        _dueController.value =
            TextEditingValue(text: DateFormat.yMd().format(due));
        epochTime = due.millisecondsSinceEpoch / 1000.round();
        _deadlineController.value =
            TextEditingValue(text: DateFormat.yMd().format(deadline));
        epochTime2 = deadline.millisecondsSinceEpoch / 1000.round();
      });
    });
  }
}
