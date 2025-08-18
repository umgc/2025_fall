// lib/services/caila_service.dart - Enhanced with assignment context management and parsing
import 'dart:math' as Math;

import '../apis/caila_api.dart';

// Assignment parsing data models
class ParsedAssignment {
  final String title;
  final String description;
  final List<Question> questions;
  final String rubric;
  final String dueDate;
  final String additionalNotes;
  final List<AssignmentRequirement> requirements;
  final List<String> deliverables;
  final String submissionRequirements;
  final String gradingCriteria;
  final String essayPrompt;
  final String requiredLength;
  final String thesisRequirements;
  final String sourceRequirements;
  final String structureGuidelines;
  
  // Enhanced fields for assignments
  final String learningObjectives;
  final String assignmentInstructions;
  final String courseMeta;
  final String duration;
  final String resourcesGuidance;
  final String implementationNotes;
  final List<AssignmentPart> assignmentParts;

  ParsedAssignment({
    required this.title,
    required this.description,
    required this.questions,
    required this.rubric,
    required this.dueDate,
    required this.additionalNotes,
    this.requirements = const [],
    this.deliverables = const [],
    this.submissionRequirements = '',
    this.gradingCriteria = '',
    this.essayPrompt = '',
    this.requiredLength = '',
    this.thesisRequirements = '',
    this.sourceRequirements = '',
    this.structureGuidelines = '',
    this.learningObjectives = '',
    this.assignmentInstructions = '',
    this.courseMeta = '',
    this.duration = '',
    this.resourcesGuidance = '',
    this.implementationNotes = '',
    this.assignmentParts = const [],
  });
}

class Question {
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String type; // 'multiple-choice', 'short-answer', 'true-false', 'essay'

  Question({
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.type = 'multiple-choice',
  });
}

class AssignmentRequirement {
  final String title;
  final String description;
  final bool isRequired;

  AssignmentRequirement({
    required this.title,
    required this.description,
    this.isRequired = true,
  });
}

class AssignmentPart {
  final int number;
  final String title;
  final String duration;
  String content;
  final List<String> tasks;
  final List<AssignmentQuestion> questions;

  AssignmentPart({
    required this.number,
    required this.title,
    required this.duration,
    required this.content,
    required this.tasks,
    required this.questions,
  });
}

class AssignmentQuestion {
  final int number;
  final String text;

  AssignmentQuestion({
    required this.number,
    required this.text,
  });
}

class AssignmentContextManager {
  String? _originalAssignmentContext;
  String? _currentAssignmentContext;
  String? _selectedMaterialType;
  
  // Getters
  String? get originalAssignmentContext => _originalAssignmentContext;
  String? get currentAssignmentContext => _currentAssignmentContext;
  String? get selectedMaterialType => _selectedMaterialType;
  
  bool get hasContext => _currentAssignmentContext != null;
  bool get hasOriginalContext => _originalAssignmentContext != null;
  
  // Set new assignment context (for new generation)
  void setNewAssignment({
    required String content,
    required String materialType,
  }) {
    _originalAssignmentContext = content;
    _currentAssignmentContext = content;
    _selectedMaterialType = materialType;
  }
  
  // Update current context (for revisions)
  void updateCurrentAssignment(String content) {
    _currentAssignmentContext = content;
  }
  
  // Clear all context
  void clearContext() {
    _originalAssignmentContext = null;
    _currentAssignmentContext = null;
    _selectedMaterialType = null;
  }
  
  // Check if material type changed (should clear context)
  bool shouldClearOnMaterialTypeChange(String? newMaterialType) {
    return hasContext && _selectedMaterialType != newMaterialType;
  }
  
  // Update material type
  void updateMaterialType(String materialType) {
    _selectedMaterialType = materialType;
  }
  
  // Get context summary for debugging
  Map<String, dynamic> getContextSummary() {
    return {
      'hasOriginalContext': hasOriginalContext,
      'hasCurrentContext': hasContext,
      'originalLength': _originalAssignmentContext?.length ?? 0,
      'currentLength': _currentAssignmentContext?.length ?? 0,
      'materialType': _selectedMaterialType,
    };
  }
}

class CailaService {
  // Chat functionality with improved error handling
  static Future<String> chatWithCaila({
    required String authToken,
    required String prompt,
    String? courseId,
    String? studentId,
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    try {
      // Use the adaptive timeout method that automatically adjusts based on request type
      final response = await CailaApi.chatWithAdaptiveTimeout(
        authToken: authToken,
        prompt: prompt,
        courseId: courseId,
        studentId: studentId,
        sessionId: sessionId,
        history: history,
      );
      
      if (response['success'] == true) {
        return response['response'] ?? 'No response received';
      } else {
        final error = response['error'] ?? 'Chat failed';
        throw Exception(error);
      }
    } catch (e) {
      // Provide more user-friendly error messages
      if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        if (_isMaterialGenerationRequest(prompt)) {
          throw Exception('🕐 Material generation is taking longer than expected.\n\n💡 Try:\n• Breaking your request into smaller parts\n• Being more specific about what you want\n• Trying again in a moment\n\nThe AI might be handling a complex request or the server might be busy.');
        } else {
          throw Exception('⏱️ Request timed out.\n\nPlease try:\n• A shorter message\n• A simpler question\n• Waiting a moment and trying again');
        }
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('🔐 Session expired. Please log in again.');
      } else if (e.toString().contains('500') || e.toString().contains('Internal Server Error')) {
        throw Exception('🛠️ Server error. Please try again in a few moments.');
      } else if (e.toString().contains('Network error') || e.toString().contains('connection')) {
        throw Exception('🌐 Network connection issue. Please check your internet connection and try again.');
      }
      
      // For other errors, provide the original message but make it more user-friendly
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception('❌ $errorMessage');
    }
  }

