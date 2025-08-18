import 'package:flutter/material.dart';
import 'package:focused_ai_ui/models/assignment.dart';
import 'package:focused_ai_ui/models/course.dart';
import 'package:focused_ai_ui/models/submission.dart';
import 'package:focused_ai_ui/screens/teacher_home_screen.dart';
import 'package:focused_ai_ui/services/grader_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GraderScreen extends StatefulWidget {
  const GraderScreen({super.key});

  @override
  State<GraderScreen> createState() => _GraderScreenState();
}

class _GraderScreenState extends State<GraderScreen> {
  bool _isSidebarCollapsed = false;
  String? selectedCourseId;
  int selectedAssignmentIndex = 0;
  Submission? selectedSubmission;

  List<Course> courses = [];
  List<Assignment> assignments = [];
  List<Submission> submissions = [];

  bool isLoadingCourses = true;
  bool isLoadingAssignments = false;
  bool isLoadingSubmissions = false;

  String submissionContent = '';

  TextEditingController gradeController = TextEditingController();
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    try {
      final fetchedCourses = await GraderService.fetchCourses();
      setState(() {
        courses = fetchedCourses;
        selectedCourseId = courses.isNotEmpty ? courses[0].id : null;
        isLoadingCourses = false;
      });
      if (selectedCourseId != null) {
        await fetchAssignments(selectedCourseId!);
      }
    } catch (e) {
      print('Error fetching courses: $e');
      setState(() => isLoadingCourses = false);
    }
  }

  Future<void> fetchAssignments(String courseId) async {
    setState(() => isLoadingAssignments = true);
    try {
      final fetchedAssignments = await GraderService.fetchAssignments(courseId);
      setState(() {
        assignments = fetchedAssignments;
        selectedAssignmentIndex = 0;
      });
      if (fetchedAssignments.isNotEmpty) {
        await fetchSubmissions();
      }
    } catch (e) {
      print('Error fetching assignments: $e');
    } finally {
      setState(() => isLoadingAssignments = false);
    }
  }

  Future<void> fetchSubmissions() async {
    if (selectedCourseId == null || assignments.isEmpty) return;
    final assignmentId = assignments[selectedAssignmentIndex].id;

    setState(() => isLoadingSubmissions = true);
    try {
      final fetchedSubmissions = await GraderService.fetchSubmissions(selectedCourseId!, assignmentId);
      setState(() {
        submissions = fetchedSubmissions;
        selectedSubmission = submissions.isNotEmpty ? submissions[0] : null;
      });
      await fetchSubmissionContent();
    } catch (e) {
      print('Error fetching submissions: $e');
    } finally {
      setState(() => isLoadingSubmissions = false);
    }
  }

  Future<void> fetchSubmissionContent() async {
    if (selectedCourseId == null || assignments.isEmpty || selectedSubmission == null) return;
    try {
      final courseworkId = assignments[selectedAssignmentIndex].id;
      final result = await GraderService.fetchSubmissionText(
        selectedCourseId!,
        courseworkId,
        selectedSubmission!.studentId,
      );
      setState(() {
        submissionContent = result;
      });
    } catch (e) {
      print('Error fetching parsed submission text: $e');
      setState(() => submissionContent = 'Failed to load submission.');
    }
  }

  Future<void> _launchRubric() async {
    if (selectedCourseId == null || assignments.isEmpty) return;
    final courseworkId = assignments[selectedAssignmentIndex].id;
    try {
      final link = await GraderService.fetchRubricLink(selectedCourseId!, courseworkId);
      final uri = Uri.tryParse(link);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Invalid or inaccessible URL");
      }
    } catch (e) {
      print('Error opening rubric: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open rubric link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 233, 233),
      appBar: AppBar(
        title: const Text('FocusEd AI'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.lightGreen.shade300, const Color(0xFFADD8E6)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Row(
        children: [
          SizedBox(
            width: _isSidebarCollapsed ? 60 : 250,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(_isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left),
                      onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                    ),
                  ),
                  if (!_isSidebarCollapsed) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Course:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isLoadingCourses
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                              value: selectedCourseId,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedCourseId = val;
                                    selectedAssignmentIndex = 0;
                                    selectedSubmission = null;
                                  });
                                  fetchAssignments(val);
                                }
                              },
                            ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Assignments:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isLoadingAssignments
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<int>(
                              value: selectedAssignmentIndex,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: assignments.asMap().entries.map((entry) {
                                return DropdownMenuItem(value: entry.key, child: Text(entry.value.name));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedAssignmentIndex = val;
                                    selectedSubmission = null;
                                  });
                                  fetchSubmissions();
                                }
                              },
                            ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Submissions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isLoadingSubmissions
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<Submission>(
                              value: selectedSubmission,
                              hint: const Text('Select submission'),
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: submissions.map((s) {
                                return DropdownMenuItem<Submission>(
                                  value: s,
                                  child: Text(s.studentName, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => selectedSubmission = val);
                                fetchSubmissionContent();
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_mode),
                        label: const Text("GRADE ALL"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () async {
                          if (selectedCourseId == null || assignments.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a course and assignment first.')),
                            );
                            return;
                          }

                          final courseId = selectedCourseId!;
                          final assignmentId = assignments[selectedAssignmentIndex].id;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 20),
                                  Text("Grading all submissions..."),
                                ],
                              ),
                            ),
                          );

                          try {
                            final failures = await GraderService.gradeAllSubmissions(courseId, assignmentId);
                            Navigator.pop(context);

                            if (failures.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("✅ All submissions graded successfully!")),
                              );
                            } else {
                              final errorMessage = "⚠️ Some submissions failed:\n${failures.join("\n• ")}";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  duration: const Duration(seconds: 6),
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            print('❌ Error grading all: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error grading all submissions.")),
                            );
                          }
                        },
                      ),
                    ),

                  ]
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  isLoadingSubmissions ? 'Loading...' : submissionContent,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rubric:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _launchRubric,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Attached Rubric'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const Divider(height: 15, thickness: 1),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedCourseId == null || assignments.isEmpty || selectedSubmission == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select course, assignment, and submission.')),
                        );
                        return;
                      }
                      final courseId = selectedCourseId!;
                      final courseworkId = assignments[selectedAssignmentIndex].id;
                      final userId = selectedSubmission!.studentId;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Grading in progress..."),
                            ],
                          ),
                        ),
                      );

                      try {
                        final result = await GraderService.gradeStudentSubmission(
                          courseId: courseId,
                          assignmentId: courseworkId,
                          userId: userId,
                        );
                        setState(() {
                          gradeController.text = result['grade'] ?? '';
                          commentController.text = result['comments'] ?? '';
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Grading complete!')),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        print('❌ Error grading submission: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to grade submission.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                    child: const Text('GRADE'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Report:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: gradeController,
                    decoration: const InputDecoration(labelText: 'Grade (%)'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: TextField(
                      controller: commentController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedCourseId == null ||
                          assignments.isEmpty ||
                          selectedSubmission == null ||
                          gradeController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields before submitting.')),
                        );
                        return;
                      }

                      try {
                        await GraderService.submitGradeAndComments(
                          courseId: selectedCourseId!,
                          assignmentId: assignments[selectedAssignmentIndex].id,
                          submissionId: selectedSubmission!.id,
                          grade: int.parse(gradeController.text),
                          comments: commentController.text,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submitted to Google Classroom!')),
                        );
                      } catch (e) {
                        print('❌ Submission failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submission failed.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('SUBMIT'),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
