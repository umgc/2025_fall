// lib/features/grading/widgets/submission_list_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/submission.dart';
import '../providers/grading_provider.dart';

class SubmissionListPanel extends StatelessWidget {
  const SubmissionListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GradingProvider>(
      builder: (context, gradingProvider, child) {
        if (gradingProvider.isLoading) {
          return _buildLoadingWidget();
        }
        
        if (gradingProvider.submissions.isEmpty) {
          return _buildEmptyWidget();
        }
        
        return _buildSubmissionsList(gradingProvider);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Loading submissions...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'No submissions',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select an assignment to view submissions',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList(GradingProvider gradingProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: gradingProvider.submissions.length,
      itemBuilder: (context, index) {
        final submission = gradingProvider.submissions[index];
        final isSelected = gradingProvider.selectedSubmission?.id == submission.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildSubmissionCard(submission, isSelected, gradingProvider),
        );
      },
    );
  }

  Widget _buildSubmissionCard(Submission submission, bool isSelected, GradingProvider gradingProvider) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => gradingProvider.selectSubmission(submission),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      submission.studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? Colors.blue[800] : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusIndicator(submission),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // File info
              Row(
                children: [
                  Icon(
                    submission.files.length > 1 ? Icons.folder : Icons.description,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      submission.files.length > 1 
                          ? '${submission.files.length} files'
                          : submission.files.isNotEmpty 
                            ? submission.files.first.filename
                            : 'No files',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Language and submission time
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getLanguageColor(submission.primaryLanguage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      submission.primaryLanguage.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getLanguageColor(submission.primaryLanguage),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(submission.submittedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              
              // Grade if available
              if (submission.grade != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(submission.grade!.letterGrade),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Grade: ${submission.grade!.letterGrade} (${submission.grade!.percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Submission submission) {
    Color statusColor;
    IconData statusIcon;
    
    if (submission.grade != null) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      switch (submission.status.toLowerCase()) {
        case 'submitted':
          statusColor = Colors.blue;
          statusIcon = Icons.assignment_turned_in;
          break;
        case 'graded':
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case 'draft':
          statusColor = Colors.orange;
          statusIcon = Icons.edit;
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.help_outline;
      }
    }
    
    return Icon(
      statusIcon,
      size: 16,
      color: statusColor,
    );
  }

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return Colors.orange[700]!;
      case 'python':
        return Colors.blue[700]!;
      case 'javascript':
      case 'js':
        return Colors.yellow[700]!;
      case 'cpp':
      case 'c++':
        return Colors.indigo[700]!;
      case 'c':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getGradeColor(String letterGrade) {
    switch (letterGrade.toUpperCase()) {
      case 'A':
        return Colors.green[600]!;
      case 'B':
        return Colors.lightGreen[600]!;
      case 'C':
        return Colors.yellow[700]!;
      case 'D':
        return Colors.orange[600]!;
      case 'F':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}