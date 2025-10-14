import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// ⚠️ This version of AIFileService is currently set up to use OpenAI GPT API.
/// To switch back to HuggingFace, revert model name and API key env var in each method.
class AIFileService {
  static const _openaiChatUrl = 'https://api.openai.com/v1/chat/completions';

  /// Extracts plain text from an in-memory PDF (bytes).
  static Future<String> extractTextFromPDF(Uint8List fileBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      // Rethrow so caller can show an error/snackbar
      rethrow;
    }
  }

  // --- Helper that posts to OpenAI chat endpoint and returns the raw content string ---
  static Future<String> _postChatCompletion({
    required String openaiKey,
    required Map<String, dynamic> payload,
    String url = _openaiChatUrl,
    int timeoutSeconds = 60,
  }) async {
    final dio =
        Dio(BaseOptions(connectTimeout: Duration(seconds: timeoutSeconds)));
    late Response resp;
    try {
      resp = await dio.post(
        url,
        options: Options(headers: {
          'Authorization': 'Bearer $openaiKey',
          'Content-Type': 'application/json',
        }),
        data: payload,
      );
    } catch (e) {
      throw Exception('❌ OpenAI API request failed: $e');
    }

    // Inspect common OpenAI shapes and return a string that is the model content
    final data = resp.data;

    // 1) router/chat/completions usually returns: { choices: [ { message: { content: "..." } } ] }
    try {
      if (data is Map && data.containsKey('choices')) {
        final choices = data['choices'];
        if (choices is List && choices.isNotEmpty) {
          final first = choices[0];
          if (first is Map && first.containsKey('message')) {
            final message = first['message'];
            if (message is Map && message.containsKey('content')) {
              return message['content'].toString();
            }
          }
        }
      }

      // 2) model-specific inference endpoints sometimes return generated_text
      if (data is Map && data.containsKey('generated_text')) {
        return data['generated_text'].toString();
      }

      // 3) fallback: stringify entire response
      return jsonEncode(data);
    } catch (e) {
      // If any unexpected structure, return direct stringified body
      return resp.data.toString();
    }
  }

  /// Generic helper to try parsing the model content as JSON and convert to typed lists.
  static List<T> _parseJsonList<T>(String content, T Function(dynamic) mapper) {
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded.map(mapper).toList();
    }
    throw Exception(
        'Expected JSON array from model but got: ${decoded.runtimeType}');
  }

  /// Generate multiple choice quiz questions. Returns list of maps:
  /// { "question": "...", "options": ["A","B","C","D"], "answer": <index> }
  static Future<List<Map<String, dynamic>>> generateGameFromText(String text,
      {int questionCount = 5}) async {
    final openaiKey = dotenv.env['openai_apikey'];
    print('🧪 Loaded OpenAI Key: $openaiKey');
    if (openaiKey == null || openaiKey.isEmpty) {
      throw Exception('Missing OpenAI API Key (openai_apikey in .env)');
    }

    final systemPrompt =
        'You are an educational game designer. From the given text, generate exactly $questionCount multiple-choice questions. '
        'Respond with a VALID JSON ARRAY ONLY (no extra text) where each item has: '
        '{"question": "...", "options": ["optA", "optB", "optC", "optD"], "answer": <index>} '
        'The "answer" should be the index (0-3) of the correct option.\n\n'
        'Input: $text';

    final payload = {
      "model": "gpt-3.5-turbo",
      "stream": false,
      "messages": [
        {"role": "user", "content": systemPrompt}
      ]
    };

    final raw =
        await _postChatCompletion(openaiKey: openaiKey, payload: payload);

    try {
      final parsedList = _parseJsonList<Map<String, dynamic>>(raw, (item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        throw Exception('Item is not an object');
      });
      print('✅ Used OpenAI GPT model.');
      print('✅ Game generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'OpenAI response was not valid JSON (generateGameFromText). $e\nResponse:\n$raw');
    }
  }

  /// Generate flashcards: returns List<Map<String,String>> with {"term","definition"}
  static Future<List<Map<String, String>>> generateFlashcardsFromText(
      String text,
      {int cardCount = 5}) async {
    final openaiKey = dotenv.env['openai_apikey'];
    print('🧪 Loaded OpenAI Key: $openaiKey');
    if (openaiKey == null || openaiKey.isEmpty) {
      throw Exception('Missing OpenAI API Key (openai_apikey in .env)');
    }

    final systemPrompt = '''
You are an educational assistant. Analyze the following input content and generate exactly $cardCount educational flashcards.

Each flashcard must contain:
- "term": a keyword or phrase that will be on side A
- "definition": a sentence or explanation that will be on side B

Return a valid JSON array ONLY. Do not include any extra text, explanation, or formatting outside the JSON. Ensure all values are strings.

Example format:
[
  {"term": "Gravity", "definition": "The force that pulls objects toward the Earth."},
  {"term": "Friction", "definition": "The resistance force between two surfaces in contact."}
]

Input:
$text
''';

    final payload = {
      "model": "gpt-3.5-turbo",
      "stream": false,
      "messages": [
        {"role": "user", "content": systemPrompt}
      ]
    };

    final raw =
        await _postChatCompletion(openaiKey: openaiKey, payload: payload);
    print('🧪 RAW Flashcard JSON: $raw');
    // Extract only the first valid JSON array to avoid malformed multi-array issues
    final match = RegExp(r'\[\s*{[\s\S]*?}\s*\]').firstMatch(raw);
    final safeJson = match?.group(0);
    if (safeJson == null) {
      throw Exception("Failed to extract JSON array from response:\n$raw");
    }

    try {
      final parsedList = _parseJsonList<Map<String, String>>(safeJson!, (item) {
        if (item is Map)
          return Map<String, String>.from(
              item.map((k, v) => MapEntry(k.toString(), v.toString())));
        throw Exception('Item is not an object');
      });
      print('✅ Used OpenAI GPT model.');
      print('✅ Flashcards generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'OpenAI response was not valid JSON (generateFlashcardsFromText). $e\nResponse:\n$raw');
    }
  }

  /// Generate matching pairs: returns List<Map<String,String>> with {"term","match"}
  static Future<List<Map<String, String>>> generateMatchingPairsFromText(
      String text,
      {int pairCount = 5}) async {
    final openaiKey = dotenv.env['openai_apikey'];
    print('🧪 Loaded OpenAI Key: $openaiKey');
    if (openaiKey == null || openaiKey.isEmpty) {
      throw Exception('Missing OpenAI API Key (openai_apikey in .env)');
    }

    final systemPrompt = '''
You are an educational assistant. From the given lesson text, extract exactly $pairCount concept-definition pairs as a matching game.

Each item must be a JSON object with:
- "term": a keyword or concept
- "match": a short explanation or definition

Return a single JSON array with exactly $pairCount objects and no other text.

Example:
[
  {"term": "Gravity", "match": "A force that pulls objects toward Earth."},
  {"term": "Friction", "match": "A force that resists motion between surfaces."}
]

Input:
$text
''';

    final payload = {
      "model": "gpt-3.5-turbo",
      "stream": false,
      "messages": [
        {"role": "user", "content": systemPrompt}
      ]
    };

    final raw =
        await _postChatCompletion(openaiKey: openaiKey, payload: payload);
    print('🧪 RAW Matching JSON: $raw');

    // Extract only the first valid JSON array to avoid malformed multi-array issues
    final match = RegExp(r'\[\s*{[\s\S]*?}\s*\]').firstMatch(raw);
    final safeJson = match?.group(0);
    if (safeJson == null) {
      throw Exception("Failed to extract JSON array from response:\n$raw");
    }

    try {
      final parsedList = _parseJsonList<Map<String, String>>(safeJson!, (item) {
        if (item is Map) {
          final term = item['term']?.toString();
          final match = item['match']?.toString();
          return {
            'term': term ?? '⚠️ No term',
            'match': match ?? '⚠️ No match'
          };
        }
        throw Exception('Item is not an object');
      });
      print('✅ Used OpenAI GPT model.');
      print('✅ Matching pairs generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'OpenAI response was not valid JSON (generateMatchingPairsFromText). $e\nResponse:\n$raw');
    }
  }

  /// Generate math questions: returns List<Map<String,String>> with {"question","answer"}
  static Future<List<Map<String, String>>> generateMathQuestionsFromText(
      String text,
      {int questionCount = 5}) async {
    final openaiKey = dotenv.env['openai_apikey'];
    print('🧪 Loaded OpenAI Key: $openaiKey');
    if (openaiKey == null || openaiKey.isEmpty) {
      throw Exception('Missing OpenAI API Key (openai_apikey in .env)');
    }

    final systemPrompt =
        'You are a math teacher assistant. From the given input text, generate exactly $questionCount math problems. '
        'Each item should have {"question":"...","answer":"..."} and you must respond with a VALID JSON ARRAY ONLY.\n\nInput: $text';

    final payload = {
      "model": "gpt-3.5-turbo",
      "stream": false,
      "messages": [
        {"role": "user", "content": systemPrompt}
      ]
    };

    final raw =
        await _postChatCompletion(openaiKey: openaiKey, payload: payload);

    try {
      final parsedList = _parseJsonList<Map<String, String>>(raw, (item) {
        if (item is Map)
          return Map<String, String>.from(
              item.map((k, v) => MapEntry(k.toString(), v.toString())));
        throw Exception('Item is not an object');
      });
      print('✅ Used OpenAI GPT model.');
      print('✅ Math questions generated: $parsedList');
      return parsedList;
    } catch (e) {
      throw Exception(
          'OpenAI response was not valid JSON (generateMathQuestionsFromText). $e\nResponse:\n$raw');
    }
  }
}
