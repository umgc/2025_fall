import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../models/submission.dart';

class SubmissionPanel extends StatefulWidget {
  final Assignment? selectedAssignment;
  final Function(Assignment) onAssignmentSelected;
  final List<Assignment> assignments;

  const SubmissionPanel({
    super.key,
    this.selectedAssignment,
    required this.onAssignmentSelected,
    required this.assignments,
  });

  @override
  State<SubmissionPanel> createState() => _SubmissionPanelState();
}

class _SubmissionPanelState extends State<SubmissionPanel> {
  List<Submission> submissions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedAssignment != null) {
      _loadSubmissions();
    }
  }

  @override
  void didUpdateWidget(SubmissionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAssignment?.id != oldWidget.selectedAssignment?.id) {
      if (widget.selectedAssignment != null) {
        _loadSubmissions();
      } else {
        setState(() {
          submissions = [];
        });
      }
    }
  }

  Future<void> _loadSubmissions() async {
    if (widget.selectedAssignment == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // This would be implemented to load actual submissions
      // For now, we'll use placeholder data
      setState(() {
        submissions = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assignment selector
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
                'Student Submissions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Assignment>(
                value: widget.selectedAssignment,
                decoration: const InputDecoration(
                  labelText: 'Select Assignment',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: widget.assignments.map((assignment) {
                  return DropdownMenuItem<Assignment>(
                    value: assignment,
                    child: Text(assignment.name),
                  );
                }).toList(),
                onChanged: (assignment) {
                  if (assignment != null) {
                    widget.onAssignmentSelected(assignment);
                  }
                },
              ),
            ],
          ),
        ),
        
        // Submissions content
        Expanded(
          child: _buildSubmissionsContent(),
        ),
      ],
    );
  }

  Widget _buildSubmissionsContent() {
    if (widget.selectedAssignment == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select an assignment to view submissions',
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
            Text('Loading submissions...'),
          ],
        ),
      );
    }

    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No submissions for ${widget.selectedAssignment!.name}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(submission.status),
              child: Text(
                submission.studentName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(submission.studentName),
            subtitle: Text(
              'Submitted: ${_formatDate(submission.submittedAt)} • ${submission.files.length} files',
            ),
            trailing: Chip(
              label: Text(
                submission.status,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _getStatusColor(submission.status).withOpacity(0.2),
            ),
            onTap: () {
              // Handle submission detail view
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'missing':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}