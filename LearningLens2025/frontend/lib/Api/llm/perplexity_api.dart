import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/services/api_service.dart';

class PerplexityLLM implements LLM {
  @override
  final String apiKey;

  @override
  final String url = 'https://api.perplexity.ai/chat/completions';
  @override
  final String model = 'sonar';
  @override
  final double tokenCount = 0.25;
  @override
  final int contextSize;
  @override
  final int maxOutputTokens;

  final parsedUrl = Uri.parse('https://api.perplexity.ai/chat/completions');

  PerplexityLLM(
    this.apiKey, {
    int? contextSize,
    int? maxOutputTokens,
  })  : contextSize = contextSize ?? 4000,
        maxOutputTokens = maxOutputTokens ?? 1000;

  Map<String, dynamic> convertHttpRespToJson(String httpResponseString) {
    return (json.decode(httpResponseString) as Map<String, dynamic>);
  }

  //
  String getPostBody(String queryMessage) {
    return jsonEncode({
      // 'model': 'llama-3-sonar-large-32k-online',
      //'model': 'llama-3.1-sonar-large-128k-chat',
      'model': model,
      'messages': [
        {'role': 'system', 'content': 'Be precise and concise'},
        {'content': queryMessage, 'role': 'user'}
      ]
    });
  }

  //
  Map<String, String> getPostHeaders() {
    return ({
      'accept': 'application/json',
      'content-type': 'application/json',
      'authorization': 'Bearer $apiKey',
    });
  }

  //
  Uri getPostUrl() => Uri.https('api.perplexity.ai', '/chat/completions');

  //
  Future<String> postMessage(
      Uri url, Map<String, String> postHeaders, Object postBody) async {
    final httpPackageResponse =
        await ApiService().httpPost(url, headers: postHeaders, body: postBody);

    if (httpPackageResponse.statusCode != 200) {
      print('Failed to retrieve the http package!');
      print('statusCode :  ${httpPackageResponse.statusCode}');
      print('body:  ${httpPackageResponse.body}');
      return "";
    }

    print("In postmessage : ${httpPackageResponse.body}");
    return httpPackageResponse.body;
  }

  List<String> parseQueryResponse(String resp) {
    // ignore: prefer_adjacent_string_concatenation
    String quizRegExp =
        // r'(<\?xml.*?\?>\s*<quiz>(\s*.*?<question>\s*.*?<text>\s*(.*?)</text>\s*.*?<options>(\s*.*?<option>\s*(.*?)</option>)+\s*</options>\s*.*?<answer>\s*(.*?)</answer>\s*.*?</question>)+\s*</quiz>)';
        r'(<\?xml.*?\?>\s*<quiz>.*?</quiz>)';

    RegExp exp = RegExp(quizRegExp);
    String respNoNewlines = resp.replaceAll('\n', '');
    Iterable<RegExpMatch> matches = exp.allMatches(respNoNewlines);
    List<String> parsedResp = [];

    print("Parsing the query response - matches: $matches");

    for (final m in matches) {
      if (m.group(0) != null) {
        parsedResp.add(m.group(0)!);

        print("This is a match : ${m.group(0)}");
        print("Number of groups in the match: ${m.groupCount}");
        print("parsedResp : $parsedResp");
      }
    }

    return parsedResp;
  }

  //
  @override
  Future<String> postToLlm(String queryPrompt) async {
    var resp = "";

    // use the following test query so Perplexity doesn't charge
    // 'How many stars are there in our galaxy?'
    if (queryPrompt.isNotEmpty) {
      resp = await queryAI(queryPrompt);
    }
    return resp;
  }

  //
  Future<String> queryAI(String query) async {
    final postHeaders = getPostHeaders();
    final postBody = getPostBody(query);
    final httpPackageUrl = getPostUrl();

    final httpPackageRespString =
        await postMessage(httpPackageUrl, postHeaders, postBody);

    final httpPackageResponseJson =
        convertHttpRespToJson(httpPackageRespString);

    var retResponse = "";
    for (var respChoice in httpPackageResponseJson['choices']) {
      retResponse += respChoice['message']['content'];
    }
    // print("In queryAI - content :  $retResponse");
    return retResponse;
  }

  @override
  Future<String> getChatResponse(String prompt) async {
    final postHeaders = getPostHeaders();
    final postBody = getPostBody(prompt);
    final httpPackageUrl = getPostUrl();

    try {
      // Make the POST request to the chat completions endpoint
      var response = await ApiService()
          .httpPost(httpPackageUrl, headers: postHeaders, body: postBody);

      // Check for successful response
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['choices'][0]['message']['content']
            .trim(); // Return the chat response
      } else {
        // Log the error response and handle failure cases
        print('Failed to fetch response. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return 'Sorry, I couldn’t fetch a response. Please try again.';
      }
    } catch (error) {
      // Log and handle connection or parsing errors
      print('Error occurred: $error');
      return 'An error occurred. Please check your internet connection and try again.';
    }
  }

  @override
  Future<String> generate(String prompt) async {
    print('Generating response for prompt Perplexity: $prompt');

    final postHeaders = getPostHeaders();
    final postBody = getPostBody(prompt);
    final url = getPostUrl();
    final responseString = await postMessage(url, postHeaders, postBody);
    final responseJson = jsonDecode(responseString);
    return responseJson['choices'][0]['message']['content'].trim();
  }

