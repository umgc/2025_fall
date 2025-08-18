// Enhanced TestFileUploadWidget with completely isolated styling

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class TestFileUploadWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilesChanged;
  final String? assignmentId;

  const TestFileUploadWidget({
    super.key,
    required this.onFilesChanged,
    this.assignmentId,
  });

  @override
  State<TestFileUploadWidget> createState() => _TestFileUploadWidgetState();
}

class _TestFileUploadWidgetState extends State<TestFileUploadWidget> {
  PlatformFile? inputFile;
  PlatformFile? outputFile;
  String inputContent = '';
  String outputContent = '';
  bool isUploading = false;
  String? _currentAssignmentId;

  @override
  void initState() {
    super.initState();
    _currentAssignmentId = widget.assignmentId;
  }

  @override
  void didUpdateWidget(TestFileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if assignment changed
    if (oldWidget.assignmentId != widget.assignmentId) {
      print('🔄 TestFileUploadWidget: Assignment changed from ${oldWidget.assignmentId} to ${widget.assignmentId}');
      _resetForNewAssignment();
    }
  }

  // Reset widget state for new assignment
  void _resetForNewAssignment() {
    setState(() {
      inputFile = null;
      outputFile = null;
      inputContent = '';
      outputContent = '';
      isUploading = false;
      _currentAssignmentId = widget.assignmentId;
    });
    
    // Notify parent that files are cleared
    _notifyParent();
    
    print('🗑️ TestFileUploadWidget reset for assignment: ${widget.assignmentId}');
  }

