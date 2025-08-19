import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/participant.dart';
import '../services/analytics_services.dart';

class StudentChart extends StatefulWidget {
  final int courseId;
  final int assessmentId;

  const StudentChart({super.key, required this.courseId, required this.assessmentId});

  @override
  State<StudentChart> createState() => _StudentChartState();
}

class _StudentChartState extends State<StudentChart> {
  late Future<List<Participant>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = AnalyticsService().getStudentReport(widget.courseId, widget.assessmentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Participant>>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final students = snapshot.data!;
          return BarChart(
            BarChartData(
              barGroups: students.asMap().entries.map((entry) {
                int x = entry.key;
                double y = entry.value.score;
                return BarChartGroupData(x: x, barRods: [
                  BarChartRodData(toY: y, width: 20),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      return Text(students[index].name, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error loading report');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}