  // Material generation with enhanced error handling
  static Future<String> generateMaterial({
    required String authToken,
    required String prompt,
    String? materialType,
    String? courseId,
    String? title,
  }) async {
    try {
      // Add some context to help the AI understand this is a material generation request
      String enhancedPrompt = prompt;
      if (materialType != null) {
        enhancedPrompt = 'Create a $materialType: $prompt';
      }
      
      final response = await CailaApi.generateMaterial(
        authToken: authToken,
        prompt: enhancedPrompt,
        materialType: materialType,
        courseId: courseId,
        title: title,
      );
      
      if (response['success'] == true) {
        return response['response'] ?? 'No material generated';
      } else {
        final error = response['error'] ?? 'Material generation failed';
        throw Exception(error);
      }
    } catch (e) {
      // Enhanced error messages for material generation
      if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        throw Exception('⏳ Material generation is taking longer than expected.\n\n🎯 This often happens with:\n• Very detailed requests\n• Complex assignments\n• Multiple requirements\n\n💡 Try:\n• Simplifying your request\n• Focusing on one aspect at a time\n• Being more specific about what you need\n• Trying again (server might be busy)');
      } else if (e.toString().contains('401')) {
        throw Exception('🔐 Session expired. Please log in again.');
      } else if (e.toString().contains('500')) {
        throw Exception('🛠️ Server error during material generation. Please try again in a few moments.');
      } else if (e.toString().contains('Network error')) {
        throw Exception('🌐 Network issue during material generation. Please check your connection and try again.');
      }
      
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception('❌ $errorMessage');
    }
  }

  // Enhanced rubric generation for assignments
  static Future<String> generateRubric({
    required String authToken,
    required String assignmentPrompt,
    String? courseId,
  }) async {
    try {
      final response = await CailaApi.generateRubric(
        authToken: authToken,
        assignmentPrompt: assignmentPrompt,
        courseId: courseId,
      );
      
      if (response['success'] == true) {
        return response['rubric'] ?? response['response'] ?? 'No rubric generated';
      } else {
        throw Exception(response['error'] ?? 'Rubric generation failed');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('⏳ Rubric generation timed out.\n\n💡 Try:\n• Providing a shorter assignment description\n• Being more specific about requirements\n• Trying again');
      }
      throw Exception('Failed to generate rubric: $e');
    }
  }

  // Assignment evaluation using API with better error handling
  static Future<String> evaluateAnswer({
    required String authToken,
    required String rubric,
    required String studentAnswer,
    String? courseId,
    String? assignmentId,
  }) async {
    try {
      final response = await CailaApi.evaluateAnswer(
        authToken: authToken,
        assignmentId: assignmentId ?? 'unknown',
        studentAnswer: studentAnswer,
        rubric: rubric,
        courseId: courseId,
      );
      
      if (response['success'] == true) {
        return response['evaluation'] ?? response['response'] ?? 'No evaluation generated';
      } else {
        throw Exception(response['error'] ?? 'Evaluation failed');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('⏳ Answer evaluation timed out.\n\n💡 Try:\n• Shortening the student answer\n• Simplifying the rubric\n• Trying again');
      }
      throw Exception('Failed to evaluate answer: $e');
    }
  }

  // Chat history management
  static Future<List<Map<String, dynamic>>> getChatHistory({
    required String authToken,
  }) async {
    try {
      final response = await CailaApi.getChatHistory(
        authToken: authToken,
      );
      
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['history'] ?? []);
      } else {
        throw Exception(response['error'] ?? 'Failed to get chat history');
      }
    } catch (e) {
      throw Exception('Failed to get chat history: $e');
    }
  }

  // Teacher materials management
  static Future<List<Map<String, dynamic>>> getTeacherMaterials({
    required String authToken,
    required String teacherId,
  }) async {
    try {
      return await CailaApi.getTeacherMaterials(
        authToken: authToken,
        teacherId: teacherId,
      );
    } catch (e) {
      throw Exception('Failed to get teacher materials: $e');
    }
  }

  static Future<Map<String, dynamic>> getMaterial({
    required String authToken,
    required String materialId,
  }) async {
    try {
      return await CailaApi.getMaterial(
        authToken: authToken,
        materialId: materialId,
      );
    } catch (e) {
      throw Exception('Failed to get material: $e');
    }
  }

  // Student conversation logs for teachers
  static Future<List<Map<String, dynamic>>> getStudentLogs({
    required String authToken,
    required String courseId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await CailaApi.getStudentChatLogs(
        authToken: authToken,
        courseId: courseId,
        studentId: studentId,
      );
      
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['logs'] ?? []);
      } else {
        throw Exception(response['error'] ?? 'Failed to get student logs');
      }
    } catch (e) {
      throw Exception('Failed to get student logs: $e');
    }
  }

  // ===== NEW ASSIGNMENT CONTEXT MANAGEMENT METHODS =====
  
  // Build revision prompts with full context
  static String buildRevisionPrompt(String revisionRequest, String currentAssignment, String? materialType) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are CAILA, an AI teaching assistant. I need you to revise a specific part of an existing assignment while keeping everything else exactly the same.');
    buffer.writeln();
    buffer.writeln('CURRENT ASSIGNMENT:');
    buffer.writeln('=' * 50);
    buffer.writeln(currentAssignment);
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('REVISION REQUEST:');
    buffer.writeln(revisionRequest);
    buffer.writeln();
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('1. Keep the overall structure, format, and style of the assignment exactly the same');
    buffer.writeln('2. Only modify the specific section mentioned in the revision request');
    buffer.writeln('3. Maintain the same educational level and assessment criteria');
    buffer.writeln('4. Keep all other questions/sections unchanged');
    buffer.writeln('5. Return the complete revised assignment, not just the changed section');
    buffer.writeln('6. Ensure the revision integrates seamlessly with the existing content');
    
    if (materialType != null) {
      buffer.writeln('7. Maintain the $materialType format and requirements');
    }
    
    return buffer.toString();
  }

  // Detect revision requests
  static bool isRevisionRequest(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    return lowerPrompt.contains('revise') ||
           lowerPrompt.contains('change') ||
           lowerPrompt.contains('modify') ||
           lowerPrompt.contains('update') ||
           lowerPrompt.contains('edit') ||
           lowerPrompt.contains('fix') ||
           lowerPrompt.contains('improve') ||
           lowerPrompt.contains('make it') ||
           lowerPrompt.contains('adjust') ||
           (lowerPrompt.contains('question') && (lowerPrompt.contains('more') || lowerPrompt.contains('less') || lowerPrompt.contains('different')));
  }

  // Detect material generation requests
  static bool isMaterialGenerationRequest(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    return lowerPrompt.contains('create') || 
           lowerPrompt.contains('generate') || 
           lowerPrompt.contains('make') ||
           lowerPrompt.contains('assignment') ||
           lowerPrompt.contains('quiz') ||
           lowerPrompt.contains('lesson') ||
           lowerPrompt.contains('worksheet') ||
           lowerPrompt.contains('rubric') ||
           lowerPrompt.contains('test') ||
           lowerPrompt.contains('exam') ||
           lowerPrompt.contains('activity') ||
           lowerPrompt.contains('project') ||
           lowerPrompt.contains('study guide');
  }

  // Check if content looks like generated material
  static bool isGeneratedMaterial(String content) {
    return content.length > 200 && 
           (content.contains('**') || 
            content.contains('##') || 
            content.toLowerCase().contains('objective') ||
            content.toLowerCase().contains('instruction') ||
            content.toLowerCase().contains('question') ||
            content.toLowerCase().contains('due date') ||
            content.toLowerCase().contains('rubric'));
  }

  // Clean markdown formatting for display
  static String cleanMarkdownForDisplay(String text) {
  if (text.isEmpty) return text;
  
  String result = text;
  
  // Remove markdown headers but keep the text
  result = result.replaceAllMapped(RegExp(r'^#{1,6}\s*(.+)$', multiLine: true), (match) => match.group(1) ?? '');
  
  // Remove bold markers: **text** -> text
  result = result.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1) ?? '');
  
  // Remove italic markers: *text* -> text
  result = result.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => match.group(1) ?? '');
  
  // Remove standalone asterisks and markdown markers
  result = result.replaceAll(RegExp(r'^\*+\s*', multiLine: true), '');
  result = result.replaceAll(RegExp(r'\s*\*+$', multiLine: true), '');
  
  // Clean up horizontal rules
  result = result.replaceAll(RegExp(r'^-{3,}$', multiLine: true), '');
  
  // Clean up multiple spaces and newlines
  result = result.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
  result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
  
  return result.trim();
}

// Format timestamps for display
static String formatTimestamp(String timestamp) {
  try {
    final dateTime = DateTime.parse(timestamp);
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
  } catch (e) {
    return '';
  }
}

// Helper method to detect material generation requests
static bool _isMaterialGenerationRequest(String prompt) {
  final lowerPrompt = prompt.toLowerCase();
  return lowerPrompt.contains('create') || 
         lowerPrompt.contains('generate') || 
         lowerPrompt.contains('make') ||
         lowerPrompt.contains('assignment') ||
         lowerPrompt.contains('quiz') ||
         lowerPrompt.contains('lesson') ||
         lowerPrompt.contains('worksheet') ||
         lowerPrompt.contains('rubric') ||
         lowerPrompt.contains('test') ||
         lowerPrompt.contains('exam') ||
         lowerPrompt.contains('activity') ||
         lowerPrompt.contains('project') ||
         lowerPrompt.contains('study guide');
}

