import 'package:flutter/material.dart';
import '../components/app_navbar.dart';
import '../components/dashboard_button.dart';
import '../constants/app_strings.dart';
import '../constants/app_routes.dart';
import '../models/course.dart';
import '../models/user.dart';
import 'student_assignment_screen.dart';
import 'student_chat_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String? authToken;
  final User? user;
  final List<Course>? courses;

  const StudentDashboard({
    super.key,
    this.authToken,
    this.user,
    this.courses,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<Course> availableCourses = [];
  Course? selectedCourse;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCourses();
  }

  void _initializeCourses() {
    if (widget.courses != null) {
      setState(() {
        availableCourses = widget.courses!;
        if (availableCourses.isNotEmpty) {
          selectedCourse = availableCourses.first;
        }
      });
    }
  }

  void _navigateToAssignments() {
    if (selectedCourse == null) {
      _showMessage('Please select a course first', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAssignmentScreen(
          authToken: widget.authToken,
          course: selectedCourse!,
          user: widget.user,
        ),
      ),
    );
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentChatScreen(
          authToken: widget.authToken,
          course: selectedCourse,
          user: widget.user,
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavbar(
        title: '🎓 Student Dashboard',
        actions: [
          if (widget.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    widget.user!.platform == 'google' ? Icons.class_ : Icons.account_balance,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.user!.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.authToken == null) ...[
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              _buildConnectPrompt(),
            ] else ...[
              _buildUserInfoSection(),
              const SizedBox(height: 20),
              _buildCourseSelectionSection(),
              const SizedBox(height: 20),
              _buildActionsSection(),
            ],
            
            if (errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Welcome to CAILA',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Connect to your Learning Management System to access your courses and get personalized help with assignments.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('Access your real courses and assignments'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('Get contextual help from CAILA AI'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('Conversations logged for teacher review'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectPrompt() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Authentication Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please authenticate through your institution\'s login system to access CAILA.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.user!.platform == 'google' ? Colors.blue[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                widget.user!.platform == 'google' ? Icons.class_ : Icons.account_balance,
                color: widget.user!.platform == 'google' ? Colors.blue : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected to ${widget.user!.platform.toUpperCase()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.user!.name,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${availableCourses.length} courses available',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSelectionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Courses',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (availableCourses.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'No courses found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              DropdownButtonFormField<Course>(
                value: selectedCourse,
                decoration: const InputDecoration(
                  labelText: 'Select Course',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                items: availableCourses.map((course) {
                  return DropdownMenuItem<Course>(
                    value: course,
                    child: Text(course.name),
                  );
                }).toList(),
                onChanged: (course) {
                  setState(() {
                    selectedCourse = course;
                  });
                },
              ),
              
              if (selectedCourse != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected: ${selectedCourse!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        // Course-specific actions
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Actions',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                DashboardButton(
                  title: selectedCourse != null 
                      ? 'Work on ${selectedCourse!.name} Assignments'
                      : 'Select a course to view assignments',
                  subtitle: 'View and complete assignments with CAILA\'s help',
                  icon: Icons.assignment,
                  backgroundColor: Colors.green,
                  onPressed: selectedCourse != null ? _navigateToAssignments : null,
                  isEnabled: selectedCourse != null,
                  width: double.infinity,
                ),
                
                const SizedBox(height: 12),
                
                DashboardButton(
                  title: selectedCourse != null 
                      ? 'View Chat History - ${selectedCourse!.name}'
                      : 'Select a course to view chat history',
                  subtitle: 'Review your conversations with CAILA',
                  icon: Icons.history,
                  backgroundColor: Colors.indigo,
                  onPressed: selectedCourse != null ? () => _navigateToChat() : null,
                  isEnabled: selectedCourse != null,
                  width: double.infinity,
                ),
                
                if (selectedCourse == null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select a course above to access assignments and chat with CAILA',
                            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // General actions
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'General Actions',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                DashboardButton(
                  title: 'Chat with CAILA (General)',
                  subtitle: 'General conversation with AI assistant',
                  icon: Icons.chat,
                  backgroundColor: Colors.purple,
                  onPressed: _navigateToChat,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(errorMessage!)),
        ],
      ),
    );
  }
}