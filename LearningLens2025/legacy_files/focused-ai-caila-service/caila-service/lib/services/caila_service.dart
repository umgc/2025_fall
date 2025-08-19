import '../apis/caila_api.dart';
import '../models/course.dart';
import '../models/assignment.dart';

class CailaService {
  // Chat functionality
  static Future<String> chatWithCaila({
    required String authToken,
    required String prompt,
    String? courseId,
    String? studentId,
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await CailaApi.chat(
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
        throw Exception(response['error'] ?? 'Chat failed');
      }
    } catch (e) {
      throw Exception('Failed to chat with CAILA: $e');
    }
  }

  // Material generation
  static Future<String> generateMaterial({
    required String authToken,
    required String prompt,
    String? materialType,
    String? courseId,
    String? title,
  }) async {
    try {
      final response = await CailaApi.generateMaterial(
        authToken: authToken,
        prompt: prompt,
        materialType: materialType,
        courseId: courseId,
        title: title,
      );
      
      if (response['success'] == true) {
        return response['response'] ?? 'No material generated';
      } else {
        throw Exception(response['error'] ?? 'Material generation failed');
      }
    } catch (e) {
      throw Exception('Failed to generate material: $e');
    }
  }

  // Enhanced rubric generation for assignments
  static Future<String> generateRubric({
    required String authToken,
    required String assignmentPrompt,
    String? courseId,
  }) async {
    final rubricPrompt = '''
Create a comprehensive rubric for the following assignment:

$assignmentPrompt

Please include:
- Clear criteria and performance levels
- Point values for each criterion
- Specific descriptors for each performance level
- Total possible points
''';

    return await generateMaterial(
      authToken: authToken,
      prompt: rubricPrompt,
      materialType: 'Rubric',
      courseId: courseId,
      title: 'Assignment Rubric',
    );
  }

  // Assignment evaluation
  static Future<String> evaluateAnswer({
    required String authToken,
    required String rubric,
    required String studentAnswer,
    String? courseId,
  }) async {
    final evaluationPrompt = '''
You are an AI assistant evaluating a student's work. Here is the rubric:

$rubric

Here is the student's answer:

$studentAnswer

Please evaluate the answer against the rubric and provide:
1. A score for each criterion
2. Constructive feedback highlighting strengths
3. Specific areas for improvement
4. Overall score and grade recommendation
5. Encouraging comments to help the student learn

Be fair, constructive, and educational in your feedback.
''';

    return await chatWithCaila(
      authToken: authToken,
      prompt: evaluationPrompt,
      courseId: courseId,
    );
  }

  // Chat history management
  static Future<List<Map<String, dynamic>>> getChatHistory({
    required String authToken,
  }) async {
    try {
      final response = await CailaApi.getChatHistory(authToken: authToken);
      
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

  // Context-aware prompts for different material types
  static String enhancePromptForMaterialType({
    required String materialType,
    required String prompt,
    String? courseContext,
  }) {
    String systemContext = '';
    
    switch (materialType.toLowerCase()) {
      case 'quiz':
        systemContext = '''
You are an educational content creator specializing in quiz generation. 
Create engaging, clear, and educationally sound quiz questions that:
- Test understanding, not just memorization
- Include a variety of question types
- Provide clear instructions
- Are appropriate for the educational level
''';
        break;
      case 'assignment':
        systemContext = '''
You are an educational content creator specializing in assignment design.
Create meaningful, challenging, and pedagogically effective assignments that:
- Have clear learning objectives
- Include step-by-step instructions
- Provide assessment criteria
- Encourage critical thinking
''';
        break;
      case 'lesson plan':
      case 'lesson':
        systemContext = '''
You are an educational content creator specializing in lesson planning.
Create structured, engaging, and comprehensive lesson content that:
- Has clear learning objectives
- Includes diverse teaching methods
- Provides assessment opportunities
- Engages different learning styles
''';
        break;
      case 'worksheet':
        systemContext = '''
You are an educational content creator specializing in worksheet design.
Create practical, interactive, and skill-building worksheet activities that:
- Reinforce key concepts
- Include varied exercise types
- Provide clear instructions
- Build skills progressively
''';
        break;
      default:
        systemContext = '''
You are an educational content creator. Create high-quality educational content that:
- Is pedagogically sound
- Engages learners effectively
- Meets educational standards
- Is ready for classroom use
''';
    }

    String enhancedPrompt = systemContext;
    
    if (courseContext != null && courseContext.isNotEmpty) {
      enhancedPrompt += '\n\nCourse context: $courseContext';
    }
    
    enhancedPrompt += '\n\nUser request: $prompt';
    enhancedPrompt += '\n\nPlease create content that is educationally appropriate, well-structured, and ready for use.';
    
    return enhancedPrompt;
  }
}