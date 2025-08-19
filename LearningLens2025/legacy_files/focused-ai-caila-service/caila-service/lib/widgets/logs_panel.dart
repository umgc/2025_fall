import 'package:flutter/material.dart';
import '../models/course.dart';

class LogsPanel extends StatefulWidget {
  final String? authToken;
  final List<Course> courses;
  final String? selectedCourseId;
  final Function(String) onCourseSelected;

  const LogsPanel({
    super.key,
    this.authToken,
    required this.courses,
    this.selectedCourseId,
    required this.onCourseSelected,
  });

  @override
  State<LogsPanel> createState() => _LogsPanelState();
}

class _LogsPanelState extends State<LogsPanel> {
  List<Map<String, dynamic>> chatLogs = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCourseId != null) {
      _loadChatLogs();
    }
  }

  @override
  void didUpdateWidget(LogsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCourseId != oldWidget.selectedCourseId) {
      if (widget.selectedCourseId != null) {
        _loadChatLogs();
      } else {
        setState(() {
          chatLogs = [];
          errorMessage = null;
        });
      }
    }
  }

  Future<void> _loadChatLogs() async {
    if (widget.authToken == null || widget.selectedCourseId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // This would be implemented based on the platform
      // For now, we'll use a placeholder
      setState(() {
        chatLogs = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Chat Logs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: widget.selectedCourseId,
                decoration: const InputDecoration(
                  labelText: 'Select Course',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: widget.courses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course.id,
                    child: Text(course.name),
                  );
                }).toList(),
                onChanged: (courseId) {
                  if (courseId != null) {
                    widget.onCourseSelected(courseId);
                  }
                },
              ),
            ],
          ),
        ),
        
        // Logs content
        Expanded(
          child: _buildLogsContent(),
        ),
      ],
    );
  }

  Widget _buildLogsContent() {
    if (widget.selectedCourseId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a course to view student chat logs',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chat logs...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading chat logs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChatLogs,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chatLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chat logs found for this course',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Students haven\'t used CAILA yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatLogs.length,
      itemBuilder: (context, index) {
        final log = chatLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                (log['studentName'] ?? 'S')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(log['studentName'] ?? 'Unknown Student'),
            subtitle: Text(
              '${log['messageCount'] ?? 0} messages • ${log['lastActivity'] ?? 'Unknown'}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle log detail view
            },
          ),
        );
      },
    );
  }
}