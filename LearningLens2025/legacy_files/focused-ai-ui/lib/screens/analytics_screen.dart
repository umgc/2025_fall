// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;


import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:focused_ai_ui/models/course.dart';
import 'package:focused_ai_ui/models/grade.dart';
import '../services/analytics_services.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  List<Course> _courses = [];
  List<Grade> _grades = [];

  int? _selectedCourseId;
  bool _isLoadingGrades = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() async {
    try {
      final courses = await _analyticsService.getCourses();
      setState(() {
        _courses = courses;
        if (_selectedCourseId != null &&
            !_courses.any((c) => c.id == _selectedCourseId)) {
          _selectedCourseId = null;
        }
      });
    } catch (e) {
      print("Failed to load courses: $e");
    }
  }

  void _onCourseSelected(int courseId) {
    setState(() {
      _selectedCourseId = courseId;
      _grades = [];
      _isLoadingGrades = true;
    });
    _loadCourseGrades(courseId);
  }

  Future<void> _loadCourseGrades(int courseId) async {
    try {
      final grades = await _analyticsService.fetchQuizGrades(courseId);
      setState(() {
        _grades = grades;
      });
    } catch (e) {
      print("Failed to load grades: $e");
    } finally {
      setState(() {
        _isLoadingGrades = false;
      });
    }
  }

  /*Future<void> _exportGradesToCSV() async {
  if (_grades.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No grades to export")),
    );
    return;
  }

  try {
    // Convert to rows
    List<List<String>> rows = [
      ["Assignment Title", "Student ID", "Grade"],
      ..._grades.map((g) => [
            g.assignmentTitle,
            g.studentId,
            g.grade.toStringAsFixed(1),
          ])
    ];

    // Convert to CSV string
    String csvData = const ListToCsvConverter().convert(rows);

    // Save to file
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/grades_export.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    // Share or open
    await Share.shareXFiles([XFile(path)], text: "Exported Quiz Grades");

  } catch (e) {
    print("Export error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to export grades")),
    );
  }
}*/

void exportCsvWeb(String csvContent, String fileName) {
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

  Map<String, double> _calculateAverageGradesPerQuiz(List<Grade> grades) {
    final Map<String, List<double>> grouped = {};
    for (final g in grades) {
      grouped.putIfAbsent(g.submissionId, () => []).add(g.score);
    }
    return grouped.map((title, gradesList) {
      final avg = gradesList.reduce((a, b) => a + b) / gradesList.length;
      return MapEntry(title, avg);
    });
  }

@override
Widget build(BuildContext context) {
  final averageGrades = _calculateAverageGradesPerQuiz(_grades);

  return Scaffold(
    appBar: AppBar(title: const Text("Course Analytics")),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Select a course",
            ),
            value: _selectedCourseId,
            items: _courses.map((course) {
              return DropdownMenuItem<int>(
                child: Text(course.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) _onCourseSelected(value);
            },
          ),
          const SizedBox(height: 24),

          if (_grades.isNotEmpty)
/*  Align(
    alignment: Alignment.centerRight,
    child: ElevatedButton.icon(
      onPressed: _exportGradesToCSV,
      icon: const Icon(Icons.download),
      label: const Text("Export Grades"),
    ),
  ),*/

Align(
    alignment: Alignment.centerRight,
  child:ElevatedButton.icon(
  onPressed: () {
    final csvBuffer = StringBuffer();
    csvBuffer.writeln("Quiz Title,Student ID,Grade");
    for (final grade in _grades) {
      csvBuffer.writeln("${grade.gradedAt},${grade.submissionId},${grade.score}");
    }
    exportCsvWeb(csvBuffer.toString(), "quiz_grades.csv");
  },
  icon: const Icon(Icons.download),
  label: const Text("Export CSV"),
),),

          if (_isLoadingGrades)
            const Center(child: CircularProgressIndicator())
          else if (_grades.isNotEmpty)
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    "Average Quiz Grades",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                if (value.toInt() < averageGrades.length) {
                                  return Text(
                                    averageGrades.keys.elementAt(value.toInt()),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true,reservedSize: 40, interval: 20),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: averageGrades.entries.toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final value = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: value.value,
                                width: 16,
                                borderRadius: BorderRadius.circular(6),
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "All Grades",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _grades.length,
                    itemBuilder: (context, index) {
                      final g = _grades[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(g.feedback),
                          subtitle: Text('Student ID: ${g.id}'),
                          trailing: Text(
                            g.score.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          else
            const Center(child: Text("No grades available.")),
        ],
      ),
    ),
  );
}
}



