// TODO: Put public facing types in this file.

//import 'dart:ffi';

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

//This is the abstract class for the LLM API module
//It has a single method called generate which takes a string prompt and returns a string
abstract class LLM {
  final String apiKey;
  String get url;
  String get model;
  double get tokenCount;
  int get contextSize;
  int get maxOutputTokens;

  LLM(this.apiKey);

  // Abstract method that subclasses must implement
  Future<String> postToLlm(String prompt);

  // Abstract method that subclasses must implement
  Future<String> getChatResponse(String prompt);

  // Abstract method that subclasses must implement
  Future<String> generate(String prompt);

  // Abstract method that subclasses must implement
  Future<String> chat({
    List<Map<String, dynamic>>? context,
    String? prompt,
    double temperature = 0.7,
    double topP = 1.0,
    double frequencyPenalty = 0.0,
    double presencePenalty = 0.0,
    bool stream = false,
  });
  Stream<String> chatStream({
    List<Map<String, dynamic>>? context,
    String? prompt,
    double temperature = 0.7,
    double topP = 1.0,
    double frequencyPenalty = 0.0,
    double presencePenalty = 0.0,
  });
}
