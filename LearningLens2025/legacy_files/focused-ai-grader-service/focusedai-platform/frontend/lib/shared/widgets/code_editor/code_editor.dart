import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/cpp.dart';
import '../../../core/models/code_file.dart';

class CodeEditor extends StatefulWidget {
  final List<CodeFile> files;
  final bool readOnly;
  final Function(String filename, String content)? onCodeChanged;

  const CodeEditor({
    super.key,
    required this.files,
    this.readOnly = false,
    this.onCodeChanged,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> with TickerProviderStateMixin {
  TabController? _tabController;
  List<CodeController> _controllers = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.files.isNotEmpty) {
      _tabController = TabController(length: widget.files.length, vsync: this);
      _controllers = widget.files.map((file) {
        return CodeController(
          text: file.content,
          language: _getLanguageMode(file.language),
        );
      }).toList();

      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) {
          setState(() {
            _currentIndex = _tabController!.index;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.files != oldWidget.files) {
      _tabController?.dispose();
      for (var controller in _controllers) {
        controller.dispose();
      }
      _initializeControllers();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No code files to display',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (widget.files.length > 1) ...[
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              tabs: widget.files.map((file) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFileIcon(file.filename),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(file.filename),
                    ],
                  ),
                );
              }).toList(),
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: widget.files.length == 1
                ? _buildCodeField(0)
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(
                      widget.files.length,
                      (index) => _buildCodeField(index),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField(int index) {
    return CodeField(
      controller: _controllers[index],
      readOnly: widget.readOnly,
      wrap: true,
      lineNumbers: true,
      onChanged: widget.onCodeChanged != null
          ? (value) => widget.onCodeChanged!(
                widget.files[index].filename,
                value,
              )
          : null,
      textStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
    );
  }

  dynamic _getLanguageMode(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return java;
      case 'python':
        return python;
      case 'javascript':
        return javascript;
      case 'cpp':
      case 'c++':
        return cpp;
      default:
        return java;
    }
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'java':
        return Icons.coffee;
      case 'py':
        return Icons.psychology;
      case 'js':
        return Icons.javascript;
      case 'cpp':
      case 'cc':
      case 'cxx':
        return Icons.code;
      default:
        return Icons.description;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