  @override
  Future<String> chat({
    List<Map<String, dynamic>>? context,
    String? prompt,

    /// **Optional generation parameters:**

    /// * [temperature] — Controls randomness / creativity.
    ///   - Range: 0.0–2.0
    ///   - Lower → more deterministic and focused.
    ///   - Higher → more creative or “loose” output.
    ///   - Default: 0.7

    double temperature = 0.7,

    /// * [topP] — Nucleus sampling threshold (diversity control).
    ///   - Range: 0.0–1.0
    ///   - Lower values limit how many words the model can choose from.
    ///   - Use either `temperature` or `topP`, not both low at once.
    ///   - Default: 1.0
    ///
    double topP = 1.0,

    /// * [frequencyPenalty] — Reduces repetition of identical words/phrases.
    ///   - Range: -2.0–2.0
    ///   - Higher values discourage reusing the same words.
    ///   - Useful for long explanations or summaries.
    ///   - Default: 0.0
    ///
    double frequencyPenalty = 0.0,

    /// * [presencePenalty] — Reduces repetition of ideas or topics.
    ///   - Range: -2.0–2.0
    ///   - Higher values push the model to introduce new ideas.
    ///   - Too high can make the response drift off-topic.
    ///   - Default: 0.0

    double presencePenalty = 0.0,

    /// * [stream] — Whether to stream tokens as they’re generated.
    ///   - `false` → Wait for full response (simpler, default).
    ///   - `true` → Receive partial chunks (useful for live chat UIs).
    ///   - Default: false

    bool stream = false,
  }) async {
    // Validate input
    final hasContext = context != null && context.isNotEmpty;
    final singlePrompt = prompt != null && prompt.trim().isNotEmpty;
    // Ensure only one of messages or prompt is provided
    if (!hasContext && !singlePrompt) {
      throw ArgumentError('Either messages or prompt must be provided.');
    }
    if (hasContext && singlePrompt) {
      throw ArgumentError('Provide either messages or prompt, not both.');
    }
    // Build Headers
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    // Build Body based on input type
    Map<String, dynamic> body;

    if (prompt != null) {
      // Single prompt case
      body = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant. Be precise and concise.'
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': temperature,
        'top_p': topP,
        'frequency_penalty': frequencyPenalty,
        'presence_penalty': presencePenalty,
        'max_tokens': maxOutputTokens,
        'stream': stream,
      };
    } else {
      // Context messages case
      body = {
        'model': model,
        'messages': context,
        'temperature': temperature,
        'top_p': topP,
        'frequency_penalty': frequencyPenalty,
        'presence_penalty': presencePenalty,
        'max_tokens': maxOutputTokens,
        'stream': stream,
      };
    }
    // Convert body to JSON
    final bodyJson = jsonEncode(body);

    //Send HTTP POST request
    final response =
        await http.post(parsedUrl, headers: headers, body: bodyJson);
    if (response.statusCode != 200) {
      throw Exception(
          'Perplexity API error: ${response.statusCode} - ${response.body}');
    }
    // Parse and return the response content
    final data = jsonDecode(response.body);

    // Adjust based on actual response structure
    return data['choices'][0]['message']['content'].toString().trim();
  }

  @override
  Stream<String> chatStream({
    List<Map<String, dynamic>>? context,
    String? prompt,
    double temperature = 0.7,
    double topP = 1.0,
    double frequencyPenalty = 0.0,
    double presencePenalty = 0.0,
    bool stream = true,
  }) async* {
    final hasContext = context != null && context.isNotEmpty;
    final singlePrompt = prompt != null && prompt.trim().isNotEmpty;
    if (!hasContext && !singlePrompt) {
      throw ArgumentError('Either messages or prompt must be provided.');
    }
    if (hasContext && singlePrompt) {
      throw ArgumentError('Provide either messages or prompt, not both.');
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      if (stream) 'Accept': 'text/event-stream',
    };

    final body = {
      'model': model,
      'messages': singlePrompt
          ? [
              {
                'role': 'system',
                'content':
                    'You are a helpful assistant. Be precise and concise.'
              },
              {'role': 'user', 'content': prompt}
            ]
          : context,
      'temperature': temperature,
      'frequency_penalty': frequencyPenalty,
      'presence_penalty': presencePenalty,
      'max_tokens': maxOutputTokens,
      'stream': true, // critical for SSE
    };
    print("Streaming body: $body");
    final client = http.Client();
    try {
      final req = http.Request('POST', parsedUrl)
        ..headers.addAll(headers)
        ..body = jsonEncode(body);

      final streamedResponse = await client.send(req);
      if (streamedResponse.statusCode != 200) {
        final errBody = await streamedResponse.stream.bytesToString();
        throw Exception(
            'API stream error: ${streamedResponse.statusCode} - $errBody');
      }

      final lineStream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.isEmpty) continue;
        if (!line.startsWith('data:')) continue;

        final payload = line.substring(5).trim();
        if (payload == '[DONE]') break;

        dynamic jsonLine;
        try {
          jsonLine = jsonDecode(payload);
        } catch (_) {
          continue;
        }

        final choices = jsonLine['choices'];
        if (choices is List && choices.isNotEmpty) {
          final choice = choices[0];
          final delta = choice['delta'];
          if (delta is Map && delta.containsKey('content')) {
            final token = (delta['content'] ?? '').toString();
            if (token.isNotEmpty) yield token;
          } else if (choice['message'] is Map &&
              (choice['message']['content'] ?? '').toString().isNotEmpty) {
            yield choice['message']['content'].toString();
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
