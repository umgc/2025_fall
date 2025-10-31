import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/lms/constants/learning_lens.constants.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/beans/moodle_rubric.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/beans/submission_with_grade.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'view_submission_detail.dart';
import '../Api/llm/perplexity_api.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:learninglens_app/services/prompt_builder_service.dart';
import 'package:learninglens_app/Api/llm/local_llm_service.dart'; // local llm
import 'package:flutter/foundation.dart';

class SubmissionList extends StatefulWidget {
  final int assignmentId;
  final String courseId;

  SubmissionList({
    super.key,
    required this.assignmentId,
    required this.courseId,
  });

  @override
  SubmissionListState createState() => SubmissionListState();
}

class SubmissionListState extends State<SubmissionList> {
  LmsInterface api = LmsFactory.getLmsService();
  Map<int, bool> isLoadingMap = {};
  Map<int, LlmType> llmSelectionMap = {};
  Map<int, String> toneSelectionMap = {};
  Map<int, String> voiceSelectionMap = {};
  Map<int, String> detailLevelSelectionMap = {};
  Map<int, String> gradeLevelSelectionMap = {};
  bool _localLlmAvail = !kIsWeb;

  late Future<List<SubmissionWithGrade>> futureSubmissionsWithGrades =
      api.getSubmissionsWithGrades(widget.assignmentId);
  late Future<List<Participant>> futureParticipants =
      api.getCourseParticipants(widget.courseId);
  late Future<bool> futureHasRubric;

  final perplexityApiKey = LocalStorageService.getPerplexityKey();
  final openApiKey = LocalStorageService.getOpenAIKey();
  final grokApiKey = LocalStorageService.getGrokKey();
  final deepseekApiKey = LocalStorageService.getDeepseekKey();

  LlmType? selectedLLM;

  String filterOption = 'All Students';
  String fullNameFilter = '';