// Context-aware prompts for different material types
static String enhancePromptForMaterialType({
  required String materialType,
  required String prompt,
  String? courseContext,
  String? difficulty,
  List<String>? learningObjectives,
}) {
  StringBuffer systemContext = StringBuffer();
  
  systemContext.writeln('You are CAILA, an expert AI teaching assistant and educational content creator.');
  systemContext.writeln();

  switch (materialType.toLowerCase()) {
    case 'quiz':
    case 'assessment':
      systemContext.writeln('''
TASK: Create engaging, pedagogically sound quiz questions that:
- Test understanding, not just memorization
- Include a variety of question types (multiple choice, short answer, essay)
- Provide clear instructions and expectations
- Are appropriate for the educational level
- Include answer keys and explanations where helpful
- Focus on critical thinking and application of concepts
''');
    case 'assignment':
    case 'homework':
      systemContext.writeln('''
TASK: Design meaningful, challenging, and pedagogically effective assignments that:
- Have clear, measurable learning objectives
- Include step-by-step instructions and requirements
- Provide assessment criteria and rubrics
- Encourage critical thinking and analysis
- Are appropriately scoped for the time available
- Include resources and guidance for students
''');
    case 'lesson plan':
    case 'lesson':
      systemContext.writeln('''
TASK: Create structured, engaging, and comprehensive lesson content that:
- Has clear learning objectives aligned with curriculum standards
- Includes diverse teaching methods and activities
- Provides assessment opportunities throughout
- Engages different learning styles (visual, auditory, kinesthetic)
- Includes timing and pacing guidelines
- Offers extension activities for advanced learners
''');
    case 'worksheet':
    case 'practice':
      systemContext.writeln('''
TASK: Design practical, interactive, and skill-building worksheet activities that:
- Reinforce key concepts through practice
- Include varied exercise types and difficulty levels
- Provide clear instructions and examples
- Build skills progressively from simple to complex
- Include answer keys for self-assessment
- Offer hints or scaffolding for struggling learners
''');
    case 'rubric':
      systemContext.writeln('''
TASK: Create comprehensive, fair assessment rubrics that:
- Define clear criteria and performance levels
- Include specific, observable descriptors
- Align with learning objectives and assignment goals
- Provide point values and grade ranges
- Are easy for students to understand and self-assess
- Support consistent grading across instructors
''');
    case 'study guide':
    case 'review':
      systemContext.writeln('''
TASK: Develop comprehensive study materials that:
- Organize key concepts in a logical sequence
- Include summaries, examples, and practice problems
- Provide multiple ways to engage with the material
- Include self-assessment opportunities
- Offer study strategies and tips
- Connect concepts to real-world applications
''');
    case 'project instructions':
    case 'project':
      systemContext.writeln('''
TASK: Create detailed project guidelines that:
- Define clear project scope and deliverables
- Include timeline and milestone checkpoints
- Provide assessment criteria and expectations
- Offer resources and support materials
- Encourage creativity while meeting learning objectives
- Include collaboration guidelines if applicable
''');
    case 'essay':
      systemContext.writeln('''
TASK: Create detailed essay assignment instructions that:
- Provide a clear, engaging prompt that encourages critical thinking
- Include specific requirements for length, format, and structure
- Specify citation and source requirements
- Provide assessment criteria and rubric
- Include guidance on thesis development and argumentation
- Offer resources and support for the writing process
''');
    default:
      systemContext.writeln('''
TASK: Create high-quality educational content that:
- Is pedagogically sound and evidence-based
- Engages learners effectively
- Meets educational standards and best practices
- Is ready for immediate classroom use
- Supports diverse learning needs and styles
''');
  }

  systemContext.writeln();

  if (courseContext != null && courseContext.isNotEmpty) {
    systemContext.writeln('COURSE CONTEXT: $courseContext');
    systemContext.writeln();
  }

  if (difficulty != null && difficulty.isNotEmpty) {
    systemContext.writeln('DIFFICULTY LEVEL: $difficulty');
    systemContext.writeln();
  }

  if (learningObjectives != null && learningObjectives.isNotEmpty) {
    systemContext.writeln('LEARNING OBJECTIVES:');
    for (final objective in learningObjectives) {
      systemContext.writeln('- $objective');
    }
    systemContext.writeln();
  }

  systemContext.writeln('USER REQUEST:');
  systemContext.writeln(prompt);
  systemContext.writeln();

  systemContext.writeln('REQUIREMENTS:');
  systemContext.writeln('- Create content that is educationally appropriate and well-structured');
  systemContext.writeln('- Ensure content is ready for immediate use in educational settings');
  systemContext.writeln('- Use clear, accessible language appropriate for the target audience');
  systemContext.writeln('- Include practical implementation guidance where relevant');
  systemContext.writeln('- Format content professionally with clear organization');

  return systemContext.toString();
}

// Enhanced student guidance prompts
static String enhancePromptForStudentGuidance({
  required String studentQuestion,
  String? courseContext,
  String? assignmentContext,
  String? studentWork,
  List<Map<String, String>>? conversationHistory,
}) {
  StringBuffer context = StringBuffer();

  context.writeln('You are CAILA, an AI teaching assistant designed to help students learn effectively.');
  context.writeln();
  context.writeln('CORE PRINCIPLES:');
  context.writeln('- Guide learning without giving direct answers');
  context.writeln('- Ask clarifying questions to understand student needs');
  context.writeln('- Encourage critical thinking and problem-solving');
  context.writeln('- Provide examples and analogies to explain concepts');
  context.writeln('- Be patient, encouraging, and supportive');
  context.writeln('- Help students develop learning strategies');
  context.writeln();

  if (courseContext != null && courseContext.isNotEmpty) {
    context.writeln('COURSE CONTEXT:');
    context.writeln(courseContext);
    context.writeln();
  }

  if (assignmentContext != null && assignmentContext.isNotEmpty) {
    context.writeln('CURRENT ASSIGNMENT:');
    context.writeln(assignmentContext);
    context.writeln();
  }

  if (studentWork != null && studentWork.isNotEmpty) {
    context.writeln('STUDENT\'S CURRENT WORK:');
    context.writeln(studentWork);
    context.writeln();
  }

  if (conversationHistory != null && conversationHistory.isNotEmpty) {
    context.writeln('RECENT CONVERSATION:');
    for (final message in conversationHistory.take(6)) {
      final role = message['role'] == 'user' ? 'Student' : 'CAILA';
      final content = message['content'] ?? '';
      context.writeln('$role: ${content.length > 100 ? '${content.substring(0, 100)}...' : content}');
    }
    context.writeln();
  }

  context.writeln('STUDENT QUESTION:');
  context.writeln(studentQuestion);
  context.writeln();

  context.writeln('Please provide helpful, educational guidance that:');
  context.writeln('- Helps the student think through the problem');
  context.writeln('- Provides hints and strategies rather than direct answers');
  context.writeln('- Encourages the student to explain their thinking');
  context.writeln('- Builds confidence and learning skills');
  context.writeln('- Is appropriate for the educational context');

  return context.toString();
}

// Validate and sanitize prompts
static String sanitizePrompt(String prompt) {
  // Remove potentially harmful content
  String sanitized = prompt.trim();
  
  // Remove excessive whitespace
  sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
  
  // Limit length to prevent abuse
  if (sanitized.length > 5000) {
    sanitized = '${sanitized.substring(0, 5000)}...';
  }
  
  return sanitized;
}

