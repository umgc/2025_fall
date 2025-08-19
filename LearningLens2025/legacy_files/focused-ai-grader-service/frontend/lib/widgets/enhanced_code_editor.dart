// lib/widgets/enhanced_code_editor.dart
// ENHANCED VERSION - Adds test input/output upload and validation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/code_execution_service.dart';

class EnhancedCodeEditor extends StatefulWidget {
  final String code;
  final String fileName;
  final String language;
  final bool isLoading;
  final String? assignmentId;
  final String? studentId;

  const EnhancedCodeEditor({
    super.key,
    required this.code,
    required this.fileName,
    required this.language,
    this.isLoading = false,
    this.assignmentId,
    this.studentId,
  });

  @override
  State<EnhancedCodeEditor> createState() => _EnhancedCodeEditorState();
}

class _EnhancedCodeEditorState extends State<EnhancedCodeEditor> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  bool _showLineNumbers = true;
  double _fontSize = 14.0;
  String _selectedTheme = 'dark';
  
  // Execution state
  bool _isExecuting = false;
  String? _executionOutput;
  String? _executionError;
  bool _showExecutionResult = false;
  
  // Test input/output state
  String? _testInput;
  String? _expectedOutput;
  String? _testInputFileName;
  String? _expectedOutputFileName;
  bool _showTestPanel = false;
  bool? _testPassed;
  String? _testFeedback;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Color _getColorForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return Colors.orange;
      case 'python':
        return Colors.blue;
      case 'javascript':
      case 'js':
        return Colors.yellow;
      case 'cpp':
      case 'c++':
        return Colors.purple;
      case 'c':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return Icons.coffee;
      case 'python':
        return Icons.code;
      case 'javascript':
      case 'js':
        return Icons.javascript;
      case 'cpp':
      case 'c++':
      case 'c':
        return Icons.memory;
      default:
        return Icons.description;
    }
  }

  List<String> _getCodeLines() {
    return widget.code.split('\n');
  }


  Future<void> _uploadTestInput() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'in', 'input'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _testInput = String.fromCharCodes(file.bytes!);
            _testInputFileName = file.name;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Test input uploaded: ${file.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to upload test input: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Upload expected output file
  Future<void> _uploadExpectedOutput() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'out', 'output', 'expected'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _expectedOutput = String.fromCharCodes(file.bytes!);
            _expectedOutputFileName = file.name;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Expected output uploaded: ${file.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to upload expected output: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Create test input manually
  void _createTestInputManually() {
    final TextEditingController inputController = TextEditingController(text: _testInput ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Test Input'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the input that will be passed to your program:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Examples:\n• For calculator: "2+2"\n• For user input: "John\\n25\\n"\n• For multiple values: "5\\n10\\n15"',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: inputController,
                  decoration: const InputDecoration(
                    labelText: 'Test Input',
                    border: OutlineInputBorder(),
                    hintText: 'Enter test input here...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _testInput = inputController.text;
                _testInputFileName = 'manual_input.txt';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Test input created'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Create expected output manually
  void _createExpectedOutputManually() {
    final TextEditingController outputController = TextEditingController(text: _expectedOutput ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Expected Output'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the expected output for your test input:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Examples:\n• For calculator input "2+2": "4"\n• For greeting: "Hello John!"\n• Multiple lines: "Result:\\n15"',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: outputController,
                  decoration: const InputDecoration(
                    labelText: 'Expected Output',
                    border: OutlineInputBorder(),
                    hintText: 'Enter expected output here...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _expectedOutput = outputController.text;
                _expectedOutputFileName = 'expected_output.txt';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Expected output created'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Compare actual output with expected output
  bool _compareOutputs(String actual, String expected) {
    // Normalize whitespace and line endings
    String normalizeString(String str) {
      return str.trim()
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .replaceAll(RegExp(r'\s+'), ' ');
    }
    
    final normalizedActual = normalizeString(actual);
    final normalizedExpected = normalizeString(expected);
    
    return normalizedActual == normalizedExpected;
  }

  /// Generate detailed test feedback
  String _generateTestFeedback(String actual, String expected, bool passed) {
    if (passed) {
      return '''✅ Test Passed!

Your program produced the expected output.

Expected: "$expected"
Actual: "$actual"

Great job! 🎉''';
    } else {
      // Calculate similarity for partial credit suggestions
      final actualLines = actual.split('\n');
      final expectedLines = expected.split('\n');
      
      String feedback = '''❌ Test Failed

Your program's output doesn't match the expected result.

Expected Output:
"$expected"

Actual Output:
"$actual"

''';

      // Provide specific suggestions based on differences
      if (actualLines.length != expectedLines.length) {
        feedback += '💡 Line Count Difference: Expected ${expectedLines.length} lines, got ${actualLines.length} lines.\n';
      }
      
      if (actual.trim().isEmpty) {
        feedback += '💡 No Output: Your program didn\'t produce any output. Check if you\'re printing results.\n';
      } else if (actual.contains(expected) || expected.contains(actual)) {
        feedback += '💡 Partial Match: Your output contains some correct elements but has extra or missing content.\n';
      } else {
        feedback += '💡 Different Output: The output format or content is different from expected.\n';
      }
      
      feedback += '\n🔧 Suggestions:\n';
      feedback += '• Check your print statements\n';
      feedback += '• Verify input processing logic\n';
      feedback += '• Test with the exact input provided\n';
      feedback += '• Check for extra spaces or newlines';
      
      return feedback;
    }
  }

  Widget _buildFileHeader() {
    return Container(
      height: 50,
      color: _selectedTheme == 'dark' ? const Color(0xFF2D3748) : Colors.grey.shade200,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getColorForLanguage(widget.language),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForLanguage(widget.language),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.language.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.fileName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _selectedTheme == 'dark' ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Test Input Button
          ElevatedButton.icon(
            onPressed: _showTestInputDialog,
            icon: Icon(
              Icons.input,
              size: 16,
              color: _testInput != null ? Colors.white : null,
            ),
            label: Text(
              'Test Input',
              style: TextStyle(
                fontSize: 12,
                color: _testInput != null ? Colors.white : null,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _testInput != null ? Colors.green : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 8),
          
          // Test Output Button
          ElevatedButton.icon(
            onPressed: _showTestOutputDialog,
            icon: Icon(
              Icons.output,
              size: 16,
              color: _expectedOutput != null ? Colors.white : null,
            ),
            label: Text(
              'Test Output',
              style: TextStyle(
                fontSize: 12,
                color: _expectedOutput != null ? Colors.white : null,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _expectedOutput != null ? Colors.blue : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 8),
          
          // Execute Code Button
          ElevatedButton.icon(
            onPressed: (widget.isLoading || _isExecuting) ? null : () => _executeCode(),
            icon: Icon(
              _isExecuting ? Icons.hourglass_empty : Icons.play_arrow,
              size: 16,
              color: (widget.isLoading || _isExecuting) ? null : Colors.white,
            ),
            label: Text(
              _isExecuting ? 'Running...' : 'Run',
              style: TextStyle(
                fontSize: 12,
                color: (widget.isLoading || _isExecuting) ? null : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: (widget.isLoading || _isExecuting) ? Colors.grey : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
          ),
          
          // Run with Test Button
          if (_testInput != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: (widget.isLoading || _isExecuting) ? null : () => _executeCodeWithTest(),
                icon: Icon(
                  _isExecuting ? Icons.hourglass_empty : Icons.quiz,
                  size: 16,
                  color: (widget.isLoading || _isExecuting) ? null : Colors.white,
                ),
                label: Text(
                  _isExecuting ? 'Testing...' : 'Test',
                  style: TextStyle(
                    fontSize: 12,
                    color: (widget.isLoading || _isExecuting) ? null : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (widget.isLoading || _isExecuting) ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          // Editor controls
          IconButton(
            icon: Icon(
              _showLineNumbers ? Icons.format_list_numbered : Icons.format_list_numbered_outlined,
              color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              setState(() {
                _showLineNumbers = !_showLineNumbers;
              });
            },
            tooltip: 'Toggle line numbers',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.text_fields,
              color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Font size',
            onSelected: (value) {
              setState(() {
                _fontSize = double.parse(value);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '12', child: Text('12px')),
              const PopupMenuItem(value: '14', child: Text('14px')),
              const PopupMenuItem(value: '16', child: Text('16px')),
              const PopupMenuItem(value: '18', child: Text('18px')),
              const PopupMenuItem(value: '20', child: Text('20px')),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.palette,
              color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Theme',
            onSelected: (value) {
              setState(() {
                _selectedTheme = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'dark', child: Text('Dark Theme')),
              const PopupMenuItem(value: 'light', child: Text('Light Theme')),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.copy,
              color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Copy code',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Show test input dialog
  void _showTestInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.input, color: Colors.green),
            SizedBox(width: 8),
            Text('Test Input'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure test input for your code:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Current test input display
              if (_testInput != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Test Input:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          _testInput!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _uploadTestInput();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _createTestInputManually();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Create Manual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_testInput != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _testInput = null;
                        _testInputFileName = null;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test input cleared'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Test Input'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show test output dialog
  void _showTestOutputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.output, color: Colors.blue),
            SizedBox(width: 8),
            Text('Expected Output'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure expected output for test validation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Current expected output display
              if (_expectedOutput != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Expected Output:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Text(
                          _expectedOutput!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _uploadExpectedOutput();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _createExpectedOutputManually();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Create Manual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_expectedOutput != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _expectedOutput = null;
                        _expectedOutputFileName = null;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expected output cleared'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Expected Output'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers(List<String> lines) {
    if (!_showLineNumbers) return const SizedBox.shrink();

    return Container(
      width: 60,
      color: _selectedTheme == 'dark' 
          ? const Color(0xFF1A202C) 
          : Colors.grey.shade100,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _verticalController,
              itemCount: lines.length,
              itemBuilder: (context, index) {
                return Container(
                  height: _fontSize * 1.5,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: _fontSize - 2,
                      color: _selectedTheme == 'dark' 
                          ? Colors.grey.shade500 
                          : Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _getTextStyleForLine(String line) {
    Color textColor = _selectedTheme == 'dark' ? Colors.white : Colors.black87;
    
    // Basic syntax highlighting
    if (line.trim().startsWith('//') || line.trim().startsWith('#')) {
      textColor = Colors.green; // Comments
    } else if (line.contains('import ') || line.contains('#include') || line.contains('from ')) {
      textColor = Colors.orange; // Imports
    } else if (line.contains('public ') || line.contains('private ') || line.contains('class ') || 
               line.contains('def ') || line.contains('function ')) {
      textColor = Colors.blue; // Keywords
    } else if (line.contains('"') || line.contains("'")) {
      textColor = Colors.yellow.shade700; // Strings
    }

    return TextStyle(
      fontSize: _fontSize,
      fontFamily: 'monospace',
      color: textColor,
      height: 1.5,
    );
  }

  Widget _buildCodeContent(List<String> lines) {
    if (widget.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _selectedTheme == 'dark' ? Colors.white : Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading file content...',
              style: TextStyle(
                color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: Container(
        color: _selectedTheme == 'dark' 
            ? const Color(0xFF1A202C) 
            : Colors.white,
        child: Scrollbar(
          controller: _horizontalController,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: Scrollbar(
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 2000, // Allow horizontal scrolling for long lines
                child: ListView.builder(
                  controller: _verticalController,
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    return Container(
                      height: _fontSize * 1.5,
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              line.isEmpty ? ' ' : line, // Show empty space for blank lines
                              style: _getTextStyleForLine(line),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final lines = _getCodeLines();
    return Container(
      height: 30,
      color: _selectedTheme == 'dark' 
          ? const Color(0xFF2D3748) 
          : Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Lines: ${lines.length}',
            style: TextStyle(
              fontSize: 12,
              color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Characters: ${widget.code.length}',
            style: TextStyle(
              fontSize: 12,
              color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
            ),
          ),
          if (_testInput != null) ...[
            const SizedBox(width: 16),
            Icon(
              Icons.input,
              size: 12,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Test Ready',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Font: ${_fontSize.toInt()}px',
            style: TextStyle(
              fontSize: 12,
              color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = _getCodeLines();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedTheme == 'dark' 
              ? Colors.grey.shade700 
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildFileHeader(),
          Expanded(
            child: Row(
              children: [
                _buildLineNumbers(lines),
                _buildCodeContent(lines),
              ],
            ),
          ),
          if (_showExecutionResult) _buildExecutionResult(),
          _buildStatusBar(),
        ],
      ),
    );
  }

  // Enhanced execution methods
  Future<void> _executeCode() async {
    setState(() {
      _isExecuting = true;
      _showExecutionResult = true;
      _executionOutput = null;
      _executionError = null;
      _testPassed = null;
      _testFeedback = null;
    });

    try {
      final language = CodeExecutionService.detectLanguageFromFilename(widget.fileName);
      
      print('🚀 Executing ${widget.fileName} as $language');
      
      final result = await CodeExecutionService.executeCode(
        language: language,
        code: widget.code,
        filename: widget.fileName,
        assignmentId: widget.assignmentId,
        studentId: widget.studentId,
        platform: 'focusedai-grading',
      );

      setState(() {
        _isExecuting = false;
        _executionOutput = result.output;
        _executionError = result.error;
      });

      if (!result.success && result.error.contains('not configured')) {
        _showConfigurationDialog();
      }

    } catch (e) {
      setState(() {
        _isExecuting = false;
        _executionError = 'Execution failed: $e';
      });
    }
  }

  Future<void> _executeCodeWithTest() async {
    setState(() {
      _isExecuting = true;
      _showExecutionResult = true;
      _executionOutput = null;
      _executionError = null;
      _testPassed = null;
      _testFeedback = null;
    });

    try {
      final language = CodeExecutionService.detectLanguageFromFilename(widget.fileName);
      
      print('🧪 Testing ${widget.fileName} as $language with input: $_testInput');
      
      final result = await CodeExecutionService.executeCodeWithInput(
        language: language,
        code: widget.code,
        filename: widget.fileName,
        input: _testInput!,
        assignmentId: widget.assignmentId,
        studentId: widget.studentId,
        platform: 'focusedai-grading',
      );

      setState(() {
        _isExecuting = false;
        _executionOutput = result.output;
        _executionError = result.error;
        
        // Perform test validation if expected output is available
        if (_expectedOutput != null && result.success) {
          _testPassed = _compareOutputs(result.output, _expectedOutput!);
          _testFeedback = _generateTestFeedback(result.output, _expectedOutput!, _testPassed!);
        }
      });

      if (!result.success && result.error.contains('not configured')) {
        _showConfigurationDialog();
      }

    } catch (e) {
      setState(() {
        _isExecuting = false;
        _executionError = 'Test execution failed: $e';
      });
    }
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend Configuration Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The code execution backend is not properly configured.'),
            SizedBox(height: 16),
            Text('Please ensure:'),
            Text('• Spring Boot backend is running on port 8080'),
            Text('• Lambda function URLs are configured'),
            Text('• CORS is properly set up'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionResult() {
    return Container(
      height: _testPassed != null ? 280 : 200,
      decoration: BoxDecoration(
        color: _selectedTheme == 'dark' ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: _selectedTheme == 'dark' ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        children: [
          // Execution result header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _selectedTheme == 'dark' ? const Color(0xFF2D3748) : Colors.grey.shade200,
            ),
            child: Row(
              children: [
                Icon(
                  _isExecuting ? Icons.hourglass_empty : 
                  (_executionError != null && _executionError!.isNotEmpty) ? Icons.error :
                  _testPassed == false ? Icons.warning :
                  _testPassed == true ? Icons.check_circle :
                  Icons.check_circle,
                  size: 16,
                  color: _isExecuting ? Colors.orange : 
                         (_executionError != null && _executionError!.isNotEmpty) ? Colors.red :
                         _testPassed == false ? Colors.orange :
                         _testPassed == true ? Colors.green :
                         Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _isExecuting ? 'Executing...' : 
                  _testPassed == true ? 'Test Passed ✅' :
                  _testPassed == false ? 'Test Failed ❌' :
                  'Execution Result',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedTheme == 'dark' ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: _selectedTheme == 'dark' ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _showExecutionResult = false;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Execution result content
          Expanded(
            child: _isExecuting
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Executing code...'),
                        SizedBox(height: 8),
                        Text(
                          'Container-based languages may take 10-30s on first run',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Test feedback (if available)
                        if (_testFeedback != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _testPassed == true ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _testPassed == true ? Colors.green.shade300 : Colors.orange.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Test Results:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _testPassed == true ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _testFeedback!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        if (_executionOutput != null && _executionOutput!.isNotEmpty) ...[
                          Text(
                            'Output:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedTheme == 'dark' ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              _executionOutput!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_executionError != null && _executionError!.isNotEmpty) ...[
                          Text(
                            'Error:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedTheme == 'dark' ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              _executionError!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}