  String getApiKey(LlmType selectedLLM) {
    switch (selectedLLM) {
      case LlmType.CHATGPT:
        return openApiKey;
      case LlmType.GROK:
        return grokApiKey;
      case LlmType.DEEPSEEK:
        return deepseekApiKey;
      default:
        return perplexityApiKey;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      futureSubmissionsWithGrades =
          api.getSubmissionsWithGrades(widget.assignmentId);
      futureParticipants = api.getCourseParticipants(widget.courseId);
      futureHasRubric = fetchEssayHasRubric(widget.assignmentId);
    });
  }

  // Helper method to fetch if essay has rubric
  Future<bool> fetchEssayHasRubric(int essayId) async {
    MoodleRubric? rubric =
        await LmsFactory.getLmsService().getRubric(essayId.toString());
    return rubric != null;
  }

  LlmType getDefaultLlm() {
    final openApiKey = LocalStorageService.getOpenAIKey();
    final grokApiKey = LocalStorageService.getGrokKey();
    final deepseekApiKey = LocalStorageService.getDeepseekKey();
    final perplexityApiKey = LocalStorageService.getPerplexityKey();
    final localLLMPath = LocalStorageService.getLocalLLMPath();

    if (openApiKey.isNotEmpty) {
      return LlmType.CHATGPT;
    } else if (grokApiKey.isNotEmpty) {
      return LlmType.GROK;
    } else if (deepseekApiKey.isNotEmpty) {
      return LlmType.DEEPSEEK;
    } else if (perplexityApiKey.isNotEmpty) {
      return LlmType.PERPLEXITY;
    } else if (localLLMPath != "") {
      return LlmType.LOCAL;
    } else {
      // fallback if none are available
      return LlmType.CHATGPT;
    }
  }

  void _handleLLMChanged(int participantId, LlmType? newValue) {
    setState(() {
      if (newValue != null) {
        llmSelectionMap[participantId] = newValue;
      }
    });
  }

  void _handleFilterChanged(String? newValue) {
    setState(() {
      if (newValue != null) {
        filterOption = newValue;
      }
    });
  }

  void _handleFullNameFilterChanged(String newValue) {
    setState(() {
      fullNameFilter = newValue;
    });
  }

  void _handleToneChanged(int participantId, String? newValue) {
    setState(() {
      if (newValue != null) {
        toneSelectionMap[participantId] = newValue;
      }
    });
  }

  void _handleVoiceChanged(int participantId, String? newValue) {
    setState(() {
      if (newValue != null) {
        voiceSelectionMap[participantId] = newValue;
      }
    });
  }

  void _handleDetailChanged(int participantId, String? newValue) {
    setState(() {
      if (newValue != null) {
        detailLevelSelectionMap[participantId] = newValue;
      }
    });
  }

  void _handleGradeLevelChanged(int participantId, String? newValue) {
    setState(() {
      if (newValue != null) {
        gradeLevelSelectionMap[participantId] = newValue;
      }
    });
  }

  // Widget to display the "under development" error with icon and back button
  Widget _buildUnderDevelopmentError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .construction, // Construction icon to indicate "under development"
            size: 60,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Submissions/Grading feature is currently not available for Google Classroom. Please reach out to the developer for more information.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Navigate back to the previous screen
            },
            child: Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: futureHasRubric,
          builder: (bCon, bSnap) {
            if (bSnap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (bSnap.hasError) {
              return Center(child: Text('Error: ${bSnap.error}'));
            } else if (bSnap.data != true) {
              return Center(
                  child: Text(
                      'This assignment was created outside of EduLense and does not have an EduLense rubric.'));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filterOption,
                          decoration:
                              InputDecoration(labelText: 'Submission Status'),
                          onChanged: _handleFilterChanged,
                          items: <String>[
                            'All Students',
                            'With Submission',
                            'Without Submission'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Filter by Name',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: _handleFullNameFilterChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                // Help trigger below the Submission Status filter row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text(
                          'Information on AI Grading using Tone / Voice / Detail Level'),
                      onPressed: () => showAiGraderDetails(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      FutureBuilder<List<Participant>>(
                        future: futureParticipants,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Participant>>
                                participantSnapshot) {
                          if (participantSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (participantSnapshot.hasError) {
                            if (participantSnapshot.error
                                is UnimplementedError) {
                              return _buildUnderDevelopmentError(context);
                            }
                            return Center(
                                child: Text(
                                    'Error: ${participantSnapshot.error}'));
                          } else if (!participantSnapshot.hasData ||
                              participantSnapshot.data!.isEmpty) {
                            return Center(
                                child: Text('No participants found.'));
                          } else {
                            return FutureBuilder<List<SubmissionWithGrade>>(
                              future: futureSubmissionsWithGrades,
                              builder: (BuildContext context,
                                  AsyncSnapshot<List<SubmissionWithGrade>>
                                      submissionSnapshot) {
                                if (submissionSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (submissionSnapshot.hasError) {
                                  if (submissionSnapshot.error
                                      is UnimplementedError) {
                                    return _buildUnderDevelopmentError(context);
                                  }
                                  return Center(
                                      child: Text(
                                          'Error: ${submissionSnapshot.error}'));
                                } else {
                                  List<Participant> participants =
                                      participantSnapshot.data!;
                                  List<SubmissionWithGrade>
                                      submissionsWithGrades =
                                      submissionSnapshot.data ?? [];

                                  participants.sort((a, b) {
                                    int lastNameComparison =
                                        a.lastname.compareTo(b.lastname);
                                    if (lastNameComparison != 0) {
                                      return lastNameComparison;
                                    } else {
                                      return a.firstname.compareTo(b.firstname);
                                    }
                                  });

                                  if (filterOption == 'With Submission') {
                                    participants =
                                        participants.where((participant) {
                                      return submissionsWithGrades.any((sub) =>
                                          sub.submission.userid ==
                                          participant.id);
                                    }).toList();
                                  } else if (filterOption ==
                                      'Without Submission') {
                                    participants =
                                        participants.where((participant) {
                                      return !submissionsWithGrades.any((sub) =>
                                          sub.submission.userid ==
                                          participant.id);
                                    }).toList();
                                  }

                                  if (fullNameFilter.isNotEmpty) {
                                    participants =
                                        participants.where((participant) {
                                      return participant.fullname
                                          .toLowerCase()
                                          .contains(
                                              fullNameFilter.toLowerCase());
                                    }).toList();
                                  }

                                  return SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      alignment: WrapAlignment.center,
                                      children: participants.map((participant) {
                                        SubmissionWithGrade?
                                            submissionWithGrade =
                                            submissionsWithGrades
                                                .where((sub) =>
                                                    sub.submission.userid ==
                                                    participant.id)
                                                .firstOrNull;

                                        bool isLoading =
                                            isLoadingMap[participant.id] ??
                                                false;
                                        LlmType selectedLLM =
                                            llmSelectionMap[participant.id] ??
                                                getDefaultLlm();
                                        return SizedBox(
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width <
                                                  450
                                              ? double.infinity
                                              : 450,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                                width: 2.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            margin: EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 16),
                                            child: Card(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                              elevation: 0,
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSecondary,
                                                  child: Text(
                                                    participant.fullname
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSecondaryContainer,
                                                    ),
                                                  ),
                                                ),
                                                title:
                                                    Text(participant.fullname),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (submissionWithGrade !=
                                                        null)
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              'Grade Status: ${submissionWithGrade.submission.gradingStatus}'),
                                                          Text(
                                                              'Status: ${submissionWithGrade.submission.status}'),
                                                          Text(
                                                              'Submitted on: ${DateFormat('MMM d, yyyy h:mm a').format(submissionWithGrade.submission.submissionTime.toLocal())}'),
                                                          Text(
                                                              'Grade: ${submissionWithGrade.grade != null ? submissionWithGrade.grade!.grade.toString() : "Not graded yet"}'),
                                                          SizedBox(height: 6),
                                                          // DropdownButton<LlmType>(
                                                          DropdownButtonFormField<
                                                              LlmType>(
                                                            value: selectedLLM,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText: 'AI',
                                                            ),
                                                            onChanged: (newValue) =>
                                                                _handleLLMChanged(
                                                                    participant
                                                                        .id,
                                                                    newValue),
                                                            items: LlmType
                                                                .values
                                                                .map((LlmType
                                                                    llm) {
                                                              return DropdownMenuItem<
                                                                  LlmType>(
                                                                value: llm,
                                                                enabled: (llm ==
                                                                            LlmType
                                                                                .LOCAL &&
                                                                        LocalStorageService.getLocalLLMPath() !=
                                                                            "" &&
                                                                        _localLlmAvail) ||
                                                                    LocalStorageService
                                                                        .userHasLlmKey(
                                                                            llm),
                                                                child: Text(
                                                                  llm.displayName,
                                                                  style:
                                                                      TextStyle(
                                                                    color: (llm == LlmType.LOCAL && LocalStorageService.getLocalLLMPath() != "" && _localLlmAvail) ||
                                                                            LocalStorageService.userHasLlmKey(
                                                                                llm)
                                                                        ? Colors
                                                                            .black87
                                                                        : Colors
                                                                            .grey,
                                                                  ),
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                          if (selectedLLM ==
                                                              LlmType
                                                                  .LOCAL) ...[
                                                            const SizedBox(
                                                                height: 6),
                                                            const Text(
                                                              "Running a Large Language Model (LLM) requires substantial hardware resources. The recommended model for is 7B or higher reasoning (Qwen) models. Using smaller models may produce inaccurate or misleading responses.\nFor best results, we recommend using the external LLM.\nPlease use the local LLM responsibly and independently verify any critical information.",
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                          ],
                                                          SizedBox(height: 4),
                                                          // Tone Dropdown
                                                          DropdownButtonFormField<
                                                              String>(
                                                            value: toneSelectionMap[
                                                                    participant
                                                                        .id] ??
                                                                'Formal',
                                                            decoration:
                                                                InputDecoration(
                                                                    labelText:
                                                                        'Tone'),
                                                            onChanged: (newValue) =>
                                                                _handleToneChanged(
                                                                    participant
                                                                        .id,
                                                                    newValue),
                                                            items: [
                                                              'Formal',
                                                              'Straightforward',
                                                              'Casual'
                                                            ]
                                                                .map((tone) =>
                                                                    DropdownMenuItem(
                                                                      value:
                                                                          tone,
                                                                      child: Text(
                                                                          tone),
                                                                    ))
                                                                .toList(),
                                                          ),
                                                          SizedBox(height: 4),

                                                          // Voice Dropdown
                                                          DropdownButtonFormField<
                                                              String>(
                                                            value: voiceSelectionMap[
                                                                    participant
                                                                        .id] ??
                                                                'Supportive',
                                                            decoration:
                                                                InputDecoration(
                                                                    labelText:
                                                                        'Voice'),
                                                            onChanged: (newValue) =>
                                                                _handleVoiceChanged(
                                                                    participant
                                                                        .id,
                                                                    newValue),
                                                            items: [
                                                              'Supportive',
                                                              'Neutral',
                                                              'Constructive'
                                                            ]
                                                                .map((voice) =>
                                                                    DropdownMenuItem(
                                                                      value:
                                                                          voice,
                                                                      child: Text(
                                                                          voice),
                                                                    ))
                                                                .toList(),
                                                          ),
                                                          SizedBox(height: 4),

                                                          // Level of Detail Dropdown
                                                          DropdownButtonFormField<
                                                              String>(
                                                            value: detailLevelSelectionMap[
                                                                    participant
                                                                        .id] ??
                                                                'Neutral',
                                                            decoration:
                                                                InputDecoration(
                                                                    labelText:
                                                                        'Level of Detail'),
                                                            onChanged: (newValue) =>
                                                                _handleDetailChanged(
                                                                    participant
                                                                        .id,
                                                                    newValue),
                                                            items: [
                                                              'Basic',
                                                              'Neutral',
                                                              'Detailed'
                                                            ]
                                                                .map((detail) =>
                                                                    DropdownMenuItem(
                                                                      value:
                                                                          detail,
                                                                      child: Text(
                                                                          detail),
                                                                    ))
                                                                .toList(),
                                                          ),
                                                          SizedBox(height: 4),

                                                          // Grade Level Dropdown
                                                          DropdownButtonFormField<
                                                              String>(
                                                            value: gradeLevelSelectionMap[
                                                                    participant
                                                                        .id] ??
                                                                LearningLensConstants
                                                                    .gradeLevels
                                                                    .last,
                                                            decoration:
                                                                InputDecoration(
                                                                    labelText:
                                                                        'Grade Level'),
                                                            onChanged: (newValue) =>
                                                                _handleGradeLevelChanged(
                                                                    participant
                                                                        .id,
                                                                    newValue),
                                                            items: LearningLensConstants
                                                                .gradeLevels
                                                                .map((detail) =>
                                                                    DropdownMenuItem(
                                                                      value:
                                                                          detail,
                                                                      child: Text(
                                                                          detail),
                                                                    ))
                                                                .toList(),
                                                          ),
                                                          SizedBox(height: 4),
                                                        ],
                                                      )
                                                    else
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(height: 52),
                                                          Text('No Submission',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .error)),
                                                          SizedBox(height: 84),
                                                        ],
                                                      ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        if (submissionWithGrade !=
                                                            null)
                                                          isLoading
                                                              ? Stack(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  children: [
                                                                    const CircularProgressIndicator(),
                                                                    if (selectedLLM ==
                                                                        LlmType
                                                                            .LOCAL)
                                                                      TextButton(
                                                                        onPressed:
                                                                            () async {
                                                                          final decision =
                                                                              await LocalLLMService().showCancelConfirmationDialog();
                                                                          if (decision) {
                                                                            LocalLLMService().cancel();
                                                                          }
                                                                        },
                                                                        style: TextButton
                                                                            .styleFrom(
                                                                          foregroundColor:
                                                                              Colors.redAccent,
                                                                        ),
                                                                        child:
                                                                            const Text(
                                                                          'Cancel Generation',
                                                                          style: TextStyle(
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.w500),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                )
                                                              : ElevatedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    if (await LocalLLMService()
                                                                        .checkIfLoadedLocalLLMRecommended()) {
                                                                      try {
                                                                        setState(
                                                                            () {
                                                                          isLoadingMap[participant.id] =
                                                                              true;
                                                                        });

                                                                        var submissionText = submissionWithGrade
                                                                            .submission
                                                                            .onlineText;
                                                                        int? contextId = await LmsFactory.getLmsService().getContextId(
                                                                            widget.assignmentId,
                                                                            widget.courseId);

                                                                        String?
                                                                            fetchedRubric;
                                                                        if (contextId !=
                                                                            null) {
                                                                          MoodleRubric?
                                                                              moodleRubric =
                                                                              await LmsFactory.getLmsService().getRubric(widget.assignmentId.toString());
                                                                          if (moodleRubric ==
                                                                              null) {
                                                                            print('Failed to fetch rubric.');
                                                                            return;
                                                                          }
                                                                          fetchedRubric =
                                                                              jsonEncode(moodleRubric.toJson());
                                                                        }

                                                                        String queryPrompt = buildLlmPrompt(
                                                                            submissionText:
                                                                                submissionText,
                                                                            fetchedRubric:
                                                                                fetchedRubric,
                                                                            tone: toneSelectionMap[participant.id] ??
                                                                                'Formal',
                                                                            voice: voiceSelectionMap[participant.id] ??
                                                                                'Supportive',
                                                                            detailLevel: detailLevelSelectionMap[participant.id] ??
                                                                                'Neutral',
                                                                            gradeLevel:
                                                                                gradeLevelSelectionMap[participant.id] ?? LearningLensConstants.gradeLevels.last);

                                                                        String
                                                                            apiKey =
                                                                            getApiKey(selectedLLM);
                                                                        dynamic
                                                                            llmInstance;
                                                                        if (selectedLLM ==
                                                                            LlmType
                                                                                .CHATGPT) {
                                                                          llmInstance =
                                                                              OpenAiLLM(apiKey);
                                                                        } else if (selectedLLM ==
                                                                            LlmType
                                                                                .GROK) {
                                                                          llmInstance =
                                                                              GrokLLM(apiKey);
                                                                        } else if (selectedLLM ==
                                                                            LlmType
                                                                                .DEEPSEEK) {
                                                                          llmInstance =
                                                                              DeepseekLLM(apiKey);
                                                                        } else if (selectedLLM ==
                                                                            LlmType.LOCAL) {
                                                                          llmInstance =
                                                                              LocalLLMService();
                                                                        } else {
                                                                          llmInstance =
                                                                              PerplexityLLM(apiKey);
                                                                        }
                                                                        dynamic
                                                                            gradedResponse =
                                                                            await llmInstance.postToLlm(queryPrompt);
                                                                        gradedResponse = gradedResponse
                                                                            .replaceAll('```json',
                                                                                '')
                                                                            .replaceAll('```',
                                                                                '')
                                                                            .trim();
                                                                        var results = await LmsFactory.getLmsService().setRubricGrades(
                                                                            widget.assignmentId,
                                                                            participant.id,
                                                                            gradedResponse);
                                                                        _fetchData();
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                SubmissionDetail(
                                                                              participant: participant,
                                                                              submission: submissionWithGrade,
                                                                              courseId: widget.courseId,
                                                                            ),
                                                                          ),
                                                                        );
                                                                        print(
                                                                            'Results: $results');
                                                                      } catch (e) {
                                                                        print(
                                                                            'An error occurred: $e');
                                                                      } finally {
                                                                        setState(
                                                                            () {
                                                                          isLoadingMap[participant.id] =
                                                                              false;
                                                                        });
                                                                      }
                                                                    }
                                                                  },
                                                                  child: Text(
                                                                      'Grade'),
                                                                ),
                                                        SizedBox(width: 8),
                                                        if (submissionWithGrade !=
                                                            null)
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          SubmissionDetail(
                                                                    participant:
                                                                        participant,
                                                                    submission:
                                                                        submissionWithGrade,
                                                                    courseId: widget
                                                                        .courseId,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Text(
                                                                'View Details'),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                isThreeLine: true,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                }
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }

  void showAiGraderDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
            'Details on AI Grader Settings - Tone, Voice, Level of Detail'),
        content: const Text(
          'You can choose the different LLM models from the dropdown if available.\n\n'
          'Tone controls the mood or delivery style of the generated feedback. This controls how to LLM sounds:\n'
          '• Formal – Academic, precise language, no contractions.\n'
          '• Straightforward – Clear, concise, direct phrasing.\n'
          '• Casual – Conversational and friendly.\n\n'
          'Voice sets the personality and can change the feel of who is speaking:\n'
          '• Supportive – Encouraging and positive; focuses on growth.\n'
          '• Neutral – Objective and factual; avoids emotional or motivational phrasing.\n'
          '• Constructive – Balanced and specific; highlights both strengths and areas for improvement.\n\n'
          'Level of Detail sets how much feedback is generated:\n'
          '• Basic – 1 paragraph per criterion\n'
          '• Neutral – 2 paragraphs per criterion\n'
          '• Detailed – 3 paragraphs per criterion\n\n'
          'Grade level adjusts the wording and language appropriate for different student grade levels:\n'
          'Note: These settings ONLY affect the written feedback.\n'
          'Grading is determined strictly by the rubric.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