  @override
  Widget build(BuildContext context) {
    // Only show changes when BOTH files are uploaded
    bool hasBothFiles = inputFile != null && outputFile != null;
    bool hasAnyFiles = inputFile != null || outputFile != null;
    
    return Theme(
      // Override all theme styling to prevent inheritance
      data: ThemeData(
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          elevation: 4,
        ),
      ),
      child: PopupMenuButton<String>(
        // Completely custom button with explicit styling
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tooltip: hasBothFiles ? 'Test Files Ready - Click to manage' : 'Upload Test Files',
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'input',
            child: Row(
              children: [
                Icon(
                  Icons.input,
                  size: 16,
                  color: inputFile != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Input File', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        inputFile?.name ?? 'No file selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: inputFile != null ? Colors.green : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (inputFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: () => _clearFile('input'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'output',
            child: Row(
              children: [
                Icon(
                  Icons.output,
                  size: 16,
                  color: outputFile != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Output File', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        outputFile?.name ?? 'No file selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: outputFile != null ? Colors.green : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (outputFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: () => _clearFile('output'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // Show detailed status indicator in popup
          PopupMenuItem<String>(
            value: 'status',
            enabled: false,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasBothFiles ? Colors.green[50] : 
                       hasAnyFiles ? Colors.orange[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    hasBothFiles ? Icons.check_circle : 
                    hasAnyFiles ? Icons.warning : Icons.info,
                    size: 16,
                    color: hasBothFiles ? Colors.green : 
                           hasAnyFiles ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasBothFiles ? 'Both files uploaded - ready for grading!' : 
                          hasAnyFiles ? 'Upload remaining file to enable grading' : 
                          'No test files uploaded',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasBothFiles ? Colors.green[700] : 
                                   hasAnyFiles ? Colors.orange[700] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasAnyFiles) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Progress: ${(inputFile != null ? 1 : 0) + (outputFile != null ? 1 : 0)}/2 files',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          if (hasAnyFiles)
            PopupMenuItem<String>(
              value: 'clear_all',
              child: Row(
                children: [
                  const Icon(Icons.clear_all, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Clear All Files',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          const PopupMenuItem<String>(
            value: 'help',
            child: Row(
              children: [
                Icon(Icons.help_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text('Help'),
              ],
            ),
          ),
        ],
        onSelected: (value) async {
          switch (value) {
            case 'input':
              await _pickFile('input');
              break;
            case 'output':
              await _pickFile('output');
              break;
            case 'clear_all':
              _clearAllFiles();
              break;
            case 'help':
              _showHelp();
              break;
            case 'status':
              // Do nothing - this is just for display
              break;
          }
        },
        // Completely custom button with explicit styling
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            // Explicitly control background - only green when both files present
            color: hasBothFiles ? Colors.green.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            // Explicit border to prevent any inherited styling
            border: Border.all(color: Colors.transparent, width: 0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.upload_file,
                size: 16,
                // Explicitly control icon color
                color: hasBothFiles ? Colors.green : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                hasBothFiles ? 'Ready' : 'Test Files',
                style: TextStyle(
                  fontSize: 12,
                  // Explicitly control text color
                  color: hasBothFiles ? Colors.green : Colors.white,
                  fontWeight: hasBothFiles ? FontWeight.bold : FontWeight.normal,
                  // Remove any inherited text styling
                  decoration: TextDecoration.none,
                ),
              ),
              // Only show indicator when both files uploaded
              if (hasBothFiles) ...[
                const SizedBox(width: 6),
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(String type) async {
    if (isUploading) return;
    
    try {
      setState(() {
        isUploading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'in', 'out'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        String content = '';
        if (file.bytes != null) {
          content = String.fromCharCodes(file.bytes!);
        } else {
          throw Exception('Could not read file content');
        }
        
        setState(() {
          if (type == 'input') {
            inputFile = file;
            inputContent = content;
          } else {
            outputFile = file;
            outputContent = content;
          }
        });

        // Notify parent component
        _notifyParent();
        
        // Better success messages
        String message;
        Color backgroundColor;
        
        if (inputFile != null && outputFile != null) {
          message = '✅ Both files uploaded - grading enabled!';
          backgroundColor = Colors.green;
        } else {
          message = '${type == 'input' ? 'Input' : 'Output'} file uploaded: ${file.name}';
          backgroundColor = Colors.orange;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  void _clearFile(String type) {
    setState(() {
      if (type == 'input') {
        inputFile = null;
        inputContent = '';
      } else {
        outputFile = null;
        outputContent = '';
      }
    });
    
    _notifyParent();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type == 'input' ? 'Input' : 'Output'} file cleared'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _clearAllFiles() {
    setState(() {
      inputFile = null;
      outputFile = null;
      inputContent = '';
      outputContent = '';
    });
    
    _notifyParent();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All test files cleared'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Test Files Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignment: ${widget.assignmentId ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Better help content with status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (inputFile != null && outputFile != null) ? Colors.green[50] : Colors.orange[50],
                border: Border.all(
                  color: (inputFile != null && outputFile != null) ? Colors.green[200]! : Colors.orange[200]!
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        (inputFile != null && outputFile != null) ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: (inputFile != null && outputFile != null) ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (inputFile != null && outputFile != null) ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Input file: ${inputFile?.name ?? 'Not uploaded'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: inputFile != null ? Colors.green[600] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Output file: ${outputFile?.name ?? 'Not uploaded'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: outputFile != null ? Colors.green[600] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            const Text(
              'Test files are used to automatically test student code:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• Input File: Contains the input data that will be passed to student programs'),
            const SizedBox(height: 8),
            const Text('• Output File: Contains the expected output that student programs should produce'),
            const SizedBox(height: 12),
            const Text(
              'Both files are required for automatic grading.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supported formats: .txt, .in, .out',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Test files are automatically cleared when switching assignments.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _notifyParent() {
    bool hasBothFiles = inputFile != null && outputFile != null;
    
    widget.onFilesChanged({
      'hasFiles': hasBothFiles, // Only true when both files are present
      'inputFile': inputFile,
      'outputFile': outputFile,
      'inputContent': inputContent,
      'outputContent': outputContent,
      'inputFilename': inputFile?.name,
      'outputFilename': outputFile?.name,
      'assignmentId': widget.assignmentId,
      // Additional status information
      'hasInputFile': inputFile != null,
      'hasOutputFile': outputFile != null,
      'filesReady': hasBothFiles,
    });
  }
}