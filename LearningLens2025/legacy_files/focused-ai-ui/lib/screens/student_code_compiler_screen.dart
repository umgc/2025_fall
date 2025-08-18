import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/cpp.dart';
import 'dart:convert';
import 'dart:io';

import '../services/auth_service.dart';
import '../services/code_execution_service.dart';
import '../screens/student_home_screen.dart';
import '../models/code_file.dart';

class StudentCodeCompilerScreen extends StatefulWidget {
  const StudentCodeCompilerScreen({super.key});

  @override
  State<StudentCodeCompilerScreen> createState() => _StudentCodeCompilerScreenState();
}

class _StudentCodeCompilerScreenState extends State<StudentCodeCompilerScreen> 
    with TickerProviderStateMixin {
  
  final CodeExecutionService _codeExecutionService = CodeExecutionService();
  
  final Map<String, Mode> _languageModes = {
    'java': java,
    'javascript': javascript,
    'python': python,
    'cpp': cpp,
  };

  final Map<String, IconData> _languageIcons = {
    'java': Icons.coffee,
    'javascript': Icons.javascript,
    'python': Icons.code,
    'cpp': Icons.code_outlined,
  };

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _mainClassNameController = TextEditingController();

  Map<String, CodeController> _controllers = {};
  String? _activeFileName;
  List<PlatformFile> _selectedFiles = [];
  PlatformFile? _activeFile;

  String _output = "Welcome to Code Compiler\nReady to execute your code...";
  String _selectedLanguage = 'java';
  bool _isCodeEditorReady = false;
  bool _isExecuting = false;
  late AnimationController _animationController;
  bool _isDarkMode = false;

  final List<String> _supportedLanguages = ['java', 'javascript', 'python', 'cpp'];

  @override
  void initState() {
    super.initState();
    _mainClassNameController.text = "HelloWorld";
    _mainClassNameController.addListener(_handleMainNameChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeCodeEditor();
  }

  @override
  void dispose() {
    _mainClassNameController.removeListener(_handleMainNameChange);
    
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    
    _mainClassNameController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeCodeEditor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final baseName = _getDefaultMainName(_selectedLanguage);
        final extension = _getExtensionsForLanguage(_selectedLanguage).first;
        final defaultFileName = '$baseName.$extension';

        setState(() {
          _activeFileName = defaultFileName;
          _controllers[defaultFileName] = CodeController(
            text: _getDefaultCodeForLanguage(_selectedLanguage),
            language: _languageModes[_selectedLanguage]!,
          );
          _mainClassNameController.text = baseName;
          _isCodeEditorReady = true;
        });
      }
    });
  }

  String _getDefaultCodeForLanguage(String language) {
    switch (language) {
      case 'java':
        return '''public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}''';
      case 'javascript':
        return '''console.log("Hello, World!");

// Your JavaScript code here
function greet(name) {
    return `Hello, \${name}!`;
}

console.log(greet("Developer"));''';
      case 'python':
        return '''print("Hello, World!")

# Your Python code here
def greet(name):
    return f"Hello, {name}!"

print(greet("Developer"))''';
      case 'cpp':
        return '''#include <iostream>
using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    return 0;
}''';
      default:
        return '';
    }
  }

  String _getDefaultMainName(String language) {
    switch (language) {
      case 'java': return 'HelloWorld';
      case 'javascript': return 'main';
      case 'python': return 'main';
      case 'cpp': return 'main';
      default: return 'main';
    }
  }

  List<String> _getExtensionsForLanguage(String lang) {
    switch (lang) {
      case 'java': return ['java'];
      case 'javascript': return ['js'];
      case 'python': return ['py'];
      case 'cpp': return ['cpp'];
      default: return ['txt'];
    }
  }

  IconData _getFileIcon(String filename) {
    if (filename.endsWith('.java')) return Icons.coffee;
    if (filename.endsWith('.js')) return Icons.javascript;
    if (filename.endsWith('.py')) return Icons.code;
    if (filename.endsWith('.cpp')) return Icons.code_outlined;
    return Icons.description;
  }

  void _removeTab(String filename) {
    final controller = _controllers.remove(filename);
    controller?.dispose();

    setState(() {
      if (_controllers.isEmpty) {
        _activeFileName = null;
        _output = "📂 All files closed. Use 'New File' or 'Open File' to start again.";
        _isCodeEditorReady = false;
      } else {
        _activeFileName = _controllers.keys.first;
        _mainClassNameController.text = _activeFileName!.split('.').first;
      }
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _selectedLanguage == 'java'
            ? ['java']
            : _selectedLanguage == 'javascript'
                ? ['js']
                : _selectedLanguage == 'python'
                    ? ['py']
                    : ['cpp'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
          _activeFile = result.files.first;
          _activeFileName = _activeFile!.name;
          _output = "📁 Loading ${_selectedFiles.length} file(s)...";
        });

        for (var file in _selectedFiles) {
          String content = '';
          if (file.bytes != null) {
            content = utf8.decode(file.bytes!);
          } else if (file.path != null) {
            content = await File(file.path!).readAsString();
          }

          _controllers[file.name] = CodeController(
            text: content,
            language: _languageModes[_selectedLanguage]!,
          );
        }

        if (_activeFileName != null) {
          final name = _activeFileName!;
          String mainClassName;
          
          if (_selectedLanguage == 'java' && name.endsWith('.java')) {
            mainClassName = name.substring(0, name.length - 5);
          } else if (_selectedLanguage == 'javascript' && name.endsWith('.js')) {
            mainClassName = name.substring(0, name.length - 3);
          } else if (_selectedLanguage == 'python' && name.endsWith('.py')) {
            mainClassName = name.substring(0, name.length - 3);
          } else if (_selectedLanguage == 'cpp' && name.endsWith('.cpp')) {
            mainClassName = name.substring(0, name.length - 4);
          } else {
            mainClassName = name.split('.').first;
          }
          
          _mainClassNameController.text = mainClassName;
        }

        setState(() {
          _isCodeEditorReady = true;
          _output = "✅ Loaded ${_selectedFiles.length} file(s), active file: $_activeFileName\n🎯 Main class set to: ${_mainClassNameController.text}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _output = "❌ Error loading files: $e";
        });
      }
    }
  }

  Future<void> _runCode() async {
    if (_activeFileName == null || _controllers[_activeFileName!] == null) {
      setState(() {
        _output = "⚠️ Code editor is not ready. Please wait a moment and try again.";
      });
      return;
    }

    bool hasNonEmptyFile = _controllers.values.any((controller) => controller.text.isNotEmpty);
    if (!hasNonEmptyFile) {
      setState(() {
        _output = "⚠️ Please enter code or upload files first.";
      });
      return;
    }
    
    if (_mainClassNameController.text.isEmpty) {
      setState(() {
        _output = "⚠️ Please enter the main file (or class) name.";
      });
      return;
    }

    setState(() {
      _isExecuting = true;
      _output = "🔄 Compiling and executing code...\nPlease wait...";
    });

    _animationController.repeat();

    try {
      // Convert controllers to CodeFile objects
      final List<CodeFile> codeFiles = [];
      
      for (final entry in _controllers.entries) {
        final fileName = entry.key;
        final controller = entry.value;
        
        final codeFile = CodeFile(
          filename: fileName,
          content: controller.text,
          language: _selectedLanguage,
        );
        
        codeFiles.add(codeFile);
      }

      final result = await _codeExecutionService.executeCode(
        codeFiles: codeFiles,
        mainClassName: _mainClassNameController.text,
        language: _selectedLanguage,
      );

      if (mounted) {
        setState(() {
          _isExecuting = false;
          if (result['success'] == true) {
            _output = "✅ Execution Successful!\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📤 PROGRAM OUTPUT:\n${result['output'] ?? ''}";
          } else {
            _output = "❌ Execution Failed\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
            if (result['error'] != null && result['error'].isNotEmpty) {
              _output += "⚠️ ERROR:\n${result['error']}\n";
            }
            if (result['output'] != null && result['output'].isNotEmpty) {
              _output += "📤 OUTPUT:\n${result['output']}\n";
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _output = "❌ Network Error: $e";
        });
      }
    }

    _animationController.stop();
    _animationController.reset();
  }

  Future<void> _saveCodeToFile() async {
    if (_controllers[_activeFileName] == null) {
      setState(() {
        _output = "⚠️ Code editor is not ready. Please wait a moment and try again.";
      });
      return;
    }

    // final code = _controllers[_activeFileName]!.text;
    final fileExtension = _selectedLanguage == 'java'
        ? 'java'
        : _selectedLanguage == 'javascript'
            ? 'js'
            : _selectedLanguage == 'python'
                ? 'py'
                : 'cpp';

    final filename = _mainClassNameController.text.isNotEmpty
        ? _mainClassNameController.text
        : _activeFileName?.split('.').first ?? 'my_code';

    try {
      setState(() {
        _output = "💾 File content ready for download as $filename.$fileExtension";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _output = "❌ Error preparing file: $e";
        });
      }
    }
  }

  void _createNewFileTab() {
    final baseName = 'untitled';
    final extension = _getExtensionsForLanguage(_selectedLanguage).first;

    String newFileName = '$baseName.$extension';
    int counter = 1;

    while (_controllers.containsKey(newFileName)) {
      newFileName = '$baseName$counter.$extension';
      counter++;
    }

    final newController = CodeController(
      text: '',
      language: _languageModes[_selectedLanguage]!,
    );

    setState(() {
      _controllers[newFileName] = newController;
      _activeFileName = newFileName;
      _mainClassNameController.text = newFileName.split('.').first;
      _output = "📄 Created new file: $newFileName";
    });
  }

  void _handleMainNameChange() {
    final inputName = _mainClassNameController.text.trim();
    if (inputName.isEmpty || _activeFileName == null) return;

    final extension = _activeFileName!.split('.').last;
    final proposedFileName = inputName.contains('.') ? inputName : '$inputName.$extension';

    if (proposedFileName == _activeFileName) return;

    if (_controllers.containsKey(proposedFileName)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate File Name'),
          content: Text('A tab named "$inputName" already exists. Please choose a different name.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _mainClassNameController.text = _activeFileName!.split('.').first;
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final controller = _controllers.remove(_activeFileName!);
    _controllers[proposedFileName] = controller!;
    _activeFileName = proposedFileName;

    setState(() {
      _output = "📝 File renamed to: $proposedFileName";
    });
  }

  void _onLanguageChanged(String? newValue) {
    if (newValue != null && _languageModes.containsKey(newValue) && newValue != _selectedLanguage) {
      _showLanguageSwitchConfirmation(newValue);
    }
  }

  void _showLanguageSwitchConfirmation(String newLanguage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF2D2D30) : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Switch Language?',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to switch from ${_selectedLanguage.toUpperCase()} to ${newLanguage.toUpperCase()}.',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All current files and code will be lost!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone. Make sure to save your work before proceeding.',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLanguageSwitch(newLanguage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text(
                'Switch Language',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLanguageSwitch(String newLanguage) {
    setState(() {
      _selectedLanguage = newLanguage;
      _selectedFiles = [];
      _activeFile = null;
      _mainClassNameController.text = _getDefaultMainName(newLanguage);
      _isCodeEditorReady = false;
      _output = "🔄 Switching to ${newLanguage.toUpperCase()}...";
    });

    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final baseName = _getDefaultMainName(_selectedLanguage);
        final extension = _getExtensionsForLanguage(_selectedLanguage).first;
        final defaultFileName = '$baseName.$extension';

        final newController = CodeController(
          text: _getDefaultCodeForLanguage(_selectedLanguage),
          language: _languageModes[_selectedLanguage]!,
        );

        setState(() {
          _controllers[defaultFileName] = newController;
          _activeFileName = defaultFileName;
          _mainClassNameController.text = baseName;
          _isCodeEditorReady = true;
          _output = "✅ Language changed to ${_selectedLanguage.toUpperCase()}\nReady to compile and run!";
        });
      }
    });
  }

  Widget _buildFileTabs() {
    if (_controllers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF3F3F3),
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _controllers.keys.map((filename) {
            final isActive = filename == _activeFileName;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _activeFileName = filename;
                      String mainClassName;
                      if (_selectedLanguage == 'java' && filename.endsWith('.java')) {
                        mainClassName = filename.substring(0, filename.length - 5);
                      } else if (_selectedLanguage == 'javascript' && filename.endsWith('.js')) {
                        mainClassName = filename.substring(0, filename.length - 3);
                      } else if (_selectedLanguage == 'python' && filename.endsWith('.py')) {
                        mainClassName = filename.substring(0, filename.length - 3);
                      } else if (_selectedLanguage == 'cpp' && filename.endsWith('.cpp')) {
                        mainClassName = filename.substring(0, filename.length - 4);
                      } else {
                        mainClassName = filename.split('.').first;
                      }
                      _mainClassNameController.text = mainClassName;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? const Color(0xFF4CAF50) 
                          : (_isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      border: isActive ? Border.all(color: const Color(0xFF4CAF50), width: 2) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFileIcon(filename),
                          size: 14,
                          color: isActive ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            filename,
                            style: TextStyle(
                              color: isActive ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black87),
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeTab(filename),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: isActive ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF3F3F3),
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF3C3C3C) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDarkMode ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _languageIcons[_selectedLanguage],
                  size: 18,
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: _onLanguageChanged,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _supportedLanguages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang == 'cpp' ? 'C++' : lang.toUpperCase()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildActionButton(
            icon: Icons.folder_open,
            label: 'Open File',
            onPressed: _pickFiles,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.note_add,
            label: 'New File',
            onPressed: _createNewFileTab,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.save,
            label: 'Save',
            onPressed: _isCodeEditorReady ? _saveCodeToFile : null,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _isExecuting ? Icons.hourglass_empty : Icons.play_arrow,
            label: _isExecuting ? 'Running...' : 'Run',
            onPressed: _isCodeEditorReady && !_isExecuting ? _runCode : null,
            isPrimary: true,
            isLoading: _isExecuting,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPrimary ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? const Color(0xFF4CAF50)
            : (_isDarkMode ? const Color(0xFF3C3C3C) : Colors.white),
        foregroundColor: isPrimary
            ? Colors.white
            : (_isDarkMode ? Colors.white70 : Colors.black87),
        elevation: isPrimary ? 2 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isLoggedIn || authService.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Code Compiler'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
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
            actions: [
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildFileTabs(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              children: [
                                const Text(
                                  'File Name:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _mainClassNameController,
                                    onSubmitted: (_) => _handleMainNameChange(),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: _isDarkMode ? Colors.white24 : Colors.black26,
                                        ),
                                      ),
                                      hintText: 'Enter filename without extension',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.check),
                                        tooltip: 'Rename File',
                                        onPressed: _handleMainNameChange,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              child: _activeFileName != null && _controllers[_activeFileName!] != null
                                  ? CodeField(
                                      controller: _controllers[_activeFileName!]!,
                                      textStyle: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                      expands: true,
                                      maxLines: null,
                                      wrap: false,
                                    )
                                  : const Center(
                                      child: Text(
                                        "Editor not ready",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? const Color(0xFF2E2E2E) : Colors.grey.shade300,
                                border: Border(
                                  bottom: BorderSide(
                                    color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Console Output',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _output,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: _isDarkMode ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}