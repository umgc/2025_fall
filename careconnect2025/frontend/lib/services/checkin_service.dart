import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service that handles creating and retrieving patient check-ins.
/// Used by both patient and caregiver dashboards.
class CheckinService {
  static const String _baseUrl = 'https://localhost:8080/api/checkins';

  /// Adds a new check-in for a patient.
  /// Example use: CheckinService.addCheckin(patientId, caregiverId);
  static Future<bool> addCheckin(String patientId, String caregiverId) async {
    final url = Uri.parse('$_baseUrl');
    final body = jsonEncode({
      'patientId': patientId,
      'caregiverId': caregiverId,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'completed',
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  /// Fetches the total number of check-ins tied to a caregiver.
  /// Example use: final count = await CheckinService.getCheckinCount(caregiverId);
  static Future<int> getCheckinCount(String caregiverId) async {
    final url = Uri.parse('$_baseUrl/count?caregiverId=$caregiverId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      return 0;
    }
  }
}