// Generate conversation summary
static String generateConversationSummary(List<Map<String, String>> conversation) {
  if (conversation.isEmpty) return 'No conversation to summarize.';
  
  final StringBuffer summary = StringBuffer();
  summary.writeln('Conversation Summary:');
  summary.writeln('Messages: ${conversation.length}');
  
  final studentMessages = conversation.where((msg) => msg['role'] == 'user').length;
  final aiMessages = conversation.where((msg) => msg['role'] == 'assistant').length;
  
  summary.writeln('Student messages: $studentMessages');
  summary.writeln('AI responses: $aiMessages');
  
  // Extract key topics
  final allText = conversation
      .map((msg) => msg['content'] ?? '')
      .join(' ')
      .toLowerCase();
  
  final keywords = <String>[];
  if (allText.contains('assignment')) keywords.add('assignment help');
  if (allText.contains('code') || allText.contains('program')) keywords.add('programming');
  if (allText.contains('math') || allText.contains('equation')) keywords.add('mathematics');
  if (allText.contains('essay') || allText.contains('write')) keywords.add('writing');
  if (allText.contains('study') || allText.contains('exam')) keywords.add('study help');
  
  if (keywords.isNotEmpty) {
    summary.writeln('Topics discussed: ${keywords.join(', ')}');
  }
  
  return summary.toString();
}

// Error handling and retry logic
static Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  Exception? lastException;
  
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await operation();
    } catch (e) {
      lastException = e is Exception ? e : Exception(e.toString());
      
      // Don't retry certain types of errors
      if (e.toString().contains('401') || 
          e.toString().contains('403') || 
          e.toString().contains('Session expired')) {
        throw lastException;
      }
      
      if (attempt < maxRetries - 1) {
        print('CailaService: Attempt ${attempt + 1} failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay * (attempt + 1));
      }
    }
  }
  
  throw lastException ?? Exception('Operation failed after $maxRetries attempts');
}

// Batch operations for efficiency
static Future<List<String>> generateMultipleMaterials({
  required String authToken,
  required List<Map<String, String>> materialRequests,
}) async {
  final results = <String>[];
  
  for (final request in materialRequests) {
    try {
      final material = await generateMaterial(
        authToken: authToken,
        prompt: request['prompt'] ?? '',
        materialType: request['materialType'],
        courseId: request['courseId'],
        title: request['title'],
      );
      results.add(material);
    } catch (e) {
      results.add('Error generating material: $e');
    }
  }
  
  return results;
}

// ===== ASSIGNMENT PARSING METHODS =====

// Parse assignment content into structured format
static ParsedAssignment parseAssignment(String content, String materialType) {
  print('CailaService.parseAssignment: Content length: ${content.length}, Material type: $materialType');
  
  try {
    String title = _extractTitle(content);
    String description = _extractDescription(content);
    List<Question> questions = _extractQuestions(content, materialType);
    String rubric = _extractRubric(content);
    String dueDate = _extractDueDate(content);
    String additionalNotes = _extractAdditionalNotes(content);
    
    // Assignment-specific extractions
    List<AssignmentRequirement> requirements = _extractRequirements(content);
    List<String> deliverables = _extractDeliverables(content);
    String submissionRequirements = _extractSubmissionRequirements(content);
    String gradingCriteria = _extractGradingCriteria(content);
    
    // Enhanced assignment sections
    String learningObjectives = _extractLearningObjectives(content);
    String assignmentInstructions = _extractAssignmentInstructions(content);
    String courseMeta = _extractCourseMeta(content);
    String duration = _extractDuration(content);
    String resourcesGuidance = _extractResourcesGuidance(content);
    String implementationNotes = _extractImplementationNotes(content);
    List<AssignmentPart> assignmentParts = _extractAssignmentParts(content);
    
    // Essay-specific extractions
    String essayPrompt = _extractEssayPrompt(content, materialType);
    String requiredLength = _extractRequiredLength(content);
    String thesisRequirements = _extractThesisRequirements(content);
    String sourceRequirements = _extractSourceRequirements(content);
    String structureGuidelines = _extractStructureGuidelines(content);

    print('CailaService.parseAssignment: Extracted ${questions.length} questions for $materialType');

    return ParsedAssignment(
      title: title,
      description: description,
      questions: questions,
      rubric: rubric,
      dueDate: dueDate,
      additionalNotes: additionalNotes,
      requirements: requirements,
      deliverables: deliverables,
      submissionRequirements: submissionRequirements,
      gradingCriteria: gradingCriteria,
      essayPrompt: essayPrompt,
      requiredLength: requiredLength,
      thesisRequirements: thesisRequirements,
      sourceRequirements: sourceRequirements,
      structureGuidelines: structureGuidelines,
      learningObjectives: learningObjectives,
      assignmentInstructions: assignmentInstructions,
      courseMeta: courseMeta,
      duration: duration,
      resourcesGuidance: resourcesGuidance,
      implementationNotes: implementationNotes,
      assignmentParts: assignmentParts,
    );
  } catch (e, stackTrace) {
    print('CailaService.parseAssignment: Error parsing content: $e');
    print('Stack trace: $stackTrace');
    
    // Return a basic parsed assignment with just the content
    return ParsedAssignment(
      title: _extractTitleSafe(content),
      description: content.length > 500 ? '${content.substring(0, 500)}...' : content,
      questions: [],
      rubric: '',
      dueDate: '',
      additionalNotes: '',
    );
  }
}

// Enhanced rubric parsing
static Map<String, dynamic> parseRubricContent(String rubricText) {
  print('CailaService.parseRubricContent: Input length: ${rubricText.length}');
  
  final result = <String, dynamic>{
    'totalPoints': null,
    'criteria': <Map<String, dynamic>>[],
    'gradingScale': <Map<String, String>>[],
  };

  if (rubricText.isEmpty) {
    return result;
  }

  try {
    final lines = rubricText.split('\n');
    bool inTable = false;
    
    for (int i = 0; i < lines.length; i++) {
      try {
        String line = lines[i].trim();
        if (line.isEmpty) continue;

        // Look for table headers
        if (line.startsWith('|') && line.endsWith('|') && line.contains('Criteria')) {
          inTable = true;
          continue;
        }
        
        // Skip separator lines
        if (line.startsWith('|---') || line.startsWith('|===') || line.startsWith('|--')) {
          continue;
        }
        
        // Parse table rows
        if (inTable && line.startsWith('|') && line.endsWith('|')) {
          final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
          
          if (cells.length >= 2 && !cells[0].toLowerCase().contains('criteria')) {
            final criteriaName = cells.isNotEmpty ? cells[0] : '';
            final excellent = cells.length > 1 ? cells[1] : '';
            final good = cells.length > 2 ? cells[2] : '';
            final fair = cells.length > 3 ? cells[3] : '';
            final needsImprovement = cells.length > 4 ? cells[4] : '';
            
            final levels = <Map<String, dynamic>>[];
            if (excellent.isNotEmpty) levels.add({'level': 'Excellent', 'description': excellent, 'points': '4'});
            if (good.isNotEmpty) levels.add({'level': 'Good', 'description': good, 'points': '3'});
            if (fair.isNotEmpty) levels.add({'level': 'Fair', 'description': fair, 'points': '2'});
            if (needsImprovement.isNotEmpty) levels.add({'level': 'Needs Improvement', 'description': needsImprovement, 'points': '1'});
            
            (result['criteria'] as List<Map<String, dynamic>>).add({
              'name': criteriaName,
              'points': 4,
              'description': '',
              'levels': levels,
            });
          }
        }
        
        // End of table
        if (inTable && (!line.startsWith('|') || line.isEmpty)) {
          inTable = false;
        }
      } catch (e) {
        print('Error processing rubric line $i: $e');
        continue;
      }
    }
  } catch (e) {
    print('Error in parseRubricContent: $e');
  }

  return result;
}

