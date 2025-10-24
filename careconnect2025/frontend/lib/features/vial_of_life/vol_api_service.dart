import 'dart:convert';
import 'package:http/http.dart' as http;

class VolApiService {
  static const String baseUrl = 'http://localhost:8080/v1/api';

  static Future<Map<String, dynamic>?> getVial(int patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/$patientId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  static Future<bool> saveContacts(int patientId, List<String> flattened) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/contacts/save'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'patientId': patientId, 'contacts': flattened}),
    );
    return resp.statusCode == 200;
  }


  static Future<Map<String, dynamic>?> saveVial(Map<String, dynamic> vialData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vialData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  static Future<bool> deleteVial(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    return response.statusCode == 204;
  }

  static Future<String?> sharePayload(int patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/share/$patientId'));
    if (response.statusCode == 200) {
      final map = json.decode(response.body);
      return map['payload']?.toString();
    }
    return null;
  }
}
