import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medication-model.dart';

Future<List<Medication>> fetchMedicationsFromEnhancedProfile({
  required String baseUrl,   // e.g. http://10.0.2.2:8080 (emulator) or http://localhost:8080 (web)
  required int patientId,    // from /v1/api/patients/me
  required String jwtToken,  // Bearer <token>
}) async {
  final uri = Uri.parse('$baseUrl/v1/api/patients/$patientId/profile/enhanced');

  final res = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Profile fetch failed: ${res.statusCode} ${res.body}');
  }

  final Map<String, dynamic> body = json.decode(res.body);
  final Map<String, dynamic> data = (body['data'] as Map<String, dynamic>?) ?? {};
  final List meds = (data['activeMedications'] as List?) ?? const [];

  return meds
      .whereType<Map<String, dynamic>>()
      .map((m) => Medication.fromJson(m))
      .toList();
}