// QUIZ PARSING METHOD
static List<Question> _extractQuestions(String content, String materialType) {
  if (content.isEmpty || !['quiz', 'assessment', 'test'].contains(materialType.toLowerCase())) {
    return [];
  }

  try {
    print('CailaService: Parsing questions for ${materialType.toLowerCase()}');
    print('CailaService: Content length: ${content.length}');
    
    final questions = <Question>[];
    final lines = content.split('\n');
    
    Question? currentQuestion;
    List<String> currentOptions = [];
    String currentAnswer = '';
    String currentExplanation = '';
    String currentType = 'short-answer'; // Default type
    String currentQuestionText = '';
    
    // Patterns specific to CAILA's format
    final questionNumberPattern = RegExp(r'^(\d+)\.\s+(.+)', caseSensitive: false);
    final questionLinePattern = RegExp(r'^Question:\s*(.+)', caseSensitive: false);
    final optionPattern = RegExp(r'^([A-D])\)\s+(.+)', caseSensitive: false);
    final answerKeyPattern = RegExp(r'^Answer\s+Key:\s*(.+)', caseSensitive: false);
    final explanationPattern = RegExp(r'^Explanation:\s*(.+)', caseSensitive: false);
    final stopPattern = RegExp(r'^(Implementation|Formatting|Let\s+me\s+know)', caseSensitive: false);
    
    // Question type patterns from CAILA format
    final multipleChoicePattern = RegExp(r'Multiple\s+Choice', caseSensitive: false);
    final shortAnswerPattern = RegExp(r'Short\s+Answer', caseSensitive: false);
    final wordProblemPattern = RegExp(r'Word\s+Problem', caseSensitive: false);
    final trueFalsePattern = RegExp(r'True/False', caseSensitive: false);
    final essayPattern = RegExp(r'Essay', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      try {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Check for stop patterns
        if (stopPattern.hasMatch(line)) {
          print('CailaService: Stopping question parsing at: $line');
          break;
        }

        // Check for question number (e.g., "1. Multiple Choice", "2. Short Answer")
        final questionNumberMatch = questionNumberPattern.firstMatch(line);
        if (questionNumberMatch != null) {
          // Save previous question if exists
          if (currentQuestion != null && currentQuestionText.isNotEmpty) {
            questions.add(Question(
              text: currentQuestionText,
              options: List.from(currentOptions),
              correctAnswer: currentAnswer,
              explanation: currentExplanation,
              type: currentType,
            ));
            print('CailaService: Added question ${questions.length}: ${currentQuestionText.substring(0, Math.min(50, currentQuestionText.length))}...');
          }

          // Determine question type from the line
          final typeText = questionNumberMatch.group(2)?.trim() ?? '';
          if (multipleChoicePattern.hasMatch(typeText)) {
            currentType = 'multiple-choice';
          } else if (shortAnswerPattern.hasMatch(typeText)) {
            currentType = 'short-answer';
          } else if (wordProblemPattern.hasMatch(typeText)) {
            currentType = 'word-problem';
          } else if (trueFalsePattern.hasMatch(typeText)) {
            currentType = 'true-false';
          } else if (essayPattern.hasMatch(typeText)) {
            currentType = 'essay';
          } else {
            currentType = 'short-answer'; // Default
          }

          // Reset for new question
          currentQuestion = Question(text: '', options: [], correctAnswer: '', explanation: '', type: currentType);
          currentOptions.clear();
          currentAnswer = '';
          currentExplanation = '';
          currentQuestionText = '';
          
          print('CailaService: Starting new question type: $currentType');
          continue;
        }

        // Look for "Question:" line
        final questionLineMatch = questionLinePattern.firstMatch(line);
        if (questionLineMatch != null && currentQuestion != null) {
          currentQuestionText = questionLineMatch.group(1)?.trim() ?? '';
          print('CailaService: Found question text: ${currentQuestionText.substring(0, Math.min(50, currentQuestionText.length))}...');
          continue;
        }

        // Look for options (A), B), C), D))
        final optionMatch = optionPattern.firstMatch(line);
        if (optionMatch != null && currentQuestion != null && currentType == 'multiple-choice') {
          final optionText = optionMatch.group(2)?.trim() ?? '';
          if (optionText.isNotEmpty) {
            currentOptions.add('${optionMatch.group(1)}) $optionText');
            print('CailaService: Added option: ${optionMatch.group(1)}) $optionText');
          }
          continue;
        }

        // Look for "Answer Key:" line
        final answerMatch = answerKeyPattern.firstMatch(line);
        if (answerMatch != null && currentQuestion != null) {
          currentAnswer = answerMatch.group(1)?.trim() ?? '';
          print('CailaService: Found answer: $currentAnswer');
          continue;
        }

        // Look for "Explanation:" line
        final explanationMatch = explanationPattern.firstMatch(line);
        if (explanationMatch != null && currentQuestion != null) {
          currentExplanation = explanationMatch.group(1)?.trim() ?? '';
          
          // Check if explanation continues on next lines
          int nextLineIndex = i + 1;
          while (nextLineIndex < lines.length) {
            final nextLine = lines[nextLineIndex].trim();
            if (nextLine.isEmpty) {
              nextLineIndex++;
              continue;
            }
            
            // Stop if we hit another major section
            if (questionNumberPattern.hasMatch(nextLine) || 
                answerKeyPattern.hasMatch(nextLine) ||
                stopPattern.hasMatch(nextLine)) {
              break;
            }
            
            // Add to explanation if it looks like a continuation
            if (!nextLine.startsWith('Question:') && 
                !optionPattern.hasMatch(nextLine)) {
              currentExplanation += ' $nextLine';
              i = nextLineIndex; // Skip this line in main loop
            } else {
              break;
            }
            nextLineIndex++;
          }
          
          print('CailaService: Found explanation: ${currentExplanation.substring(0, Math.min(50, currentExplanation.length))}...');
          continue;
        }

        // If we have a current question but this line doesn't match patterns,
        // it might be a continuation of the question text
        if (currentQuestion != null && currentQuestionText.isNotEmpty) {
          // Check if this looks like a continuation and not a new section
          if (!line.startsWith('Answer Key:') && 
              !line.startsWith('Explanation:') &&
              !optionPattern.hasMatch(line) &&
              !questionNumberPattern.hasMatch(line) &&
              line.length > 5) {
            
            // For word problems and essays, the question might span multiple lines
            if (currentType == 'word-problem' || currentType == 'essay' || currentType == 'true-false') {
              currentQuestionText += ' $line';
              print('CailaService: Extended question text with: ${line.substring(0, Math.min(30, line.length))}...');
            }
          }
        }

      } catch (e) {
        print('CailaService: Error processing line $i: $e');
        continue;
      }
    }

    // Add the last question if exists
    if (currentQuestion != null && currentQuestionText.isNotEmpty) {
      questions.add(Question(
        text: currentQuestionText,
        options: List.from(currentOptions),
        correctAnswer: currentAnswer,
        explanation: currentExplanation,
        type: currentType,
      ));
      print('CailaService: Added final question ${questions.length}: ${currentQuestionText.substring(0, Math.min(50, currentQuestionText.length))}...');
    }

    print('CailaService: Successfully parsed ${questions.length} questions');
    
    // Debug: Print all questions found
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      print('Question ${i + 1} (${q.type}): ${q.text}');
      if (q.options.isNotEmpty) {
        print('  Options: ${q.options.join(', ')}');
      }
      print('  Answer: ${q.correctAnswer}');
      if (q.explanation.isNotEmpty) {
        print('  Explanation: ${q.explanation.substring(0, Math.min(100, q.explanation.length))}...');
      }
    }
    
    return questions;
    
  } catch (e, stackTrace) {
    print('CailaService: Error in _extractQuestions: $e');
    print('Stack trace: $stackTrace');
    return [];
  }
}

