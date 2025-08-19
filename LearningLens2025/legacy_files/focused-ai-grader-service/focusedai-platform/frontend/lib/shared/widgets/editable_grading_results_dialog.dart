// lib/shared/widgets/editable_grading_results_dialog.dart - Fixed version

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;
import '../../features/grading/providers/grading_provider.dart';
import '../../core/models/assignment.dart';
import '../../core/models/submission.dart';

class EditableGradingResultsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> gradingResults;
  final int successful;
  final int failed;
  final GradingProvider gradingProvider;
  final Function(List<Map<String, dynamic>>) onUploadSelected;
  final String? platform; // Add platform as optional parameter

  const EditableGradingResultsDialog({
    super.key,
    required this.gradingResults,
    required this.successful,
    required this.failed,
    required this.gradingProvider,
    required this.onUploadSelected,
    this.platform, // Optional platform parameter
  });

  @override
  State<EditableGradingResultsDialog> createState() => _EditableGradingResultsDialogState();
}

class _EditableGradingResultsDialogState extends State<EditableGradingResultsDialog> {
  late List<Map<String, dynamic>> _editableResults;
  final Map<String, TextEditingController> _gradeControllers = {};
  final Map<String, bool> _selectedForUpload = {};
  bool _selectAll = true;

  @override
  void initState() {
    super.initState();
    _editableResults = List<Map<String, dynamic>>.from(widget.gradingResults);
    
    // Initialize controllers and selection state
    for (int i = 0; i < _editableResults.length; i++) {
      final result = _editableResults[i];
      final submission = result['submission'] as Submission;
      final submissionId = submission.id;
      
      // Initialize grade controller with current grade (formatted to 2 decimal places)
      final currentGrade = result['outputSimilarity'] ?? 0;
      final formattedGrade = double.parse(currentGrade.toStringAsFixed(2));
      _gradeControllers[submissionId] = TextEditingController(
        text: formattedGrade.toString()
      );
      
      // Select successful grades by default
      _selectedForUpload[submissionId] = result['success'] != false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedForUpload.values.where((selected) => selected).length;
    
    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with improved typography
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Review and Edit Grades',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Summary with improved styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${widget.successful}',
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.green,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const Text(
                          'Successful',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.failed > 0)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${widget.failed}',
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.red,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const Text(
                            'Failed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$selectedCount',
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.blue,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selection controls with improved typography
            Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: (value) {
                    setState(() {
                      _selectAll = value ?? false;
                      for (final key in _selectedForUpload.keys) {
                        _selectedForUpload[key] = _selectAll;
                      }
                    });
                  },
                ),
                const Text(
                  'Select All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _resetAllGrades,
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text(
                    'Reset All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _applyGradeToAll,
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text(
                    'Apply Grade to All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Platform notice with improved styling - Fixed to use widget.platform
            if (_isGooglePlatform()) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Uploading to ${_getPlatformDisplayName()}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Results list header with improved typography
            const Text(
              'Individual Results:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            
            // Results table with improved styling
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header row with improved typography
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'Select',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Student',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Auto Grade',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Edit Grade',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Similarity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _editableResults.length,
                        itemBuilder: (context, index) => _buildEditableResultRow(index),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons with improved typography
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _downloadCSV,
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'Download CSV',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedCount > 0 ? _uploadSelectedGrades : null,
                    icon: Icon(_getUploadIcon()),
                    label: Text(
                      'Upload $selectedCount Grades',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for platform detection
  bool _isGooglePlatform() {
    if (widget.platform == null) return false;
    final platform = widget.platform!.toLowerCase();
    return platform == 'google' || 
           platform == 'google_classroom' || 
           platform == 'classroom';
  }

  String _getPlatformDisplayName() {
    if (widget.platform == null) return 'Unknown Platform';
    final platform = widget.platform!.toLowerCase();
    switch (platform) {
      case 'google':
      case 'google_classroom':
      case 'classroom':
        return 'Google Classroom';
      case 'canvas':
        return 'Canvas';
      case 'blackboard':
        return 'Blackboard';
      case 'moodle':
        return 'Moodle';
      default:
        return widget.platform!;
    }
  }

  IconData _getUploadIcon() {
    if (widget.platform == null) return Icons.upload;
    final platform = widget.platform!.toLowerCase();
    switch (platform) {
      case 'google':
      case 'google_classroom':
      case 'classroom':
        return Icons.school;
      case 'canvas':
        return Icons.art_track;
      default:
        return Icons.upload;
    }
  }

  Widget _buildEditableResultRow(int index) {
    final result = _editableResults[index];
    final submission = result['submission'] as Submission;
    final submissionId = submission.id;
    final success = result['success'] ?? true;
    final autoGrade = result['grade'] ?? 'F';
    final similarity = result['outputSimilarity'] ?? 0;
    final isSelected = _selectedForUpload[submissionId] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: isSelected ? Colors.blue[25] : null,
      ),
      child: Row(
        children: [
          // Selection checkbox
          SizedBox(
            width: 40,
            child: Checkbox(
              value: isSelected,
              onChanged: success ? (value) {
                setState(() {
                  _selectedForUpload[submissionId] = value ?? false;
                  _selectAll = _selectedForUpload.values.every((selected) => selected);
                });
              } : null,
            ),
          ),
          const SizedBox(width: 16),
          
          // Student name with improved typography
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
                if (!success)
                  Text(
                    'Error: ${result['error'] ?? 'Unknown error'}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          
          // Auto grade display
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: success ? _getGradeColor(autoGrade) : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  success ? autoGrade : '✗',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          
          // Editable grade with improved input styling
          SizedBox(
            width: 100,
            child: success ? TextField(
              controller: _gradeControllers[submissionId],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(),
                suffixText: '%',
                suffixStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (value) => _updateGrade(submissionId, value),
            ) : const Text(
              'N/A',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Similarity with improved typography
          SizedBox(
            width: 80,
            child: success ? Text(
              '${similarity.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getSimilarityColor(similarity.toDouble()),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Roboto',
              ),
            ) : const Text(
              'N/A',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Status
          SizedBox(
            width: 60,
            child: Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
  
  void _updateGrade(String submissionId, String value) {
    // Find the result and update it
    for (var result in _editableResults) {
      final submission = result['submission'] as Submission;
      if (submission.id == submissionId) {
        final grade = double.tryParse(value) ?? 0;
        final formattedGrade = double.parse(grade.toStringAsFixed(2));
        result['editedGrade'] = formattedGrade;
        result['outputSimilarity'] = formattedGrade;
        break;
      }
    }
  }

  void _resetAllGrades() {
    for (var result in _editableResults) {
      final submission = result['submission'] as Submission;
      final originalGrade = result['originalGrade'] ?? result['outputSimilarity'] ?? 0;
      final formattedGrade = double.parse(originalGrade.toStringAsFixed(2));
      _gradeControllers[submission.id]?.text = formattedGrade.toString();
      result['editedGrade'] = formattedGrade;
      result['outputSimilarity'] = formattedGrade;
    }
    setState(() {});
  }

  void _applyGradeToAll() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Apply Grade to All'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Grade (%)',
              border: OutlineInputBorder(),
              suffixText: '%',
              helperText: 'Enter grade (0-100)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final grade = double.tryParse(controller.text) ?? 0;
                final formattedGrade = double.parse(grade.toStringAsFixed(2));
                for (var result in _editableResults) {
                  if (result['success'] != false) {
                    final submission = result['submission'] as Submission;
                    _gradeControllers[submission.id]?.text = formattedGrade.toString();
                    result['editedGrade'] = formattedGrade;
                    result['outputSimilarity'] = formattedGrade;
                  }
                }
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _downloadCSV() async {
    try {
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        [
          'Student Name',
          'Student ID', 
          'Submission ID',
          'Auto Grade (%)',
          'Edited Grade (%)',
          'Letter Grade',
          'Similarity (%)',
          'Status',
          'Selected for Upload',
          'Assignment',
          'Graded Date'
        ],
      ];
      
      for (final result in _editableResults) {
        final submission = result['submission'] as Submission;
        final assignment = result['assignment'] as Assignment?;
        final success = result['success'] ?? true;
        final autoGrade = result['originalGrade'] ?? result['outputSimilarity'] ?? 0;
        final editedGrade = result['editedGrade'] ?? autoGrade;
        final similarity = result['outputSimilarity'] ?? 0;
        final isSelected = _selectedForUpload[submission.id] ?? false;
        
        final formattedAutoGrade = double.parse(autoGrade.toStringAsFixed(2));
        final formattedEditedGrade = double.parse(editedGrade.toStringAsFixed(2));
        final formattedSimilarity = double.parse(similarity.toStringAsFixed(2));
        
        csvData.add([
          submission.studentName,
          submission.studentId,
          submission.id,
          formattedAutoGrade,
          formattedEditedGrade,
          _calculateLetterGrade(formattedEditedGrade),
          formattedSimilarity,
          success ? 'Success' : 'Failed',
          isSelected ? 'Yes' : 'No',
          assignment?.name ?? 'Unknown Assignment',
          DateTime.now().toIso8601String(),
        ]);
      }
      
      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      
      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'grading_results_$timestamp.csv';
      
      if (kIsWeb) {
        // Web-specific download
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        
        html.Url.revokeObjectUrl(url);
        
        print('✅ Web CSV download completed: $fileName');
      } else {
        // Mobile/Desktop download
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Grading Results CSV',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          print('✅ CSV saved to: $outputFile');
        } else {
          print('❌ CSV save cancelled by user');
          return;
        }
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done, color: Colors.white),
                const SizedBox(width: 8),
                Text('CSV downloaded: $fileName'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ CSV download failed: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to download CSV: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _calculateLetterGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  void _uploadSelectedGrades() {
    final selectedResults = _editableResults.where((result) {
      final submission = result['submission'] as Submission;
      return _selectedForUpload[submission.id] == true;
    }).toList();
    
    Navigator.of(context).pop();
    widget.onUploadSelected(selectedResults);
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
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

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 90) return Colors.green[600]!;
    if (similarity >= 80) return Colors.lightGreen[600]!;
    if (similarity >= 70) return Colors.yellow[700]!;
    if (similarity >= 60) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  @override
  void dispose() {
    for (var controller in _gradeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}