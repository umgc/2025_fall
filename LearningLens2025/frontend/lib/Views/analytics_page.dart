import 'dart:io' show File, Platform; // For non-web file I/O
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For file saving on non-web platforms
import 'package:flutter_to_pdf/flutter_to_pdf.dart';
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/database/ai_logging_singleton.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/lms/constants/learning_lens.constants.dart';
import 'package:learninglens_app/Controller/html_converter.dart';
import 'package:learninglens_app/beans/ai_log.dart';
import 'package:learninglens_app/beans/assessment.dart';
import 'package:learninglens_app/beans/question_stat_type.dart';
import 'package:learninglens_app/beans/submission.dart';
import 'package:learninglens_app/stub/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // PDF package
import 'package:excel/excel.dart'; // Excel package
import 'package:path/path.dart' as path;

// Import the LMS services using prefixes so that type checks work correctly.
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart'
    as moodle;
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';

import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';

// Import the APIs for the Learning Lens Model (LLM).
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

import 'package:learninglens_app/Api/llm/local_llm_service.dart'; // local llm
import 'package:flutter/foundation.dart';

/// Enum to represent export formats.
enum ExportFormat { pdf, excel }

enum AnalysisDataType { bar, list, line }

/// AnalyticsPage displays the Analytics Dashboard where teachers can:
///  - View overall analytics data (live data fetched from the LMS)
///  - Generate a detailed report for essay assignments only (quizzes are omitted)
///  - Export the generated report as a valid PDF or Excel file
///    (using proper PDF/Excel libraries)
///  - View tables in fixed-height containers with visible scrollbars.
///
/// When a student is clicked in the breakdown table, a detail panel appears
/// on the right showing that student's assignment details (non-editable).
///
/// A simple wrapper to hold either an essay assignment or a quiz.
/// The `type` property distinguishes between the two.

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final lmsService = LmsFactory.getLmsService();
  final exp = ExportDelegate();
  // Live analytics data fetched from the LMS.
  Map<String, dynamic>? analyticsData;
  bool isLoading = false;
  String errorMsg = '';
  bool canceled = false;

  // Live data for dropdowns.
  List<Course> _coursesData = [];
  List<Assessment> _assessmentsData = [];
  List<Participant> _participantsData = [];

  // Selections from dropdowns.
  Course? _selectedCourse;
  String? _selectedSubject;
  Assessment? _selectedAssessment;

  // Student breakdown report built from live LMS participant data.
  List<Map<String, dynamic>> _studentBreakdown = [];
  Map<String, dynamic>? _selectedStudent;
  // Name, Type, Grade
  List<Map<String, String>> _studentCourseData = [];
  String _selectedGradeLevel = LearningLensConstants.gradeLevels.last;

  // For quiz assessments, question breakdown data.
  List<QuestionStatsType> _questionBreakdown = [];

  // Scroll controllers for tables.
  late ScrollController _verticalStudentController;
  late ScrollController _horizontalStudentController;
  late ScrollController _verticalQuestionController;
  late ScrollController _horizontalQuestionController;

  // AI Analysis data.
  List<Map<String, dynamic>> _aiAnalysisSuccess = [];
  List<Map<String, dynamic>> _aiAnalysisFail = [];
  List<Map<String, dynamic>> _aiAnalysisAi = [];
  List<Map<String, dynamic>> _aiAnalysisCourse = [];
  List<Map<String, dynamic>> _aiAnalysisAssignment = [];
  List<Map<String, dynamic>> _aiAnalysisStudent = [];
  bool _isAnalyzingSuccess = false;
  bool _isAnalyzingFail = false;
  bool _isAnalyzingAi = false;
  bool _isAnalyzingCourse = false;
  bool _isAnalyzingAssignment = false;
  bool _isAnalyzingStudents = false;
  bool _lastAnalysisQuiz = false;
  String _lastAnalysisCourse = "";
  String _lastAnalysisAssignment = "";
  String _lastAnalysisStudent = "";
  String _lastAnalysisCompletionTime = "";

  List<int> _expandedPanels = [0, 1, 2, 3, 4, 5];

  List<List<String>> _exportFrameIds = [];

  LlmType? selectedLLM;
  bool _localLlmAvail = !kIsWeb;

  // count the number of instances running so we can cancel them all.

  List<List<Color>> contrastColors = Colors.primaries.map((e) {
    HSLColor hsl = HSLColor.fromColor(e);
    double contrast =
        ThemeData.estimateBrightnessForColor(e) == Brightness.light ? -.3 : .3;
    return [
      e,
      hsl.withLightness((hsl.lightness + contrast).clamp(0, 1)).toColor()
    ];
  }).toList();

  @override
  void initState() {
    super.initState();
    _verticalStudentController = ScrollController();
    _horizontalStudentController = ScrollController();
    _verticalQuestionController = ScrollController();
    _horizontalQuestionController = ScrollController();
    _fetchAnalyticsData();
    selectedLLM = LlmType.values
        .firstWhereOrNull((llm) => LocalStorageService.userHasLlmKey(llm));
  }

  @override
  void dispose() {
    _verticalStudentController.dispose();
    _horizontalStudentController.dispose();
    _verticalQuestionController.dispose();
    _horizontalQuestionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // _fetchAnalyticsData:
  // Fetches live data from the LMS (courses, initial quizzes/essays).
  // ---------------------------------------------------------------------------
  Future<void> _fetchAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });
    try {
      _coursesData = await lmsService.getUserCourses();
      int totalCourses = _coursesData.length;
      if (_coursesData.isNotEmpty) {
        _selectedCourse = _coursesData.first;
        _selectedSubject = _selectedCourse!.subject ?? "General";
        // Fetch essays.
        List<Assignment> essayList =
            await lmsService.getEssays(_selectedCourse!.id);
        // Fetch quizzes (if available).
        List<Quiz> quizList = [];
        try {
          quizList = await lmsService.getQuizzes(_selectedCourse!.id,
              topicId: _selectedCourse!.quizTopicId);
        } catch (e) {
          print("getQuizzes not available or failed: $e");
        }
        // Combine them into one list
        _assessmentsData = [
          ...essayList.map((a) => Assessment(assessment: a, type: "essay")),
          ...quizList.map((q) => Assessment(assessment: q, type: "quiz"))
        ];
        if (_assessmentsData.isNotEmpty) {
          _selectedAssessment = _assessmentsData.first;
        }
      }
      setState(() {
        analyticsData = {
          'source': lmsService is moodle.MoodleLmsService
              ? 'Moodle'
              : 'Google Classroom',
          'totalCourses': totalCourses,
          'studentPerformance': 'Live Performance Data',
          'iepProgress': 'Live IEP Data',
          'courseEngagement': 'Live Engagement Metrics',
        };
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Failed to load analytics data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // _generateReport:
  // Builds the student breakdown for the currently selected assessment only
  // (i.e., one quiz or essay).
  // ---------------------------------------------------------------------------
  Future<void> _generateReport() async {
    if (_selectedCourse == null) return;
    setState(() {
      isLoading = true;
      errorMsg = '';
      _studentBreakdown.clear();
      _questionBreakdown.clear();
      _selectedStudent = null;
      _studentCourseData.clear();
    });

    try {
      if (isQuiz()) {
        // Grab participants for this quiz.
        int quizId = _selectedAssessment!.assessment.id;
        _participantsData = await lmsService.getQuizGradesForParticipants(
            _selectedCourse!.id.toString(), quizId);
        // Filter out non-students, if needed.
        _participantsData = _participantsData
            .where((i) => i.roles.contains('student'))
            .toList();
      } else if (isEssay()) {
        // Grab participants for this essay.
        int assignmentId = _selectedAssessment!.assessment.id;
        _participantsData = await lmsService.getEssayGradesForParticipants(
            _selectedCourse!.id.toString(), assignmentId);
      } else {
        throw Exception("Unsupported Assessment Type");
      }

      // Build the table shown in the "Student Breakdown" section.
      getStudentBreakdown(_participantsData);

      // If it's a quiz, also fetch the question breakdown.
      await _fetchQuestionBreakdown();
      await _fetchAllAssessmentsForStudents();
    } catch (e) {
      setState(() {
        errorMsg = 'Failed to generate report: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // getStudentBreakdown:
  // Builds `_studentBreakdown` from the given participant list for the currently
  // selected assessment only.
  // ---------------------------------------------------------------------------
  void getStudentBreakdown(List<Participant> participantsData) {
    _studentBreakdown = participantsData.map((participant) {
      double? grade = participant.avgGrade;
      String displayGrade = (grade != null) ? '${grade.toInt()}%' : '0%';
      return {
        'id': participant.id,
        'studentName': participant.fullname,
        'avgGrade': displayGrade,
        'classRank': 0,
      };
    }).toList();

    // Sort descending by numeric grade.
    _studentBreakdown.sort((a, b) {
      int aGrade = int.tryParse(a['avgGrade'].replaceAll('%', '')) ?? 0;
      int bGrade = int.tryParse(b['avgGrade'].replaceAll('%', '')) ?? 0;
      return bGrade.compareTo(aGrade);
    });

    // Assign a 1-based rank.
    for (int i = 0; i < _studentBreakdown.length; i++) {
      _studentBreakdown[i]['classRank'] = i + 1;
    }
  }

  // ---------------------------------------------------------------------------
  // _saveReport:
  // Exports the generated report as PDF or Excel (only for the single selected assessment).
  // ---------------------------------------------------------------------------
  Future<void> _saveReport() async {
    final format = await _chooseExportFormat();
    if (format == null) return;
    String extension = (format == ExportFormat.pdf) ? 'pdf' : 'xlsx';
    String defaultName = 'my_report.$extension';

    if (kIsWeb) {
      // Build bytes.
      List<int> bytes = (format == ExportFormat.pdf)
          ? await _exportReportAsPdf()
          : await _exportReportAsExcel();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = defaultName;
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Report exported as $extension via browser download.')),
      );
    } else if (Platform.isAndroid || Platform.isIOS) {
      try {
        List<int> bytes = await _exportReportAsExcel();
        var dir = await getApplicationDocumentsDirectory();
        File(path.join('${dir.path}/$defaultName'))
          ..createSync(recursive: true)
          ..writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to Excel at:\n$dir')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e')),
        );
      }
    } else {
      final savePath = await _pickFileLocation(defaultName);
      if (savePath == null) return;
      try {
        List<int> bytes = (format == ExportFormat.pdf)
            ? await _exportReportAsPdf()
            : await _exportReportAsExcel();
        final file = File(savePath);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved as $extension at:\n$savePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // _chooseExportFormat:
  // Prompts the user to select whether to export the report as PDF or Excel.
  // ---------------------------------------------------------------------------
  Future<ExportFormat?> _chooseExportFormat() async {
    return showDialog<ExportFormat>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Export Format'),
          content: const Text(
              'Would you like to export the report as PDF or Excel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ExportFormat.pdf),
              child: const Text('PDF'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ExportFormat.excel),
              child: const Text('Excel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // _exportReportAsPdf:
  // Uses the pdf package to generate a PDF document containing the student breakdown
  // and, if applicable, the question breakdown.
  // ---------------------------------------------------------------------------
  Future<List<int>> _exportReportAsPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          // Dynamic export for student breakdown.
          if (_studentBreakdown.isNotEmpty) {
            // Dynamically capture all keys as headers.
            final studentHeaders = _studentBreakdown.first.keys.toList();
            // Map each student to a list of string values.
            final studentData = _studentBreakdown
                .map((student) =>
                    student.values.map((value) => value.toString()).toList())
                .toList();
            widgets.add(pw.Header(
                level: 0, child: pw.Text("Student Breakdown Report")));
            widgets.add(
              pw.Table.fromTextArray(
                headers: studentHeaders,
                data: studentData,
              ),
            );
          }

          // Export question breakdown (only for quizzes).
          if (isQuiz() && _questionBreakdown.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 20));
            widgets
                .add(pw.Header(level: 0, child: pw.Text("Question Breakdown")));
            widgets.add(
              pw.Table.fromTextArray(
                headers: [
                  'Q#',
                  'Question Type',
                  'Question',
                  '% Answered Correct',
                  '# Correct',
                  '# Incorrect',
                  '# Total Attempts'
                ],
                data: _questionBreakdown
                    .map((q) => [
                          q.id.toString(),
                          q.questionType,
                          q.questionText,
                          "${computePercentCorrect(q).toStringAsFixed(2)}%",
                          q.numCorrect.toString(),
                          q.numIncorrect.toString(),
                          q.totalAttempts.toString(),
                        ])
                    .toList(),
              ),
            );
          }
          return widgets;
        },
      ),
    );
    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // _exportReportAsExcel:
  // Uses the excel package to generate an Excel file containing the student breakdown
  // and, if applicable, the question breakdown.
  // ---------------------------------------------------------------------------
  Future<List<int>> _exportReportAsExcel() async {
    var excel = Excel.createExcel();
    excel.rename('Sheet1', 'Student Breakdown');

    // Dynamic export for student breakdown.
    Sheet studentSheet = excel['Student Breakdown'];
    if (_studentBreakdown.isNotEmpty) {
      // Get headers dynamically from the first map.
      var studentHeaders = _studentBreakdown.first.keys
          .toList()
          .map((e) => TextCellValue(e))
          .toList();
      studentSheet.appendRow(studentHeaders);
      // Append each student row by mapping the values to strings.
      for (var student in _studentBreakdown) {
        studentSheet.appendRow(student.values
            .map((value) => TextCellValue(value.toString()))
            .toList());
      }
    }

    // Export question breakdown if it's a quiz.
    if (isQuiz() && _questionBreakdown.isNotEmpty) {
      Sheet questionSheet = excel['Question Breakdown'];
      questionSheet.appendRow([
        TextCellValue('Q#'),
        TextCellValue('Question Type'),
        TextCellValue('Question'),
        TextCellValue('% Answered Correct'),
        TextCellValue('# Correct'),
        TextCellValue('# Incorrect'),
        TextCellValue('# Total Attempts')
      ]);
      for (var q in _questionBreakdown) {
        questionSheet.appendRow([
          TextCellValue(q.id.toString()),
          TextCellValue(q.questionType),
          TextCellValue(q.questionText),
          TextCellValue("${computePercentCorrect(q).toStringAsFixed(2)}%"),
          TextCellValue(q.numCorrect.toString()),
          TextCellValue(q.numIncorrect.toString()),
          TextCellValue(q.totalAttempts.toString()),
        ]);
      }
    }

    return excel.encode()!;
  }

  // ---------------------------------------------------------------------------
  // _pickFileLocation:
  // For non-web platforms, uses FilePicker to let the user choose a save location.
  // On web, file saving is handled via an AnchorElement.
  // ---------------------------------------------------------------------------
  Future<String?> _pickFileLocation(String defaultName) async {
    if (kIsWeb) return null;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: defaultName,
    );
    return result;
  }

  // ---------------------------------------------------------------------------
  // Export AI Analysis Functions
  // ---------------------------------------------------------------------------
  Future<void> _exportAIAnalysis() async {
    final format = await _chooseExportFormat();
    if (format == null) return;
    String extension = (format == ExportFormat.pdf) ? 'pdf' : 'xlsx';
    String defaultName =
        'ai_analysis_report_${_lastAnalysisCourse}_${_lastAnalysisAssignment}_${_lastAnalysisStudent}_$_lastAnalysisCompletionTime.$extension';

    if (kIsWeb) {
      List<int> bytes = (format == ExportFormat.pdf)
          ? await _exportAIAnalysisAsPdf()
          : await _exportAIAnalysisAsExcel();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = defaultName;
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'AI Analysis exported as $extension via browser download.')),
      );
    } else if (Platform.isAndroid || Platform.isIOS) {
      try {
        List<int> bytes = (format == ExportFormat.pdf)
            ? await _exportAIAnalysisAsPdf()
            : await _exportAIAnalysisAsExcel();
        var dir = await getApplicationDocumentsDirectory();
        File(path.join('${dir.path}/$defaultName'))
          ..createSync(recursive: true)
          ..writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to Excel at:\n$dir')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e')),
        );
      }
    } else {
      final savePath = await _pickFileLocation(defaultName);
      if (savePath == null) return;
      try {
        List<int> bytes = (format == ExportFormat.pdf)
            ? await _exportAIAnalysisAsPdf()
            : await _exportAIAnalysisAsExcel();
        final file = File(savePath);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('AI Analysis saved as $extension at:\n$savePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save AI Analysis: $e')),
        );
      }
    }
  }

  Future<List<int>> _exportAIAnalysisAsPdf() async {
    pw.Document pdf = pw.Document();
    for (List<String> idPair in _exportFrameIds) {
      pw.Widget header = await exp.exportToPdfWidget(idPair[0]);
      pw.Widget body = await exp.exportToPdfWidget(idPair[1]);
      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) {
            List<pw.Widget> widgets = [header, pw.SizedBox(height: 20), body];
            return widgets;
          }));
    }
    return pdf.save();
  }

  Future<List<int>> _exportAIAnalysisAsExcel() async {
    var excel = Excel.createExcel();
    _buildExcelChild(
        "Areas of Understanding",
        _aiAnalysisSuccess.isEmpty ||
                !_aiAnalysisSuccess[0].containsKey("Summary")
            ? null
            : _aiAnalysisSuccess[0]["Summary"],
        _aiAnalysisSuccess.length < 2 ||
                !_aiAnalysisSuccess[1].containsKey("Data")
            ? null
            : _aiAnalysisSuccess[1]["Data"],
        "Top Areas of Understanding",
        ["Topic", "Percentage"],
        excel,
        true);
    _buildExcelChild(
        "Areas of Misunderstanding",
        _aiAnalysisFail.isEmpty || !_aiAnalysisFail[0].containsKey("Summary")
            ? null
            : _aiAnalysisFail[0]["Summary"],
        _aiAnalysisFail.length < 2 || !_aiAnalysisFail[1].containsKey("Data")
            ? null
            : _aiAnalysisFail[1]["Data"],
        "Top Areas of Misunderstanding",
        ["Topic", "Percentage"],
        excel);
    _buildExcelChild(
        "Course Improvements",
        _aiAnalysisCourse.isEmpty ||
                !_aiAnalysisCourse[0].containsKey("Summary")
            ? null
            : _aiAnalysisCourse[0]["Summary"],
        _aiAnalysisCourse.length < 2 ||
                !_aiAnalysisCourse[1].containsKey("Data")
            ? null
            : _aiAnalysisCourse[1]["Data"],
        "Suggested Assignments",
        ["Name", "Description"],
        excel);
    _buildExcelChild(
        "Assignment Improvements",
        _aiAnalysisAssignment.isEmpty ||
                !_aiAnalysisAssignment[0].containsKey("Summary")
            ? null
            : _aiAnalysisAssignment[0]["Summary"],
        _aiAnalysisAssignment.length < 2 ||
                !_aiAnalysisAssignment[1].containsKey("Data")
            ? null
            : _aiAnalysisAssignment[1]["Data"],
        "Suggested References",
        [
          "URL",
          "Description",
        ],
        excel);
    _buildExcelChild(
        "Student Trends",
        _aiAnalysisStudent.isEmpty ||
                !_aiAnalysisStudent[0].containsKey("Summary")
            ? null
            : _aiAnalysisStudent[0]["Summary"],
        _selectedStudent == null
            ? _studentCourseData
            : _studentCourseData
                .where((element) =>
                    int.parse(element['Student ID']!) ==
                    _selectedStudent!["id"])
                .toList(),
        "Student Grades Over Time",
        [
          "Student ID",
          "Student Name",
          "Assessment",
          "Type",
          "Due Date",
          "Grade"
        ],
        excel);
    if (!_lastAnalysisQuiz) {
      _buildExcelChild(
          "AI Use Areas",
          _aiAnalysisAi.isEmpty || !_aiAnalysisAi[0].containsKey("Summary")
              ? null
              : _aiAnalysisAi[0]["Summary"],
          _aiAnalysisAi.length < 2 || !_aiAnalysisAi[1].containsKey("Data")
              ? null
              : _aiAnalysisAi[1]["Data"],
          "Top AI Use Cases",
          ["Area", "Percentage"],
          excel);
    }
    return excel.encode()!;
  }

  void _buildExcelChild(String sheetName, String? summary, List<dynamic>? data,
      String chartName, List<String> dataKeys, Excel file,
      [bool renameFirstSheet = false]) {
    if (renameFirstSheet) {
      file.rename('Sheet1', sheetName);
    }
    Sheet sheet = file[sheetName];
    sheet.appendRow([TextCellValue('Summary'), TextCellValue('Chart Name')]);
    sheet.appendRow([
      TextCellValue(summary ?? "No AI Analysis Summary Found"),
      TextCellValue(chartName)
    ]);
    sheet.appendRow(
        [TextCellValue(''), ...dataKeys.map((e) => TextCellValue(e))]);
    if (data != null && data.isNotEmpty) {
      data = data.where((e) {
        for (String k in dataKeys) {
          if (!e.containsKey(k)) {
            return false;
          }
        }
        return true;
      }).toList();
      if (dataKeys.contains("URL")) {
        data = data
            .where((element) =>
                element.containsKey("ValidURL") && element["ValidURL"])
            .toList();
      }
    }
    if (data == null || data.isEmpty) {
      sheet.appendRow(
          [TextCellValue(''), TextCellValue("No AI Analysis Data found.")]);
    } else {
      for (dynamic m in data) {
        List<TextCellValue> row = [TextCellValue('')];
        for (String k in dataKeys) {
          if (k == "Due Date") {
            row.add(TextCellValue(DateFormat.yMd().format(
                DateTime.fromMillisecondsSinceEpoch(
                    int.parse(m[k].toString())))));
          } else {
            row.add(TextCellValue(m[k].toString()));
          }
        }
        sheet.appendRow(row);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // _buildReportForm:
  // Displays dropdowns for selecting course, subject, and assessment,
  // along with Generate and Export buttons.
  // ---------------------------------------------------------------------------
  Widget _buildReportForm() {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generate New Report',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          // Course dropdown.
          DropdownButtonFormField<Course>(
            value: _selectedCourse,
            decoration: const InputDecoration(labelText: 'Course'),
            items: _coursesData.map((course) {
              return DropdownMenuItem<Course>(
                value: course,
                child: Text(course.fullName.isNotEmpty
                    ? course.fullName
                    : course.shortName),
              );
            }).toList(),
            onChanged: (val) async {
              setState(() {
                _selectedCourse = val;
                _selectedSubject = val?.subject ?? "General";
                // Clear dependent tables when course changes.
                _studentBreakdown.clear();
                _questionBreakdown.clear();
                _aiAnalysisSuccess.clear();
                _aiAnalysisFail.clear();
                _aiAnalysisAi.clear();
                _aiAnalysisAssignment.clear();
                _aiAnalysisCourse.clear();
                _selectedStudent = null;
                _studentCourseData.clear();
              });
              if (_selectedCourse != null) {
                // Fetch essays and quizzes, then combine them.
                List<Assignment> essays =
                    await lmsService.getEssays(_selectedCourse!.id);
                List<Quiz> quizzes = [];
                try {
                  quizzes = await (lmsService as dynamic)
                      .getQuizzes(_selectedCourse!.id);
                } catch (e) {
                  print("getQuizzes not available or failed: $e");
                }
                _assessmentsData = [
                  ...essays
                      .map((a) => Assessment(assessment: a, type: "essay")),
                  ...quizzes.map((q) => Assessment(assessment: q, type: "quiz"))
                ];
                if (_assessmentsData.isNotEmpty) {
                  _selectedAssessment = _assessmentsData.first;
                }
                setState(() {});
              }
            },
          ),
          // Subject dropdown.
          if (_selectedCourse != null)
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                DropdownMenuItem(
                  value: _selectedSubject,
                  child: Text(_selectedSubject ?? "General"),
                )
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSubject = val;
                  // Optionally clear dependent tables if needed.
                  _studentBreakdown.clear();
                  _questionBreakdown.clear();
                  _aiAnalysisSuccess.clear();
                  _aiAnalysisFail.clear();
                  _aiAnalysisAi.clear();
                  _aiAnalysisAssignment.clear();
                  _aiAnalysisCourse.clear();
                  _selectedStudent = null;
                  _studentCourseData.clear();
                });
              },
            ),
          // Assessment dropdown.
          DropdownButtonFormField<Assessment>(
            value: _selectedAssessment,
            decoration: const InputDecoration(labelText: 'Assessment'),
            items: _assessmentsData.map((assessment) {
              return DropdownMenuItem<Assessment>(
                value: assessment,
                child: Text(
                    '${assessment.name} (${assessment.type.toUpperCase()})'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedAssessment = val;
                // Clear question breakdown, student breakdown and AI analysis when assessment changes.
                _questionBreakdown.clear();
                _studentBreakdown.clear();
                _aiAnalysisSuccess.clear();
                _aiAnalysisFail.clear();
                _aiAnalysisAi.clear();
                _aiAnalysisAssignment.clear();
                _aiAnalysisCourse.clear();
                _selectedStudent = null;
                _studentCourseData.clear();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Spacer(),
            Text("Grade Level: "),
            DropdownButton<String>(
              value: _selectedGradeLevel,
              items: LearningLensConstants.gradeLevels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGradeLevel =
                      newValue ?? LearningLensConstants.gradeLevels.last;
                });
              },
            )
          ]),
          Row(children: [
            ElevatedButton(
              onPressed: (_selectedCourse == null ||
                      _selectedSubject == null ||
                      _selectedAssessment == null)
                  ? null
                  : _generateReport,
              child: const Text('Generate'),
            ),
            Spacer(),
            Text("LLM: "),
            DropdownButton<LlmType>(
                value: selectedLLM,
                onChanged: (LlmType? newValue) {
                  setState(() {
                    selectedLLM = newValue;
                  });
                },
                items: LlmType.values.map((LlmType llm) {
                  return DropdownMenuItem<LlmType>(
                    value: llm,
                    enabled: (llm == LlmType.LOCAL &&
                            LocalStorageService.getLocalLLMPath() != "" &&
                            _localLlmAvail) ||
                        LocalStorageService.userHasLlmKey(llm),
                    child: Text(
                      llm.displayName,
                      style: TextStyle(
                        color: (llm == LlmType.LOCAL &&
                                    LocalStorageService.getLocalLLMPath() !=
                                        "" &&
                                    _localLlmAvail) ||
                                LocalStorageService.userHasLlmKey(llm)
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  );
                }).toList()),
          ]),
          if (selectedLLM == LlmType.LOCAL) ...[
            const SizedBox(height: 6),
            const Text(
              "Running a Large Language Model (LLM) locally typically requires substantial hardware resources.\nWe recommend using 7B or higher thinking (Qwen) models to generate the analysis. \nFor best results, we strongly recommend using the external LLM for this task.\nPlease use the local LLM responsibly and independently verify any critical information.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
          Row(
            children: [
              ElevatedButton(
                onPressed: _studentBreakdown.isNotEmpty ? _saveReport : null,
                child: const Text('Export'),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: _studentBreakdown.isNotEmpty &&
                        selectedLLM != null &&
                        _selectedCourse != null &&
                        _selectedAssessment != null
                    ? () => _analyzeReport(
                        _selectedCourse!,
                        _selectedAssessment!,
                        _participantsData,
                        _selectedStudent?["id"],
                        isEssay() ? null : _questionBreakdown.toList(),
                        _studentCourseData,
                        _selectedGradeLevel)
                    : null,
                child: _isAnalyzingSuccess ||
                        _isAnalyzingFail ||
                        _isAnalyzingAssignment ||
                        _isAnalyzingAi ||
                        _isAnalyzingStudents
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_selectedStudent == null
                        ? 'AI Analyze Course'
                        : 'AI Analyze Student'),
              ),
            ],
          ),
          if (selectedLLM == LlmType.LOCAL &&
              (_isAnalyzingSuccess ||
                  _isAnalyzingFail ||
                  _isAnalyzingAssignment ||
                  _isAnalyzingAi ||
                  _isAnalyzingStudents))
            TextButton(
              onPressed: () async {
                bool decision = await LocalLLMService()
                    .showCancelConfirmationDialog(count: 10);
                if (decision) {
                  setState(() {
                    canceled = true;
                    isLoading = false;
                    _isAnalyzingSuccess = false;
                    _isAnalyzingFail = false;
                    _isAnalyzingAssignment = false;
                    _isAnalyzingAi = false;
                    _isAnalyzingStudents = false;
                  });
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Cancel Generation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildQuestionBreakdown:
  // Displays the question breakdown table for quiz assessments.
  // This is shown only when a quiz is selected.
  // Here, each DataCell wraps its Text widget with an IntrinsicWidth widget
  // to ensure that the column width adjusts to the largest text.
  // Additionally, the entire table is wrapped in a FittedBox to scale down
  // the table if the user has a smaller screen or they change their resolution.
  // ---------------------------------------------------------------------------
  Widget _buildQuestionBreakdown() {
    if (_questionBreakdown.isEmpty) {
      return const Center(child: Text('No question breakdown available.'));
    }
    return SizedBox(
      height: 200,
      child: Scrollbar(
        thumbVisibility: true,
        controller: _verticalQuestionController,
        child: SingleChildScrollView(
          controller: _verticalQuestionController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _horizontalQuestionController,
            notificationPredicate: (notification) => notification.depth == 2,
            child: SingleChildScrollView(
              controller: _horizontalQuestionController,
              scrollDirection: Axis.horizontal,
              // This is where the magic happens with the FittedBox and DataTable.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: DataTable(
                  columnSpacing: 12.0,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Question Type')),
                    DataColumn(label: Text('Question')),
                    DataColumn(label: Text('% Answered Correct')),
                    DataColumn(label: Text('# Correct')),
                    DataColumn(label: Text('# Incorrect')),
                    DataColumn(label: Text('# Total Attempts')),
                  ],
                  rows: _questionBreakdown.map((q) {
                    return DataRow(
                      cells: [
                        DataCell(IntrinsicWidth(child: Text(q.id.toString()))),
                        DataCell(IntrinsicWidth(child: Text(q.questionType))),
                        DataCell(IntrinsicWidth(child: Text(q.questionText))),
                        DataCell(IntrinsicWidth(
                            child: Text(
                                "${computePercentCorrect(q).toStringAsFixed(2)}%"))),
                        DataCell(IntrinsicWidth(
                            child: Text(q.numCorrect.toString()))),
                        DataCell(IntrinsicWidth(
                            child: Text(q.numIncorrect.toString()))),
                        DataCell(IntrinsicWidth(
                            child: Text(q.totalAttempts.toString()))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildStudentTable:
  // Returns ONLY the table of student data. The detail panel is separate.
  // ---------------------------------------------------------------------------
  Widget _buildStudentTable() {
    if (_studentBreakdown.isEmpty && !isLoading) {
      return const Center(child: Text('No student breakdown available.'));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
        height: 300,
        child: Scrollbar(
            thumbVisibility: true,
            controller: _verticalStudentController,
            child: SingleChildScrollView(
              controller: _verticalStudentController,
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 12.0,
                columns: const [
                  DataColumn(label: Expanded(child: Text('Student Name'))),
                  DataColumn(label: Text('Average Grade')),
                  DataColumn(label: Text('Class Rank')),
                ],
                rows: _studentBreakdown.map((student) {
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.25);
                      }
                      return _studentBreakdown.indexOf(student) % 2 == 0
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(.55)
                          : null; // Use the default value.
                    }),
                    selected: student == _selectedStudent,
                    onSelectChanged: (val) {
                      setState(() {
                        _selectedStudent = student;
                      });
                    },
                    cells: [
                      DataCell(
                        Text(
                          student['studentName'].toString(),
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      DataCell(Text(student['avgGrade'].toString())),
                      DataCell(Text(student['classRank'].toString())),
                    ],
                  );
                }).toList(),
              ),
            )));
  }

  // ---------------------------------------------------------------------------
  // _buildStudentDetail:
  // Displays the selected student's detail info in the bottom-right quadrant.
  // ---------------------------------------------------------------------------
  Widget _buildStudentDetail() {
    if (_selectedStudent == null) {
      return const Center(
        child: Text(
          'Select a student to see detailed grades.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    int studentId = _selectedStudent!['id'];
    if (_studentCourseData.isEmpty) {
      return Text('No data available for student $studentId.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details for ${_selectedStudent!['studentName']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._studentCourseData
            .where(
          (element) => int.parse(element['Student ID']!) == studentId,
        )
            .map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${item['Assessment']} (${item['Type']})",
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(
                          int.parse(item['Due Date']!))
                      .toLocal()),
                  style: const TextStyle(fontSize: 16),
                ),
                SizedBox(
                    width: 50,
                    child: Text(
                      item['Grade']!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // _fetchAllAssessmentsForStudent:
  // Helper function to fetch ALL assessments (quiz or essay) for ONE student.
  // ---------------------------------------------------------------------------
  Future<void> _fetchAllAssessmentsForStudents() async {
    if (_selectedCourse == null) {
      setState(() {
        _studentCourseData.clear();
      });
      return;
    }
    List<Future<List<Map<String, String>>>> futureList = [];
    for (var assessment in _assessmentsData) {
      futureList.add(() async {
        List<Participant> participants = [];
        if (assessment.type == "quiz") {
          participants = await lmsService.getQuizGradesForParticipants(
            _selectedCourse!.id.toString(),
            assessment.id,
          );
        } else if (assessment.type == "essay") {
          participants = await lmsService.getEssayGradesForParticipants(
            _selectedCourse!.id.toString(),
            assessment.id,
          );
        }
        return participants.map((participant) {
          return {
            'Assessment': assessment.name,
            'Type': assessment.type.toUpperCase(),
            'Student ID': participant.id.toString(),
            'Student Name': participant.fullname,
            'Grade': "${(participant.avgGrade ?? 0)}%",
            'Due Date':
                assessment.dueDate?.millisecondsSinceEpoch.toString() ?? "N/A"
          };
        }).toList();
      }());
    }
    try {
      final data = await Future.wait(futureList);
      List<Map<String, String>> unwrapped = [];
      for (var d in data) {
        for (var m in d) {
          unwrapped.add(m);
        }
      }
      unwrapped.sort((a, b) =>
          DateTime.fromMillisecondsSinceEpoch(int.parse(b['Due Date'] ?? '0'))
              .compareTo(DateTime.fromMillisecondsSinceEpoch(
                  int.parse(a['Due Date'] ?? '0'))));
      setState(() {
        _studentCourseData = unwrapped;
      });
    } catch (e) {
      setState(() {
        _studentCourseData.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error occurred while fetching student data: $e.")),
        );
      });
    }
  }

  // ---------------------------------------------------------------------------
  // _fetchQuestionBreakdown:
  // If a quiz is selected, fetch its question breakdown.
  // ---------------------------------------------------------------------------
  Future<void> _fetchQuestionBreakdown() async {
    if (isQuiz()) {
      try {
        int quizId = _selectedAssessment!.assessment.id;
        _questionBreakdown =
            await (lmsService as dynamic).getQuestionStatsFromQuiz(quizId);
        setState(() {});
      } catch (e) {
        print("Failed to fetch question breakdown: $e");
      }
    }
  }

  bool isQuiz() {
    return _selectedAssessment != null && _selectedAssessment!.type == "quiz";
  }

  bool isEssay() {
    return _selectedAssessment != null && _selectedAssessment!.type == "essay";
  }

  // ---------------------------------------------------------------------------
  // _buildMainGrid:
  // Creates a 2×2 grid layout:
  //  Top-left: Report form
  //  Bottom-left: Student breakdown table
  //  Top-right: Question breakdown
  //  Bottom-right: Selected student detail
  // ---------------------------------------------------------------------------
  Widget _buildMainGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (narrow)
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top-left: the report form
              _buildReportForm(),
              const SizedBox(height: 20),
              Row(children: [
                Text(
                  'Student Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Spacer(),
                ElevatedButton(
                    onPressed: _selectedStudent == null
                        ? null
                        : () => setState(() {
                              _selectedStudent = null;
                            }),
                    child: Text("Clear Selection"))
              ]),
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: _buildStudentTable(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right Column (wider)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top-right: label + question breakdown
              Visibility(
                  visible: isQuiz(),
                  child: const Text(
                    'Question Breakdown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  )),
              Visibility(visible: isQuiz(), child: const SizedBox(height: 8)),
              Visibility(
                  visible: isQuiz(),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: _buildQuestionBreakdown(),
                  )),
              Visibility(visible: isQuiz(), child: const SizedBox(height: 20)),
              // Bottom-right: label + selected student detail
              const Text(
                'Student Detail',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: _buildStudentDetail(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // _buildContent:
  // Builds the overall page content including analytics summary and the 2x2 grid.
  // ---------------------------------------------------------------------------
  Widget _buildContent() {
    if (isLoading && analyticsData == null && errorMsg.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMsg.isNotEmpty) {
      return Center(child: Text(errorMsg));
    }
    if (analyticsData == null) {
      return const Center(child: Text('No analytics data available yet.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Analytics summary.
          Center(
            child: Column(
              children: [
                Text('Analytics Source: ${analyticsData!['source']}',
                    style: const TextStyle(fontSize: 16)),
                Text('Total Courses: ${analyticsData!['totalCourses']}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    'Student Performance: ${analyticsData!['studentPerformance']}',
                    style: const TextStyle(fontSize: 16)),
                Text('IEP Progress: ${analyticsData!['iepProgress']}',
                    style: const TextStyle(fontSize: 16)),
                Text('Course Engagement: ${analyticsData!['courseEngagement']}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 2x2 grid view.
          _buildMainGrid(),
          // AI Analysis table below the grid with an export button.
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Analysis Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: (_aiAnalysisSuccess.isNotEmpty ||
                            _aiAnalysisFail.isNotEmpty ||
                            _aiAnalysisAssignment.isNotEmpty ||
                            _aiAnalysisAi.isNotEmpty ||
                            _aiAnalysisCourse.isNotEmpty) &&
                        !_isAnalyzingAi &&
                        !_isAnalyzingAssignment &&
                        !_isAnalyzingCourse &&
                        !_isAnalyzingStudents &&
                        !_isAnalyzingFail &&
                        !_isAnalyzingSuccess
                    ? _exportAIAnalysis
                    : null,
                child: const Text('Export AI Analysis'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAIAnalysisList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // build:
  // Sets up the Scaffold using the shared CustomAppBar and the main content.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Analytics Dashboard',
        userprofileurl: lmsService.profileImage ?? '',
        onRefresh: _fetchAnalyticsData,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // build:
  // Builds the overall AI analyisis summary below the 2x2 grid.
  // ---------------------------------------------------------------------------
  Widget _buildAIAnalysisList() {
    _exportFrameIds = [];
    return SelectionArea(
        child: ExpansionPanelList(
            expandedHeaderPadding: EdgeInsets.zero,
            materialGapSize: 0,
            expansionCallback: (panelIndex, isExpanded) {
              if (isExpanded && !_expandedPanels.contains(panelIndex)) {
                setState(() {
                  _expandedPanels.add(panelIndex);
                });
              } else if (!isExpanded && _expandedPanels.contains(panelIndex)) {
                setState(() {
                  _expandedPanels.remove(panelIndex);
                });
              }
            },
            children: _buildAiAnalysisChildren()));
  }

  List<ExpansionPanel> _buildAiAnalysisChildren() {
    List<ExpansionPanel> children = [
      _buildChild(
          0,
          "Areas of Understanding",
          _isAnalyzingSuccess,
          _aiAnalysisSuccess.isEmpty ||
                  !_aiAnalysisSuccess[0].containsKey("Summary")
              ? null
              : _aiAnalysisSuccess[0]["Summary"],
          AnalysisDataType.bar,
          _aiAnalysisSuccess.length < 2 ||
                  !_aiAnalysisSuccess[1].containsKey("Data")
              ? null
              : _aiAnalysisSuccess[1]["Data"],
          "Top Areas of Understanding",
          "Topic",
          "Percentage"),
      _buildChild(
          1,
          "Areas of Misunderstanding",
          _isAnalyzingFail,
          _aiAnalysisFail.isEmpty || !_aiAnalysisFail[0].containsKey("Summary")
              ? null
              : _aiAnalysisFail[0]["Summary"],
          AnalysisDataType.bar,
          _aiAnalysisFail.length < 2 || !_aiAnalysisFail[1].containsKey("Data")
              ? null
              : _aiAnalysisFail[1]["Data"],
          "Top Areas of Misunderstanding",
          "Topic",
          "Percentage"),
      _buildChild(
          2,
          "Course Improvements",
          _isAnalyzingCourse,
          _aiAnalysisCourse.isEmpty ||
                  !_aiAnalysisCourse[0].containsKey("Summary")
              ? null
              : _aiAnalysisCourse[0]["Summary"],
          AnalysisDataType.list,
          _aiAnalysisCourse.length < 2 ||
                  !_aiAnalysisCourse[1].containsKey("Data")
              ? null
              : _aiAnalysisCourse[1]["Data"],
          "Suggested Assignments",
          "Name",
          "Description"),
      _buildChild(
          3,
          "Assignment Improvements",
          _isAnalyzingAssignment,
          _aiAnalysisAssignment.isEmpty ||
                  !_aiAnalysisAssignment[0].containsKey("Summary")
              ? null
              : _aiAnalysisAssignment[0]["Summary"],
          AnalysisDataType.list,
          _aiAnalysisAssignment.length < 2 ||
                  !_aiAnalysisAssignment[1].containsKey("Data")
              ? null
              : _aiAnalysisAssignment[1]["Data"],
          "Suggested References",
          "URL",
          "Description"),
      _buildChild(
          4,
          "Student Trends",
          _isAnalyzingStudents,
          _aiAnalysisStudent.isEmpty ||
                  !_aiAnalysisStudent[0].containsKey("Summary")
              ? null
              : _aiAnalysisStudent[0]["Summary"],
          AnalysisDataType.line,
          _selectedStudent == null
              ? _studentCourseData
              : _studentCourseData
                  .where((element) =>
                      int.parse(element['Student ID']!) ==
                      _selectedStudent!["id"])
                  .toList(),
          "Student Grades Over Time",
          "Grade",
          "Due Date")
    ];

    if (!_lastAnalysisQuiz) {
      children.add(_buildChild(
          5,
          "AI Use Areas",
          _isAnalyzingAi,
          _aiAnalysisAi.isEmpty || !_aiAnalysisAi[0].containsKey("Summary")
              ? null
              : _aiAnalysisAi[0]["Summary"],
          AnalysisDataType.bar,
          _aiAnalysisAi.length < 2 || !_aiAnalysisAi[1].containsKey("Data")
              ? null
              : _aiAnalysisAi[1]["Data"],
          "Top AI Use Cases",
          "Area",
          "Percentage"));
    }
    return children;
  }

  ExpansionPanel _buildChild(
      int index,
      String title,
      bool wait,
      String? bodyText,
      AnalysisDataType dataType,
      List<dynamic>? data,
      String graphicTitle,
      String key1,
      String key2) {
    bool isUrl = key1 == "URL";
    if (data != null && data.isNotEmpty) {
      data = data
          .where((e) =>
              e.containsKey(key1) &&
              e.containsKey(key2) &&
              (dataType != AnalysisDataType.line || e[key2] != 'N/A'))
          .toList();
      if (isUrl) {
        data = data
            .where((element) =>
                element.containsKey("ValidURL") && element["ValidURL"])
            .toList();
      }
    }

    final aiExportItems = ["aiExport${title}Header", "aiExport${title}Body"];
    _exportFrameIds.add(aiExportItems);
    return ExpansionPanel(
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer.withOpacity(1),
        canTapOnHeader: true,
        headerBuilder: (context, isExpanded) {
          return ExportFrame(
              frameId: aiExportItems[0],
              exportDelegate: exp,
              child: Container(
                  padding: EdgeInsets.all(10),
                  child: Row(children: [
                    Text(
                      title,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Spacer(),
                    Visibility(
                        visible: wait, child: CircularProgressIndicator())
                  ])));
        },
        body: ExportFrame(
            frameId: aiExportItems[1],
            exportDelegate: exp,
            child: Container(
                color: Colors.grey[200],
                padding: EdgeInsets.all(10),
                child: Row(children: [
                  Expanded(
                      child: Text(
                    wait
                        ? "Loading AI Analysis..."
                        : (bodyText ?? "No AI Analysis Summary Found"),
                    softWrap: true,
                  )),
                  SizedBox(width: 10),
                  Visibility(
                      visible: !wait && bodyText != null,
                      child: Column(children: [
                        Text(graphicTitle,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                            height: 320,
                            width: 370,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: BoxBorder.all(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                            child: data == null || data.isEmpty
                                ? Text("No AI Analysis Data found.")
                                : dataType == AnalysisDataType.bar
                                    ? CaptureWrapper(
                                        key: Key('${title}BarChart'),
                                        child: BarChart(BarChartData(
                                            gridData: FlGridData(
                                                drawVerticalLine: false,
                                                horizontalInterval: 25),
                                            barTouchData:
                                                BarTouchData(enabled: false),
                                            minY: 0,
                                            maxY: 100,
                                            alignment:
                                                BarChartAlignment.spaceAround,
                                            barGroups: data.map((e) {
                                              HSLColor hsl = HSLColor.fromColor(
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer);
                                              return BarChartGroupData(
                                                  x: data!.indexOf(e),
                                                  barRods: [
                                                    BarChartRodData(
                                                        toY: e[key2].toDouble(),
                                                        width: 20,
                                                        borderRadius:
                                                            BorderRadius.zero,
                                                        color: hsl
                                                            .withLightness((hsl
                                                                        .lightness -
                                                                    data.indexOf(
                                                                            e) /
                                                                        10.0)
                                                                .clamp(0, 1))
                                                            .toColor())
                                                  ]);
                                            }).toList(),
                                            titlesData: FlTitlesData(
                                                bottomTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 100,
                                                  getTitlesWidget: (value,
                                                          meta) =>
                                                      SideTitleWidget(
                                                          meta: meta,
                                                          child: SizedBox(
                                                              width: 95,
                                                              child: Text(
                                                                data![value.toInt()]
                                                                        [key1]
                                                                    .toString(),
                                                                softWrap: true,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 5,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12),
                                                              ))),
                                                )),
                                                topTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 50,
                                                  getTitlesWidget:
                                                      (value, meta) =>
                                                          SideTitleWidget(
                                                              space: 20,
                                                              meta: meta,
                                                              child: Text(
                                                                "${data![value.toInt()][key2].toString()}%",
                                                                softWrap: true,
                                                              )),
                                                )),
                                                rightTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 10,
                                                    getTitlesWidget: (value,
                                                            meta) =>
                                                        SideTitleWidget(
                                                            meta: meta,
                                                            child: SizedBox()),
                                                  ),
                                                ),
                                                leftTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                  interval: 25,
                                                  reservedSize: 50,
                                                  showTitles: true,
                                                  getTitlesWidget: (value,
                                                          meta) =>
                                                      SideTitleWidget(
                                                          meta: meta,
                                                          child:
                                                              Text("$value%")),
                                                ))))))
                                    : dataType == AnalysisDataType.list
                                        ? ListView.builder(
                                            itemCount: data.length,
                                            itemBuilder: (context, index) {
                                              Widget firstItem = Text(
                                                  data![index][key1],
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: isUrl
                                                          ? TextDecoration
                                                              .underline
                                                          : null,
                                                      color: isUrl
                                                          ? Colors.blue
                                                          : Colors.black));
                                              return Column(children: [
                                                isUrl
                                                    ? InkWell(
                                                        child: firstItem,
                                                        onTap: () => launchUrl(
                                                            Uri.parse(
                                                                data![index]
                                                                    [key1]),
                                                            webOnlyWindowName:
                                                                "_blank"),
                                                      )
                                                    : firstItem,
                                                Text(data[index][key2])
                                              ]);
                                            })
                                        : CaptureWrapper(
                                            key: Key('${title}ScatterPlot'),
                                            child: ScatterChart(ScatterChartData(
                                                minY: 0,
                                                maxY: 100,
                                                scatterTouchData: ScatterTouchData(
                                                    touchTooltipData: ScatterTouchTooltipData(
                                                        getTooltipColor: (touchedSpot) => contrastColors[int.parse(data![touchedSpot.renderPriority]['Student ID']) % Colors.primaries.length][1],
                                                        fitInsideHorizontally: true,
                                                        fitInsideVertically: true,
                                                        getTooltipItems: (touchedSpot) {
                                                          final defaultSp =
                                                              defaultScatterTooltipItem(
                                                                  touchedSpot);
                                                          return ScatterTooltipItem(
                                                              "Student: ${data![touchedSpot.renderPriority]['Student Name']}\nAssignment: ${data[touchedSpot.renderPriority]['Assessment']} (${data[touchedSpot.renderPriority]['Type']})\nDue: ${DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(int.parse(data[touchedSpot.renderPriority]['Due Date'])))}\nGrade:${data[touchedSpot.renderPriority]['Grade']}\n",
                                                              textStyle: defaultSp
                                                                  ?.textStyle);
                                                        })),
                                                scatterSpots: data.map((e) {
                                                  String grade = e['Grade'];
                                                  return ScatterSpot(
                                                      dotPainter: FlDotCirclePainter(
                                                          color: contrastColors[int.parse(e[
                                                                  'Student ID']) %
                                                              Colors.primaries
                                                                  .length][0],
                                                          radius: 7),
                                                      double.parse(
                                                          e['Due Date']),
                                                      double.parse(grade.substring(
                                                          0, grade.length - 1)),
                                                      renderPriority:
                                                          data!.indexOf(e));
                                                }).toList(),
                                                titlesData: FlTitlesData(
                                                    bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                      showTitles: true,
                                                      minIncluded: true,
                                                      maxIncluded: false,
                                                      reservedSize: 100,
                                                      getTitlesWidget: (value,
                                                              meta) =>
                                                          SideTitleWidget(
                                                              meta: meta,
                                                              angle: -70,
                                                              child: SizedBox(
                                                                  width: 100,
                                                                  child: Text(
                                                                    (DateFormat
                                                                            .yMd()
                                                                        .format(
                                                                            DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal())),
                                                                    softWrap:
                                                                        true,
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 1,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12),
                                                                  ))),
                                                    )),
                                                    topTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        reservedSize: 10,
                                                        getTitlesWidget: (value,
                                                                meta) =>
                                                            SideTitleWidget(
                                                                meta: meta,
                                                                child:
                                                                    SizedBox()),
                                                      ),
                                                    ),
                                                    rightTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        reservedSize: 10,
                                                        getTitlesWidget: (value,
                                                                meta) =>
                                                            SideTitleWidget(
                                                                meta: meta,
                                                                child:
                                                                    SizedBox()),
                                                      ),
                                                    ),
                                                    leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                      interval: 10,
                                                      reservedSize: 50,
                                                      showTitles: true,
                                                      getTitlesWidget: (value,
                                                              meta) =>
                                                          SideTitleWidget(
                                                              meta: meta,
                                                              child: Text(
                                                                  "$value%")),
                                                    )))))))
                      ]))
                ]))),
        isExpanded: _expandedPanels.contains(index));
  }

  /// Computes the percentage a question is answered correctly.
  double computePercentCorrect(QuestionStatsType q) {
    if (q.totalAttempts == 0) return 0.0;
    return ((q.numCorrect + q.numPartial) / q.totalAttempts) * 100;
  }

  /// Computes the average grade across the student breakdown.
  double getAverageGrade() {
    if (_studentBreakdown.isEmpty) return 0.0;
    double sum = 0.0;
    for (var student in _studentBreakdown) {
      String? gradeStr = student['avgGrade'];
      if (gradeStr == null || gradeStr.isEmpty) continue;
      gradeStr = gradeStr.replaceAll('%', '');
      double? numericGrade = double.tryParse(gradeStr);
      sum += numericGrade ?? 0.0;
    }
    return sum / _studentBreakdown.length;
  }

  /// Returns the total number of quizzes submitted for the current quiz.
  int getTotalSubmittedQuizzes() {
    if (_questionBreakdown.isEmpty) return 0;
    double grandTotalAttempts = 0;
    int questionCount = _questionBreakdown.length;
    for (QuestionStatsType q in _questionBreakdown) {
      grandTotalAttempts += (q.numCorrect + q.numIncorrect + q.numPartial);
    }
    if (questionCount == 0) return 0;
    return (grandTotalAttempts / questionCount).round();
  }

  Future<void> _analyzeReport(
      Course selectedCourse,
      Assessment selectedAssessment,
      List<Participant> participantsData,
      int? selectedStudentId,
      List<QuestionStatsType>? questionBreakdown,
      List<Map<String, String>> studentCourseData,
      String selectedGradeLevel) async {
    if (selectedLLM == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "No AI credentials found. Please log in to an AI platform.")),
      );
      return;
    }
    Participant? selectedParticipant =
        participantsData.firstWhereOrNull((p) => p.id == selectedStudentId);

    try {
      setState(() {
        canceled = false;
        _aiAnalysisAi = [];
        _aiAnalysisSuccess = [];
        _aiAnalysisFail = [];
        _aiAnalysisStudent = [];
        _aiAnalysisAssignment = [];
        _aiAnalysisCourse = [];

        _isAnalyzingSuccess = true;
        _isAnalyzingFail = true;
        _isAnalyzingAssignment = true;
        _isAnalyzingCourse = true;
        _isAnalyzingStudents = true;
        _isAnalyzingAi = selectedAssessment.type == "essay";
        _lastAnalysisQuiz = selectedAssessment.type == "quiz";
        _lastAnalysisCourse = selectedCourse.fullName;
        _lastAnalysisAssignment =
            '${selectedAssessment.name} (${selectedAssessment.type.toUpperCase()})';
        _lastAnalysisStudent = selectedParticipant?.fullname ?? "Course";
      });

      String assignmentDescription;

      List<Future> futures = [];

      if (selectedParticipant != null) {
        studentCourseData = studentCourseData
            .where((element) =>
                int.parse(element['Student ID']!) == selectedParticipant.id)
            .toList();
      }

      if (studentCourseData.isNotEmpty) {
        String studentGrades = studentCourseData.map((data) {
          return "Student: ${data['Student Name']}, Assignment: ${data['Assessment']}, Type: ${data['Type']}, Grade: ${data['Grade']}, Due Date: ${DateTime.fromMillisecondsSinceEpoch(int.parse(data['Due Date']!))}";
        }).join("\n");
        if (selectedLLM != LlmType.LOCAL) {
          futures.add(_analyzeStudentTrend(studentGrades, selectedGradeLevel));
        } else {
          await _analyzeStudentTrend(studentGrades, selectedGradeLevel);
        }
      } else {
        setState(() {
          _isAnalyzingStudents = false;
        });
      }

      // Build a summary string from the student breakdown data.
      if (selectedAssessment.type == "essay") {
        String studentSummary;
        assignmentDescription = selectedAssessment.description;
        List<Submission> submissions =
            await lmsService.getAssignmentSubmissions(selectedAssessment.id);
        List<AiLog> aiLogs = await AILoggingSingleton().getLogs(
            selectedCourse,
            selectedAssessment.assessment,
            selectedParticipant,
            LocalStorageService.getSelectedClassroom().index,
            DateTime(2025, 9),
            DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day));

        // Whole course
        if (selectedParticipant == null) {
          studentSummary = participantsData
              .map((student) {
                Submission? s =
                    submissions.firstWhereOrNull((s) => s.userid == student.id);
                if (s != null) {
                  return "Name: ${student.fullname}, Submission: ${s.onlineText}";
                } else {
                  return "";
                }
              })
              .where((result) => result.isNotEmpty)
              .join("\n");
        }
        // Single student
        else {
          studentSummary =
              "Name: ${selectedParticipant.fullname}, Submission: ${submissions.firstWhereOrNull((s) => s.userid == selectedParticipant.id)?.onlineText}";
        }

        String aiSummary = aiLogs.map((logEntry) {
          return "Prompt: ${logEntry.prompt}, Reflection: ${logEntry.reflection}";
        }).join("\n");

        if (studentSummary.trim().isNotEmpty) {
          if (selectedLLM != LlmType.LOCAL) {
            futures.addAll([
              _analyzeEssaySuccess(selectedAssessment.name,
                  assignmentDescription, studentSummary, selectedGradeLevel),
              _analyzeEssayMisunderstanding(selectedAssessment.name,
                  assignmentDescription, studentSummary, selectedGradeLevel),
            ]);
          } else {
            await _analyzeEssaySuccess(selectedAssessment.name,
                assignmentDescription, studentSummary, selectedGradeLevel);
            await _analyzeEssayMisunderstanding(selectedAssessment.name,
                assignmentDescription, studentSummary, selectedGradeLevel);
          }
        } else {
          setState(() {
            _isAnalyzingSuccess = false;
            _isAnalyzingFail = false;
          });
        }

        if (aiSummary.trim().isNotEmpty) {
          if (selectedLLM != LlmType.LOCAL) {
            futures.add(_analyzeEssayAiUse(selectedAssessment.name,
                assignmentDescription, aiSummary, selectedGradeLevel));
          } else {
            await _analyzeEssayAiUse(selectedAssessment.name,
                assignmentDescription, aiSummary, selectedGradeLevel);
          }
        } else {
          setState(() {
            _isAnalyzingAi = false;
          });
        }
      } else {
        if (questionBreakdown == null) {
          setState(() {
            _isAnalyzingSuccess = false;
            _isAnalyzingFail = false;
            _isAnalyzingAssignment = false;
            _isAnalyzingCourse = false;
            _isAnalyzingStudents = false;
          });
          return;
        }
        String studentSummary;
        assignmentDescription = selectedAssessment.description;
        if (selectedParticipant != null) {
          List studentData = await lmsService.getQuizStatsForStudent(
              (selectedAssessment.assessment as Quiz).id!.toString(),
              selectedParticipant.id);
          studentSummary = studentData.map((question) {
            return "Question: ${question['questiontext']}, Type: ${question['qtype']}, Correct Answer: ${question['qright']}, Selected Answer: ${question['qanswer']}, State: ${question['qstate']}";
          }).join("\n");

          if (studentSummary.trim().isNotEmpty) {
            if (selectedLLM != LlmType.LOCAL) {
              futures.addAll([
                _analyzeStudentQuizSuccess(
                    selectedAssessment.name,
                    assignmentDescription,
                    studentSummary,
                    selectedParticipant.fullname,
                    selectedGradeLevel),
                _analyzeStudentQuizMisunderstanding(
                    selectedAssessment.name,
                    assignmentDescription,
                    studentSummary,
                    selectedParticipant.fullname,
                    selectedGradeLevel)
              ]);
            } else {
              await _analyzeStudentQuizSuccess(
                  selectedAssessment.name,
                  assignmentDescription,
                  studentSummary,
                  selectedParticipant.fullname,
                  selectedGradeLevel);
              await _analyzeStudentQuizMisunderstanding(
                  selectedAssessment.name,
                  assignmentDescription,
                  studentSummary,
                  selectedParticipant.fullname,
                  selectedGradeLevel);
            }
          } else {
            setState(() {
              _isAnalyzingSuccess = false;
              _isAnalyzingFail = false;
            });
          }
        } else {
          studentSummary = questionBreakdown.map((q) {
            return "Question: ${q.questionText}, Percent Correct: ${computePercentCorrect(q).toStringAsFixed(2)}%, Number Correct: ${q.numCorrect}, Number Incorrect: ${q.numIncorrect}, Total Attempts: ${q.totalAttempts}";
          }).join("\n");
          if (studentSummary.trim().isNotEmpty) {
            if (selectedLLM != LlmType.LOCAL) {
              futures.addAll([
                _analyzeCourseQuizSuccess(selectedAssessment.name,
                    assignmentDescription, studentSummary, selectedGradeLevel),
                _analyzeCourseQuizMisunderstanding(selectedAssessment.name,
                    assignmentDescription, studentSummary, selectedGradeLevel)
              ]);
            } else {
              await _analyzeCourseQuizSuccess(selectedAssessment.name,
                  assignmentDescription, studentSummary, selectedGradeLevel);
              await _analyzeCourseQuizMisunderstanding(selectedAssessment.name,
                  assignmentDescription, studentSummary, selectedGradeLevel);
            }
          } else {
            setState(() {
              _isAnalyzingSuccess = false;
              _isAnalyzingFail = false;
            });
          }
        }
      }
      if (selectedLLM != LlmType.LOCAL) {
        List<Future> futures2 = [
          _analyzeAssignmentImprovements(
              selectedAssessment.name,
              selectedCourse.fullName,
              assignmentDescription,
              _aiAnalysisSuccess.isEmpty
                  ? ""
                  : _aiAnalysisSuccess[0]["Summary"],
              _aiAnalysisFail.isEmpty ? "" : _aiAnalysisFail[0]["Summary"],
              selectedGradeLevel),
          _analyzeCourseImprovements(
              selectedAssessment.name,
              selectedCourse.fullName,
              assignmentDescription,
              _aiAnalysisSuccess.isEmpty
                  ? ""
                  : _aiAnalysisSuccess[0]["Summary"],
              _aiAnalysisFail.isEmpty ? "" : _aiAnalysisFail[0]["Summary"],
              selectedGradeLevel)
        ];
        await Future.wait(futures);
        await Future.wait(futures2);
      } else {
        await _analyzeAssignmentImprovements(
            selectedAssessment.name,
            selectedCourse.fullName,
            assignmentDescription,
            _aiAnalysisSuccess.isEmpty ? "" : _aiAnalysisSuccess[0]["Summary"],
            _aiAnalysisFail.isEmpty ? "" : _aiAnalysisFail[0]["Summary"],
            selectedGradeLevel);
        await _analyzeCourseImprovements(
            selectedAssessment.name,
            selectedCourse.fullName,
            assignmentDescription,
            _aiAnalysisSuccess.isEmpty ? "" : _aiAnalysisSuccess[0]["Summary"],
            _aiAnalysisFail.isEmpty ? "" : _aiAnalysisFail[0]["Summary"],
            selectedGradeLevel);
      }
      setState(() {
        _lastAnalysisCompletionTime = DateFormat.yMd().format(DateTime.now());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                "Error occurred during AI Analysis: $e. Results may be incomplete.")),
      );
      setState(() {
        _isAnalyzingSuccess = false;
        _isAnalyzingFail = false;
        _isAnalyzingAssignment = false;
        _isAnalyzingCourse = false;
        _isAnalyzingAi = false;
        _isAnalyzingStudents = false;
        _lastAnalysisCompletionTime = DateFormat.yMd().format(DateTime.now());
      });
      return;
    }
  }

  Future<void> _analyzeStudentTrend(
      String studentGrades, String selectedGradeLevel) async {
    String studentPrompt = """
    Analyze student performance over time for students for grade level '$selectedGradeLevel'.
    Assignment Submissions:
    $studentGrades
    Based on the list of student grades, perform an analysis of each student's performance over time.
    The analysis should be appropriate for the indicated grade level.
    Determine if each student is improving over time, staying the same over time, or worsening over time.
    Provide insight into how their assignment grades have changed from the earliest submission to the last submission.
    Provide insight into which assignments have not been submitted.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(studentPrompt);
    setState(() {
      _aiAnalysisStudent = response;
      _isAnalyzingStudents = false;
    });
  }

  Future<void> _analyzeEssaySuccess(String assessmentName, String essayPrompt,
      String studentSummary, String selectedGradeLevel) async {
    String successPrompt = """
    Compare the following student assignment submissions against the essay name '$assessmentName' with prompt '$essayPrompt' for grade level '$selectedGradeLevel'.
    Student Assignment Submissions:
    $studentSummary
    Based on the student submissions, provide a thorough analysis on which aspects of the assignment the students understood.
    To perform your analysis, compare each student submission to the essay name and the essay prompt.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary. Additionally, determine the top three topics from the essay prompt that students understood,
    based on the number of students who discussed that topic in their essay submission.
    For each area, provide the topic name and the percentage of student submissions that discussed the topic.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary' and
    the top three discussed topics are an object named 'Data' with keys 'Topic' and 'Percentage'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisSuccess = response;
      _isAnalyzingSuccess = false;
    });
  }

  Future<void> _analyzeEssayMisunderstanding(
      String assessmentName,
      String essayPrompt,
      String studentSummary,
      String selectedGradeLevel) async {
    String successPrompt = """
    Compare the following student assignment submissions against the essay name '$assessmentName' with prompt '$essayPrompt' for grade level '$selectedGradeLevel'.
    Student Assignment Submissions:
    $studentSummary
    Based on the student submissions, provide a thorough analysis on which aspects of the assignment the students did not understand.
    To perform your analysis, compare each student submission to the essay name and the essay prompt.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary. Additionally, determine the top three topics from the essay prompt that students did not understand,
    based on the number of students who failed to discuss that topic in their essay submission.
    For each area, provide the topic name and the percentage of student submissions that did not discuss the topic.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary' and
    the top three topics that were not discussed are an object named 'Data' with keys 'Topic' and 'Percentage'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisFail = response;
      _isAnalyzingFail = false;
    });
  }

  Future<void> _analyzeEssayAiUse(String assessmentName, String essayPrompt,
      String aiSummary, String selectedGradeLevel) async {
    String successPrompt = """
    Summarize how students used AI on the essay name '$assessmentName' with prompt '$essayPrompt' for grade level '$selectedGradeLevel'.
    Student AI Interactions:
    $aiSummary
    Based on the student AI interactions, provide a thorough analysis on how students used and reflected on AI use throughout the assignment.
    To perform your analysis, summarize the student prompts and reflections on AI use.
    The analysis should be appropriate for the indicated grade level.
    If there is no AI use on this essay, then there is nothing to summarize.
    Provide a textual summary. Additionally, determine the top three AI use cases, each with a brief description and a percentage. If there was no AI use on this essay, then this list should be empty.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary' and
    the top three AI use areas are an object named 'Data' with keys 'Area' and 'Percentage'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Area": "Area Name",
            "Percentage": 100
          },
          {
            "Area": "Area Name",
            "Percentage": 100
          },
          {
            "Area": "Area Name",
            "Percentage": 100
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisAi = response;
      _isAnalyzingAi = false;
    });
  }

  Future<void> _analyzeCourseImprovements(
      String courseName,
      String assessmentName,
      String essayPrompt,
      String successes,
      String failures,
      String selectedGradeLevel) async {
    String successPrompt = """
    Recommend improvements that could be made to course '$courseName' for grade level '$selectedGradeLevel'.
    Areas of Understanding:
    $successes
    Areas of Misunderstanding:
    $failures
    Based on the summaries of student understanding and student misunderstanding, recommend ways I can improve my course materials.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary for both course, as well as three assignments I could create for my course to improve student's understanding of the topic.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary',
    and the list of recommended assignments are an object named 'Data' with keys 'Name' and 'Description'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Name": "Assignment Name",
            "Description": "A description of the assignment."
          },
          {
            "Name": "Assignment Name",
            "Description": "A description of the assignment."
          },
          {
            "Name": "Assignment Name",
            "Description": "A description of the assignment."
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisCourse = response;
      _isAnalyzingCourse = false;
    });
  }

  Future<void> _analyzeAssignmentImprovements(
      String courseName,
      String assessmentName,
      String essayPrompt,
      String successes,
      String failures,
      String selectedGradeLevel) async {
    String successPrompt = """
    Recommend improvements that could be made to to assignment '$assessmentName' with description '$essayPrompt' for grade level '$selectedGradeLevel'.
    Areas of Understanding:
    $successes
    Areas of Misunderstanding:
    $failures
    Based on the summaries of student understanding and student misunderstanding, recommend ways I can improve the assignment.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary for assignment improvements, as well as three references I could provide to students to help them better understand the topic.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary',
    and the list of recommended references are an object named 'Data' with keys 'URL' and 'Description'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "URL": "https://www.example.com/",
            "Description": "A textual description of the reference."
          },
          {
            "URL": "https://www.example.com/",
            "Description": "A textual description of the reference."
          },
          {
            "URL": "https://www.example.com/",
            "Description": "A textual description of the reference."
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    // Check URL
    if (response.length >= 2 && response[1].containsKey("Data")) {
      for (dynamic map in response[1]["Data"]) {
        if (map.containsKey("URL")) {
          Uri? parse = Uri.tryParse(map["URL"]);

          bool isValid = parse != null;
          if (isValid) {
            try {
              isValid = (await http.get(parse)).statusCode < 400;
            } on http.ClientException {
              // Do nothing - not all CORS policies allow access but we still get the status code
            }
          }
          map["ValidURL"] = isValid;
        }
      }
    }
    setState(() {
      _aiAnalysisAssignment = response;
      _isAnalyzingAssignment = false;
    });
  }

  Future<void> _analyzeStudentQuizSuccess(
      String quizName,
      String quizDescription,
      String studentSummary,
      String studentName,
      String selectedGradeLevel) async {
    String successPrompt = """
    Compare the following student quiz results against the quiz name '$quizName' with description '$quizDescription' for student '$studentName' for grade level '$selectedGradeLevel'.
    Student Quiz Results:
    $studentSummary
    Based on the student quiz performance, provide a thorough analysis on which aspects of the assignment the student understood.
    To perform your analysis, determine which questions the user answered correctly, incorrectly, and partially correctly.
    Compare each question's state, correct answer, and selected answer against the quiz name and description.
    If the student answered all questions incorrectly, then there are no topics on this quiz that the student understood.
    Determine if a student was correct, partially correct, or incorrect using only the 'State' value of each question.
    A question that the student answered correctly will have a 'State' value of 'gradedright'.
    A question that the student answered correctly will have a 'State' value of 'gradedwrong'.
    A question that the student answered partially correctly will have a 'State' value of 'gradedpartial'.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary. Additionally, determine the top three topics from the quiz that student understood,
    based on number of questions about that topic the student answered correctly. If the student answered all questions incorrectly, then this list should be empty.
    For each topic, provide the topic name and the percentage of questions about that topic that were answered at least partially correctly.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary' and
    the top three correctly answered topics are an object named 'Data' with keys 'Topic' and 'Percentage'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisSuccess = response;
      _isAnalyzingSuccess = false;
    });
  }

  Future<void> _analyzeStudentQuizMisunderstanding(
      String quizName,
      String quizDescription,
      String studentSummary,
      String studentName,
      String selectedGradeLevel) async {
    String successPrompt = """
    Compare the following student quiz results against the quiz name '$quizName' with description '$quizDescription' for student '$studentName' for grade level '$selectedGradeLevel'.
    Student Quiz Results:
    $studentSummary
    Based on the student quiz performance, provide a thorough analysis on which aspects of the assignment the student did not understand.
    To perform your analysis, determine which questions the user answered correctly, incorrectly, and partially correctly.
    Compare each question's state, correct answer, and selected answer against the quiz name and description.
    If the student answered all questions correctly, then there are no topics on this quiz that the student did not understand.
    Determine if a student was correct, partially correct, or incorrect using only the 'State' value of each question.
    A question that the student answered correctly will have a 'State' value of 'gradedright'.
    A question that the student answered correctly will have a 'State' value of 'gradedwrong'.
    A question that the student answered partially correctly will have a 'State' value of 'gradedpartial'.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary.
    Additionally, determine the top three topics from the quiz that student did not understand,
    based on number of questions about that topic the student answered incorrectly. If the student answered all questions correctly, then this list should be empty.
    For each topic, provide the topic name and the percentage of questions about that topic that were answered at least partially incorrectly.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary' and
    the top three incorrectly answered topics are an object named 'Data' with keys 'Topic' and 'Percentage'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisFail = response;
      _isAnalyzingFail = false;
    });
  }

  Future<void> _analyzeCourseQuizSuccess(
      String quizName,
      String quizDescription,
      String studentSummary,
      String selectedGradeLevel) async {
    String successPrompt = """
    Compare the following class quiz results against the quiz name '$quizName' with description '$quizDescription' for grade level '$selectedGradeLevel'.
    Student Quiz Results:
    $studentSummary
    Based on the student quiz performance, provide a thorough analysis on which aspects of the assignment the class understood.
    To perform your analysis, determine how many times each question was answered correctly, incorrectly, and partially correctly
    and compare the question text against the quiz name and description.
    If all questions have an 0% correctness rate, then there are no topics on this quiz that the course understood.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary. Additionally, determine the top three topics from the quiz that the course understood,
    based on number of questions about that topic the course answered correctly.
    For each topic, provide the topic name and the percentage of questions about that topic that were answered correctly. If all questions have a 0% correctness rate, then this list should be empty.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary' and
    the top three correctly answered topics are an object named 'Data' with keys 'Topic' and 'Percentage'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisSuccess = response;
      _isAnalyzingSuccess = false;
    });
  }

  Future<void> _analyzeCourseQuizMisunderstanding(
      String quizName,
      String quizDescription,
      String studentSummary,
      String selectedGradeLevel) async {
    String successPrompt = """
    Compare the following class quiz results against the quiz name '$quizName' with description '$quizDescription' for grade level '$selectedGradeLevel'.
    Student Quiz Results:
    $studentSummary
    Based on the student quiz performance, provide a thorough analysis on which aspects of the assignment the class did not understand.
    To perform your analysis, determine how many times each question was answered correctly, incorrectly, and partially correctly
    and compare the question text against the quiz name and description.
    If all questions have a 100% correctness rate, then there are no topics on this quiz that the course did not understand.
    The analysis should be appropriate for the indicated grade level.
    Provide a textual summary. Additionally, determine the top three topics from the quiz that the course did not understand,
    based on number of questions about that topic the course answered incorrectly.
    For each topic, provide the topic name and the percentage of questions about that topic that were answered incorrectly.  If all questions have a 100% correctness rate, then this list should be empty.
    Return your analysis as a JSON array where the textual summary is an object with key 'Summary' and
    the top three incorrectly answered topics are an object named 'Data' with keys 'Topic' and 'Percentage'.
    An example of a properly formatted JSON array is:
    [
      {
        "Summary": "A textual summary of the analysis."
      },
      {
        "Data": [
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          },
          {
            "Topic": "Topic Name",
            "Percentage": 100
          }
        ]
      }
    ]
    """;

    List<Map<String, dynamic>> response = await _doAiQuery(successPrompt);
    setState(() {
      _aiAnalysisFail = response;
      _isAnalyzingFail = false;
    });
  }

  Future<List<Map<String, dynamic>>> _doAiQuery(String prompt) async {
    // Select the AI model based on the available credentials.
    LLM aiModel;
    if (selectedLLM == LlmType.CHATGPT) {
      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
    } else if (selectedLLM == LlmType.GROK) {
      aiModel = GrokLLM(LocalStorageService.getGrokKey());
    } else if (selectedLLM == LlmType.DEEPSEEK) {
      aiModel = DeepseekLLM(LocalStorageService.getDeepseekKey());
    } else if (selectedLLM == LlmType.LOCAL) {
      aiModel = LocalLLMService();
    } else {
      aiModel = PerplexityLLM(LocalStorageService.getPerplexityKey());
    }

    if (selectedLLM != LlmType.LOCAL ||
        await LocalLLMService().checkIfLoadedLocalLLMRecommended()) {
      try {
        var result =
            await aiModel.postToLlm(HtmlConverter.convert(prompt) ?? "");
        if (!canceled) {
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
          if (jsonData is List) {
            return List<Map<String, dynamic>>.from(jsonData);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text("AI analysis did not return a valid JSON array.")),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error during AI analysis: $e")),
        );
      }
    }
    return [];
  }
}