// All the extraction methods with error handling
static String _extractTitleSafe(String content) {
  try {
    return _extractTitle(content);
  } catch (e) {
    print('Error extracting title: $e');
    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.isNotEmpty && firstLine.length < 100) {
        return firstLine;
      }
    }
    return 'Generated Assignment';
  }
}

static String _extractTitle(String content) {
  if (content.isEmpty) return '';
  
  try {
    final titlePatterns = [
      RegExp(r'^(.+?Assignment:.+?)$', multiLine: true),
      RegExp(r'^(.+?Grade.+?Assignment:.+?)$', multiLine: true), 
      RegExp(r'^#\s+(.+?)$', multiLine: true),
      RegExp(r'^##\s+(.+?)$', multiLine: true),
      RegExp(r'^Title:\s*(.+?)$', multiLine: true, caseSensitive: false),
      RegExp(r'^Assignment:\s*(.+?)$', multiLine: true, caseSensitive: false),
      RegExp(r'^(.+?Quiz)\s*$', multiLine: true, caseSensitive: false),
    ];

    for (final pattern in titlePatterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        String title = match.group(1)?.trim() ?? '';
        title = title.replaceFirst(RegExp(r'^#+\s*'), '');
        title = title.replaceFirst(RegExp(r'^(Title|Assignment):\s*', caseSensitive: false), '');
        if (title.isNotEmpty) return title;
      }
    }

    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.length < 100 && !firstLine.contains('.') && firstLine.isNotEmpty) {
        return firstLine;
      }
    }
  } catch (e) {
    print('Error in _extractTitle: $e');
  }

  return '';
}

// COMPLETE EXTRACTION METHODS WITH FULL FUNCTIONALITY

static String _extractDescription(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Instructions?:\s*((?:.|\n)*?)(?=\n\s*(?:Learning\s+Objectives?|Part\s+\d+|Questions?|Due|Rubric|Criteria|Requirements|$))', caseSensitive: false),
      RegExp(r'Description:\s*((?:.|\n)*?)(?=\n\s*(?:Learning\s+Objectives?|Part\s+\d+|Questions?|Due|Rubric|Criteria|Requirements|$))', caseSensitive: false),
      RegExp(r'Overview:\s*((?:.|\n)*?)(?=\n\s*(?:Learning\s+Objectives?|Part\s+\d+|Questions?|Due|Rubric|Criteria|Requirements|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }

    // Fallback: collect lines until we hit a major section
    final lines = content.split('\n');
    final buffer = StringBuffer();
    bool foundTitle = false;

    for (final line in lines) {
      final trimmedLine = line.trim();
      
      if (!foundTitle && _isTitle(trimmedLine)) {
        foundTitle = true;
        continue;
      }
      
      if (foundTitle) {
        // Stop when we hit major sections
        if (RegExp(r'^(\*\*)?Course(\*\*)?:', caseSensitive: false).hasMatch(trimmedLine) ||
            RegExp(r'^(\*\*)?Grade\s+Level(\*\*)?:', caseSensitive: false).hasMatch(trimmedLine) ||
            RegExp(r'^(\*\*)?Duration(\*\*)?:', caseSensitive: false).hasMatch(trimmedLine) ||
            RegExp(r'^Learning\s+Objectives?', caseSensitive: false).hasMatch(trimmedLine) ||
            RegExp(r'^Assignment\s+Instructions?', caseSensitive: false).hasMatch(trimmedLine) ||
            RegExp(r'^Part\s+\d+', caseSensitive: false).hasMatch(trimmedLine) ||
            RegExp(r'^Questions?\s*:', caseSensitive: false).hasMatch(trimmedLine)) {
          break;
        }
        
        if (trimmedLine.isNotEmpty) {
          buffer.writeln(trimmedLine);
        }
      }
    }

    return buffer.toString().trim();
  } catch (e) {
    print('Error in _extractDescription: $e');
    return '';
  }
}

static String _extractRubric(String content) {
  if (content.isEmpty) return '';
  
  print('CailaService: Extracting rubric from content length: ${content.length}');
  
  try {
    final startMarkers = ['Assessment Rubric', 'Rubric', 'Grading Rubric', 'Assessment Criteria', '| Criteria |'];
    final endMarkers = ['Resources & Guidance', 'Resources', 'Implementation', 'Bonus Challenge', 'This assignment is ready', 'Let me know if'];
    
    int startIndex = -1;
    for (String marker in startMarkers) {
      int index = content.indexOf(marker);
      if (index != -1) {
        startIndex = index;
        break;
      }
    }
    
    if (startIndex == -1) return '';
    
    int endIndex = content.length;
    for (String marker in endMarkers) {
      int index = content.indexOf(marker, startIndex);
      if (index != -1 && index < endIndex) {
        endIndex = index;
      }
    }
    
    if (endIndex > startIndex) {
      return content.substring(startIndex, endIndex).trim();
    }
  } catch (e) {
    print('Error in _extractRubric: $e');
  }
  
  return '';
}

static String _extractDueDate(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Due\s+Date?:\s*(.+?)(?:\n|$)', multiLine: true, caseSensitive: false),
      RegExp(r'Deadline:\s*(.+?)(?:\n|$)', multiLine: true, caseSensitive: false),
      RegExp(r'Submit\s+by:\s*(.+?)(?:\n|$)', multiLine: true, caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractDueDate: $e');
  }

  return '';
}

static String _extractAdditionalNotes(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Notes?:\s*((?:.|\n)*?)(?:\n\s*$|$)', caseSensitive: false),
      RegExp(r'Additional\s+Information:\s*((?:.|\n)*?)(?:\n\s*$|$)', caseSensitive: false),
      RegExp(r'Important:\s*((?:.|\n)*?)(?:\n\s*$|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractAdditionalNotes: $e');
  }

  return '';
}

static List<AssignmentRequirement> _extractRequirements(String content) {
  if (content.isEmpty) return [];
  
  try {
    final requirements = <AssignmentRequirement>[];
    final lines = content.split('\n');
    
    bool inRequirementsSection = false;
    final patterns = [
      RegExp(r'Requirements?:', caseSensitive: false),
      RegExp(r'Objectives?:', caseSensitive: false),
      RegExp(r'Goals?:', caseSensitive: false),
      RegExp(r'What you need to do:', caseSensitive: false),
    ];
    
    for (final line in lines) {
      try {
        final trimmedLine = line.trim();
        
        for (final pattern in patterns) {
          if (pattern.hasMatch(trimmedLine)) {
            inRequirementsSection = true;
            break;
          }
        }
        
        if (inRequirementsSection) {
          final reqMatch = RegExp(r'^[•\-\*]?\s*(\d+[\.\)]?)?\s*(.+)').firstMatch(trimmedLine);
          if (reqMatch != null && reqMatch.groupCount >= 2) {
            final reqText = reqMatch.group(2)?.trim() ?? '';
            if (reqText.length > 10) {
              requirements.add(AssignmentRequirement(
                title: reqText.length > 50 ? '${reqText.substring(0, 50)}...' : reqText,
                description: reqText,
              ));
            }
          }
          
          if (RegExp(r'^(Due|Submission|Grading|Rubric):', caseSensitive: false).hasMatch(trimmedLine)) {
            break;
          }
        }
      } catch (e) {
        print('Error processing requirement line: $e');
        continue;
      }
    }
    
    return requirements;
  } catch (e) {
    print('Error in _extractRequirements: $e');
    return [];
  }
}

