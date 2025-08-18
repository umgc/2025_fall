// lib/widgets/assignment_preview.dart - Simplified and organized version
import 'package:flutter/material.dart';
import '../services/caila_service.dart';
import '../widgets/assignment_preview_sections.dart';

class AssignmentPreview extends StatefulWidget {
  final String content;
  final String materialType;
  final String title;
  final Function(String) onSectionEdit;
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final bool isVisible;
  final String platform; // 'google' or 'moodle'

  const AssignmentPreview({
    super.key,
    required this.content,
    required this.materialType,
    required this.title,
    required this.onSectionEdit,
    this.onSave,
    this.onExport,
    this.isVisible = true,
    required this.platform,
  });

  @override
  State<AssignmentPreview> createState() => _AssignmentPreviewState();
}

class _AssignmentPreviewState extends State<AssignmentPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isExpanded = true;
  ParsedAssignment? _parsedContent;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseContent();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AssignmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _parseContent();
    }
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _parseContent() {
    setState(() {
      _parsedContent = CailaService.parseAssignment(widget.content, widget.materialType);
    });
  }

  void _handleSectionEdit(String sectionName, String currentContent) {
    String suggestion = _generateEditSuggestion(sectionName, currentContent);
    widget.onSectionEdit(suggestion);
  }

  String _generateEditSuggestion(String sectionName, String currentContent) {
    if (currentContent.isEmpty) {
      return 'Please revise the $sectionName section';
    }

    switch (sectionName.toLowerCase()) {
      case 'title':
        return 'Please change the title "$currentContent" to';
      case 'instructions':
      case 'description':
      case 'assignment instructions':
        return 'Please revise the instructions section to be more';
      case 'learning objectives':
        return 'Please modify the learning objectives to';
      case 'questions':
        return 'Please modify the questions to';
      case 'rubric':
      case 'grading criteria':
        return 'Please adjust the rubric criteria to';
      case 'due date':
        return 'Please change the due date to';
      case 'requirements':
        return 'Please update the requirements to';
      case 'deliverables':
        return 'Please modify the deliverables to';
      case 'essay prompt':
        return 'Please revise the essay prompt to';
      case 'assignment parts':
        return 'Please revise the assignment parts to';
      case 'resources & guidance':
        return 'Please update the resources and guidance to';
      case 'implementation notes for teachers':
        return 'Please modify the implementation notes to';
      default:
        if (sectionName.startsWith('Part ') || sectionName.startsWith('Question ')) {
          return 'Please revise $sectionName to';
        } else {
          return 'Please revise the $sectionName section to';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || !_isExpanded || _parsedContent == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildScrollableContent(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(widget.materialType),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.materialType} Preview',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.title.isNotEmpty)
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onSave != null)
                IconButton(
                  onPressed: widget.onSave,
                  icon: const Icon(Icons.save, color: Colors.white),
                  tooltip: 'Save Draft',
                ),
              if (widget.onExport != null)
                IconButton(
                  onPressed: widget.onExport,
                  icon: Icon(
                    widget.platform == 'google' ? Icons.class_ : Icons.account_balance,
                    color: Colors.white,
                  ),
                  tooltip: 'Export to ${widget.platform == 'google' ? 'Google Classroom' : 'Moodle'}',
                ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close Preview',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            if (_parsedContent!.title.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Title',
                content: _parsedContent!.title,
                icon: Icons.title,
                color: Colors.blue,
                onSectionEdit: _handleSectionEdit,
              ),
            
            // Course Metadata
            if (_parsedContent!.courseMeta.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Course Information',
                content: _parsedContent!.courseMeta,
                icon: Icons.school,
                color: Colors.purple,
                onSectionEdit: _handleSectionEdit,
              ),
              
            // Duration
            if (_parsedContent!.duration.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Duration',
                content: _parsedContent!.duration,
                icon: Icons.schedule,
                color: Colors.red,
                onSectionEdit: _handleSectionEdit,
              ),
            
            // Learning Objectives
            if (_parsedContent!.learningObjectives.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Learning Objectives',
                content: _parsedContent!.learningObjectives,
                icon: Icons.lightbulb,
                color: Colors.amber,
                onSectionEdit: _handleSectionEdit,
              ),
            
            // Assignment Instructions
            if (_parsedContent!.assignmentInstructions.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Assignment Instructions',
                content: _parsedContent!.assignmentInstructions,
                icon: Icons.assignment,
                color: Colors.orange,
                onSectionEdit: _handleSectionEdit,
              ),
            
            // Description (fallback)
            if (_parsedContent!.description.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Description',
                content: _parsedContent!.description,
                icon: Icons.description,
                color: Colors.orange,
                onSectionEdit: _handleSectionEdit,
              ),
            
            // Assignment Parts
            if (_parsedContent!.assignmentParts.isNotEmpty)
              AssignmentPreviewSections.buildAssignmentPartsSection(
                assignmentParts: _parsedContent!.assignmentParts,
                onSectionEdit: _handleSectionEdit,
              ),
            
            // Questions (for quizzes)
            if (_parsedContent!.questions.isNotEmpty)
              AssignmentPreviewSections.buildQuestionsSection(
                questions: _parsedContent!.questions,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Requirements
            if (_parsedContent!.requirements.isNotEmpty)
              AssignmentPreviewSections.buildRequirementsSection(
                requirements: _parsedContent!.requirements,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Deliverables
            if (_parsedContent!.deliverables.isNotEmpty)
              AssignmentPreviewSections.buildDeliverablesSection(
                deliverables: _parsedContent!.deliverables,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Submission Requirements
            if (_parsedContent!.submissionRequirements.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Submission Requirements',
                content: _parsedContent!.submissionRequirements,
                icon: Icons.upload,
                color: Colors.teal,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Grading Criteria
            if (_parsedContent!.gradingCriteria.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Grading Criteria',
                content: _parsedContent!.gradingCriteria,
                icon: Icons.grade,
                color: Colors.indigo,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Essay-specific sections
            if (_parsedContent!.essayPrompt.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Essay Prompt',
                content: _parsedContent!.essayPrompt,
                icon: Icons.article,
                color: Colors.deepPurple,
                onSectionEdit: _handleSectionEdit,
              ),
                
            if (_parsedContent!.requiredLength.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Required Length',
                content: _parsedContent!.requiredLength,
                icon: Icons.straighten,
                color: Colors.brown,
                onSectionEdit: _handleSectionEdit,
              ),
                
            if (_parsedContent!.thesisRequirements.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Thesis Requirements',
                content: _parsedContent!.thesisRequirements,
                icon: Icons.psychology,
                color: Colors.deepOrange,
                onSectionEdit: _handleSectionEdit,
              ),
                
            if (_parsedContent!.sourceRequirements.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Source Requirements',
                content: _parsedContent!.sourceRequirements,
                icon: Icons.library_books,
                color: Colors.green,
                onSectionEdit: _handleSectionEdit,
              ),
                
            if (_parsedContent!.structureGuidelines.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Structure Guidelines',
                content: _parsedContent!.structureGuidelines,
                icon: Icons.account_tree,
                color: Colors.blueGrey,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Rubric
            if (_parsedContent!.rubric.isNotEmpty)
              AssignmentPreviewSections.buildRubricSection(
                rubricContent: _parsedContent!.rubric,
                onSectionEdit: _handleSectionEdit,
              ),
            
            // Resources & Guidance
            if (_parsedContent!.resourcesGuidance.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Resources & Guidance',
                content: _parsedContent!.resourcesGuidance,
                icon: Icons.help,
                color: Colors.cyan,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Implementation Notes
            if (_parsedContent!.implementationNotes.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Implementation Notes for Teachers',
                content: _parsedContent!.implementationNotes,
                icon: Icons.note,
                color: Colors.grey,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Due Date
            if (_parsedContent!.dueDate.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Due Date',
                content: _parsedContent!.dueDate,
                icon: Icons.schedule,
                color: Colors.red,
                onSectionEdit: _handleSectionEdit,
              ),
                
            // Additional Notes
            if (_parsedContent!.additionalNotes.isNotEmpty)
              AssignmentPreviewSections.buildEditableSection(
                title: 'Additional Notes',
                content: _parsedContent!.additionalNotes,
                icon: Icons.note,
                color: Colors.grey,
                onSectionEdit: _handleSectionEdit,
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String materialType) {
    switch (materialType.toLowerCase()) {
      case 'quiz':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'essay':
        return Icons.article;
      case 'rubric':
        return Icons.checklist;
      default:
        return Icons.article;
    }
  }
}