import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:postgres/postgres.dart';

class AILoggingSingleton {
 static final AILoggingSingleton _singleton = AILoggingSingleton._internal();
 factory AILoggingSingleton() {
  return _singleton;
 }
 AILoggingSingleton._internal();

 
  Future<void> createDb() async {
    final url = Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=createDb");
    final response = await http.post(url);
    print(response.body);
  }

  Future<String> getAllLogs() async {
    final url = Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=getTables");
    final response = await http.post(url);
    final postResponse = response.body;
    return postResponse;
  }
}