static List<String> _extractDeliverables(String content) {
  if (content.isEmpty) return [];
  
  try {
    final deliverables = <String>[];
    final lines = content.split('\n');
    
    final patterns = [
      RegExp(r'Deliverables?:', caseSensitive: false),
      RegExp(r'What to submit:', caseSensitive: false),
      RegExp(r'Submit the following:', caseSensitive: false),
      RegExp(r'You must provide:', caseSensitive: false),
    ];
    
    bool inDeliverablesSection = false;
    
    for (final line in lines) {
      try {
        final trimmedLine = line.trim();
        
        for (final pattern in patterns) {
          if (pattern.hasMatch(trimmedLine)) {
            inDeliverablesSection = true;
            break;
          }
        }
        
        if (inDeliverablesSection) {
          final delivMatch = RegExp(r'^[•\-\*]?\s*(\d+[\.\)]?)?\s*(.+)').firstMatch(trimmedLine);
          if (delivMatch != null && delivMatch.groupCount >= 2) {
            final delivText = delivMatch.group(2)?.trim() ?? '';
            if (delivText.length > 5) {
              deliverables.add(delivText);
            }
          }
          
          if (RegExp(r'^(Due|Grading|Rubric):', caseSensitive: false).hasMatch(trimmedLine)) {
            break;
          }
        }
      } catch (e) {
        print('Error processing deliverable line: $e');
        continue;
      }
    }
    
    return deliverables;
  } catch (e) {
    print('Error in _extractDeliverables: $e');
    return [];
  }
}

static String _extractSubmissionRequirements(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Submission\s+Requirements?:\s*((?:.|\n)*?)(?=\n\s*(?:Due|Grading|Rubric|$))', caseSensitive: false),
      RegExp(r'How to submit:\s*((?:.|\n)*?)(?=\n\s*(?:Due|Grading|Rubric|$))', caseSensitive: false),
      RegExp(r'Submit via:\s*((?:.|\n)*?)(?=\n\s*(?:Due|Grading|Rubric|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractSubmissionRequirements: $e');
  }

  return '';
}

static String _extractGradingCriteria(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Grading\s+Criteria:\s*((?:.|\n)*?)(?=\n\s*(?:Due|Submission|Rubric|$))', caseSensitive: false),
      RegExp(r"How you'll be graded:\s*((?:.|\n)*?)(?=\n\s*(?:Due|Submission|Rubric|$))", caseSensitive: false),
      RegExp(r'Assessment\s+Criteria:\s*((?:.|\n)*?)(?=\n\s*(?:Due|Submission|Rubric|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractGradingCriteria: $e');
  }

  return '';
}

static String _extractLearningObjectives(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Learning\s+Objectives?\s*:?\s*((?:.|\n)*?)(?=\n\s*(?:Assignment\s+Instructions?|Part\s+\d+|Questions?|Assessment|Rubric|Resources?|$))', caseSensitive: false),
      RegExp(r'Objectives?\s*:?\s*((?:.|\n)*?)(?=\n\s*(?:Assignment\s+Instructions?|Part\s+\d+|Questions?|Assessment|Rubric|Resources?|$))', caseSensitive: false),
      RegExp(r'By\s+the\s+end\s+of\s+this\s+assignment[,\s]+((?:.|\n)*?)(?=\n\s*(?:Assignment\s+Instructions?|Part\s+\d+|Questions?|Assessment|Rubric|Resources?|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractLearningObjectives: $e');
  }

  return '';
}

static String _extractAssignmentInstructions(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Assignment\s+Instructions?\s*:?\s*((?:.|\n)*?)(?=\n\s*(?:Part\s+\d+|Questions?|Assessment|Rubric|Resources?|Implementation|$))', caseSensitive: false),
      RegExp(r'Instructions?\s*:?\s*((?:.|\n)*?)(?=\n\s*(?:Part\s+\d+|Questions?|Assessment|Rubric|Resources?|Implementation|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractAssignmentInstructions: $e');
  }

  return '';
}

static String _extractCourseMeta(String content) {
  if (content.isEmpty) return '';
  
  try {
    final buffer = StringBuffer();
    final lines = content.split('\n');
    
    for (String line in lines) {
      final trimmedLine = line.trim();
      if (RegExp(r'^(\*\*)?Course(\*\*)?\s*:', caseSensitive: false).hasMatch(trimmedLine)) {
        buffer.writeln(trimmedLine);
      } else if (RegExp(r'^(\*\*)?Grade\s+Level(\*\*)?\s*:', caseSensitive: false).hasMatch(trimmedLine)) {
        buffer.writeln(trimmedLine);
      } else if (RegExp(r'^(\*\*)?Topic(\*\*)?\s*:', caseSensitive: false).hasMatch(trimmedLine)) {
        buffer.writeln(trimmedLine);
      }
    }
    
    return buffer.toString().trim();
  } catch (e) {
    print('Error in _extractCourseMeta: $e');
    return '';
  }
}

static String _extractDuration(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'(\*\*)?Duration(\*\*)?\s*:\s*(.+?)(?:\n|$)', multiLine: true, caseSensitive: false),
      RegExp(r'(\*\*)?Time(\*\*)?\s*:\s*(.+?)(?:\n|$)', multiLine: true, caseSensitive: false),
      RegExp(r'(\d+[-–]\d+\s*minutes?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        if (match.groupCount >= 3 && match.group(3) != null) {
          return match.group(3)!.trim();
        } else if (match.groupCount >= 1 && match.group(1) != null) {
          return match.group(1)!.trim();
        }
      }
    }
  } catch (e) {
    print('Error in _extractDuration: $e');
  }

  return '';
}

static String _extractResourcesGuidance(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Resources?\s*&?\s*Guidance\s*:?\s*((?:.|\n)*?)(?=\n\s*(?:Implementation|Bonus|Assessment|$))', caseSensitive: false),
      RegExp(r'Resources?\s*:?\s*((?:.|\n)*?)(?=\n\s*(?:Implementation|Bonus|Assessment|$))', caseSensitive: false),
      RegExp(r'Guidance\s*:?\s*((?:.|\n)*?)(?=\n\s*(?:Implementation|Bonus|Assessment|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractResourcesGuidance: $e');
  }

  return '';
}

static String _extractImplementationNotes(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Implementation\s+Notes?\s+for\s+Teachers?\s*:?\s*((?:.|\n)*?)(?=\n\s*$)', caseSensitive: false),
      RegExp(r'Implementation\s*:?\s*((?:.|\n)*?)(?=\n\s*$)', caseSensitive: false),
      RegExp(r'Teacher\s+Notes?\s*:?\s*((?:.|\n)*?)(?=\n\s*$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractImplementationNotes: $e');
  }

  return '';
}

