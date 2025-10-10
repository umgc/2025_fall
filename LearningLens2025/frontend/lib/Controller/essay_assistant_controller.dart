import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/Essay_Assistant_Session.dart';
import 'package:learninglens_app/beans/assignment.dart';


class Essaybuildercontroller {
  LLM llmClient;
  LmsFactory lmsClient;
  List<EssaySession> sessions = [];

Essaybuildercontroller({
  required this.llmClient,
  required this.lmsClient,
  });

  // Method to start a new essay session
  void StartSession() {
    // TODO: Implement session start logic
    
  }
  // Method to to collect and submit prompt the LLM
  void SubmitPrompt(String prompt) {
    //TODO: Implement prompt submission logic
  }
  // Method to accept response from LLM and update session state
  void acceptResponse() {
    //TODO: Implement response acceptance logic
  }
  // Method to save the current session state to LMS
  void saveSession() { 
    //TODO: Implement session saving logic
  }
  // Method to load a session state from LMS
  List<EssaySession> loadSessions(List<Assignment> assignments) {
    //TODO: Implement session loading logic
    return [];
  }
  // Method to end the current essay session
  void closeSession() {
    //TODO: Implement session closing logic
  } 
}