static List<AssignmentPart> _extractAssignmentParts(String content) {
  if (content.isEmpty) return [];
  
  try {
    final parts = <AssignmentPart>[];
    final lines = content.split('\n');
    
    AssignmentPart? currentPart;
    bool inPartContent = false;
    
    for (int i = 0; i < lines.length; i++) {
      try {
        final line = lines[i].trim();
        
        // Check for part headers like "Part 1:", "Part 2:", etc.
        final partMatch = RegExp(r'^Part\s+(\d+)\s*:\s*(.+?)(?:\s*\(\s*(\d+)\s*minutes?\s*\))?', caseSensitive: false).firstMatch(line);
        if (partMatch != null) {
          // Save previous part if exists
          if (currentPart != null) {
            parts.add(currentPart);
          }
          
          // Start new part
          final partNumber = int.tryParse(partMatch.group(1) ?? '1') ?? 1;
          final partTitle = partMatch.group(2)?.trim() ?? '';
          final partDuration = partMatch.group(3) != null ? '${partMatch.group(3)} minutes' : '';
          
          currentPart = AssignmentPart(
            number: partNumber,
            title: partTitle,
            duration: partDuration,
            content: '',
            tasks: [],
            questions: [],
          );
          inPartContent = true;
          continue;
        }
        
        // Check for end of parts section
        if (RegExp(r'^(Assessment|Rubric|Resources?|Implementation|Bonus|Questions?)', caseSensitive: false).hasMatch(line)) {
          inPartContent = false;
          if (currentPart != null) {
            parts.add(currentPart);
            currentPart = null;
          }
          continue;
        }
        
        // Add content to current part
        if (inPartContent && currentPart != null) {
          if (line.isNotEmpty) {
            if (currentPart.content.isNotEmpty) {
              currentPart.content += '\n';
            }
            currentPart.content += line;
            
            // Extract tasks
            if (RegExp(r'^Task\s*:', caseSensitive: false).hasMatch(line)) {
              // Next lines are tasks until we hit another section
              for (int j = i + 1; j < lines.length && j - i < 20; j++) { // Limit look-ahead
                final taskLine = lines[j].trim();
                if (taskLine.isEmpty) continue;
                if (RegExp(r'^(Task|Questions?|Challenge|Part\s+\d+|Assessment):', caseSensitive: false).hasMatch(taskLine)) {
                  break;
                }
                if (taskLine.startsWith('-') || taskLine.startsWith('•')) {
                  currentPart.tasks.add(taskLine.substring(1).trim());
                }
              }
            }
            
            // Extract questions from parts
            final questionMatch = RegExp(r'^(\d+)\.\s+(.+)').firstMatch(line);
            if (questionMatch != null && questionMatch.groupCount >= 2) {
              final questionNumber = int.tryParse(questionMatch.group(1) ?? '0') ?? 0;
              final questionText = questionMatch.group(2)?.trim() ?? '';
              if (questionText.isNotEmpty) {
                currentPart.questions.add(AssignmentQuestion(
                  number: questionNumber,
                  text: questionText,
                ));
              }
            }
          }
        }
      } catch (e) {
        print('Error processing line $i in _extractAssignmentParts: $e');
        continue; // Skip this line and continue
      }
    }
    
    // Add last part if exists
    if (currentPart != null) {
      parts.add(currentPart);
    }
    
    return parts;
  } catch (e) {
    print('Error in _extractAssignmentParts: $e');
    return [];
  }
}

static String _extractEssayPrompt(String content, String materialType) {
  if (content.isEmpty || materialType.toLowerCase() != 'essay') return '';
  
  try {
    final patterns = [
      RegExp(r'Essay\s+Prompt:\s*((?:.|\n)*?)(?=\n\s*(?:Requirements|Length|Sources|Due|$))', caseSensitive: false),
      RegExp(r'Prompt:\s*((?:.|\n)*?)(?=\n\s*(?:Requirements|Length|Sources|Due|$))', caseSensitive: false),
      RegExp(r'Topic:\s*((?:.|\n)*?)(?=\n\s*(?:Requirements|Length|Sources|Due|$))', caseSensitive: false),
      RegExp(r'Write about:\s*((?:.|\n)*?)(?=\n\s*(?:Requirements|Length|Sources|Due|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractEssayPrompt: $e');
  }

  return '';
}

static String _extractRequiredLength(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Length:\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'Word\s+count:\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'Page\s+length:\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'(\d+[-–]\d+\s*(?:words?|pages?))', caseSensitive: false),
      RegExp(r'(minimum\s+\d+\s*(?:words?|pages?))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractRequiredLength: $e');
  }

  return '';
}

static String _extractThesisRequirements(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Thesis\s+Requirements?:\s*((?:.|\n)*?)(?=\n\s*(?:Sources|Structure|Due|$))', caseSensitive: false),
      RegExp(r'Thesis\s+Statement:\s*((?:.|\n)*?)(?=\n\s*(?:Sources|Structure|Due|$))', caseSensitive: false),
      RegExp(r'Your\s+argument\s+should:\s*((?:.|\n)*?)(?=\n\s*(?:Sources|Structure|Due|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractThesisRequirements: $e');
  }

  return '';
}

static String _extractSourceRequirements(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Sources?\s+Requirements?:\s*((?:.|\n)*?)(?=\n\s*(?:Structure|Format|Due|$))', caseSensitive: false),
      RegExp(r'Citations?:\s*((?:.|\n)*?)(?=\n\s*(?:Structure|Format|Due|$))', caseSensitive: false),
      RegExp(r'References?:\s*((?:.|\n)*?)(?=\n\s*(?:Structure|Format|Due|$))', caseSensitive: false),
      RegExp(r'Use\s+at\s+least\s+(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'(\d+[-–]\d+\s*(?:sources?|references?))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractSourceRequirements: $e');
  }

  return '';
}

static String _extractStructureGuidelines(String content) {
  if (content.isEmpty) return '';
  
  try {
    final patterns = [
      RegExp(r'Structure:\s*((?:.|\n)*?)(?=\n\s*(?:Format|Due|Grading|$))', caseSensitive: false),
      RegExp(r'Organization:\s*((?:.|\n)*?)(?=\n\s*(?:Format|Due|Grading|$))', caseSensitive: false),
      RegExp(r'Essay\s+Structure:\s*((?:.|\n)*?)(?=\n\s*(?:Format|Due|Grading|$))', caseSensitive: false),
      RegExp(r'Format:\s*((?:.|\n)*?)(?=\n\s*(?:Due|Grading|$))', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty) return extracted;
      }
    }
  } catch (e) {
    print('Error in _extractStructureGuidelines: $e');
  }

  return '';
}

// Helper method to check if a line is a title
static bool _isTitle(String line) {
  try {
    final cleanLine = line.trim();
    return cleanLine.length < 100 && 
           (cleanLine.startsWith('#') || 
            cleanLine.toLowerCase().contains('title:') ||
            cleanLine.toLowerCase().contains('assignment:') ||
            cleanLine.toLowerCase().contains('quiz') ||
            cleanLine.toLowerCase().contains('rubric'));
  } catch (e) {
    print('Error in _isTitle: $e');
    return false;
  }
}

static Future<String> resumeChatSession({
    required String authToken,
    required String prompt,
    required String sessionId,
    required List<Map<String, String>> conversationHistory,
    String? courseId,
  }) async {
    try {
      // Use the resume API endpoint that handles context
      final response = await CailaApi.resumeChatSession(
        authToken: authToken,
        prompt: prompt,
        sessionId: sessionId,
        conversationHistory: conversationHistory,
        courseId: courseId,
      );
      
      if (response['success'] == true) {
        return response['response'] ?? 'No response received';
      } else {
        final error = response['error'] ?? 'Resume chat failed';
        throw Exception(error);
      }
    } catch (e) {
      // Provide user-friendly error messages for resume chat
      if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        throw Exception('⏱️ Resume request timed out.\n\nPlease try:\n• A shorter message\n• A simpler question\n• Waiting a moment and trying again');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('🔐 Session expired. Please log in again.');
      } else if (e.toString().contains('500') || e.toString().contains('Internal Server Error')) {
        throw Exception('🛠️ Server error. Please try again in a few moments.');
      } else if (e.toString().contains('Network error') || e.toString().contains('connection')) {
        throw Exception('🌐 Network connection issue. Please check your internet connection and try again.');
      }
      
      // For other errors, provide the original message but make it more user-friendly
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception('❌ $errorMessage');
    }
  }
}