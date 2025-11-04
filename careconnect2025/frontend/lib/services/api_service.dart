import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as httpClient;
import 'package:path/path.dart' as path;

import '../config/env_constant.dart';
import 'auth_token_manager.dart';

class ApiConstants {
  //V1 endpoints
  static final String _host = getBackendBaseUrl();
  static final String auth = '$_host/v1/api/auth';
  static final String feed = '$_host/v1/api/feed';
  static final String users = '$_host/v1/api/users';
  static final String friends = '$_host/v1/api/friends';
  static final String analytics = '$_host/v1/api/analytics';
  static final String baseUrl = '$_host/v1/api/';
  static final String familyMembers = '$_host/v1/api/family-members';
  static final String patient = '$_host/v1/api/patient';
  static final String mood = '$_host/v1/api/patient';
  static final String patients = '$_host/v1/api/patients';
  static final String caregivers = '$_host/v1/api/caregivers';
  static final String files = '$_host/v1/api/files';
  static final String connectionRequests = '$_host/v1/api/connection-requests';
  static final String subscriptions = '$_host/v1/api/subscriptions';
  static final String tasks = '$_host/v1/api/tasks';
  static final String allergies = '$_host/v1/api/allergies';
  static final String symptoms = '$_host/v1/api/symptoms';

  //V2 endpoints
  static final String baseUrlV2 = '$_host/v2/api/';
  static final String tasksV2 = '$_host/v2/api/tasks';

  // AI Services endpoints
  static final String aiChat = '$_host/v1/api/ai-chat';
  static final String aiConfig = '$_host/v1/api/ai-chat/config';
  // Invoices endpoints
  static final String invoices = '$_host/v1/api/invoices';

    // EVV endpoints
  static final String evv = '$_host/v1/api/evv';
}

class ApiService {
  static const storage = FlutterSecureStorage();

  // Performance optimization: Connection pooling
  static final http.Client _httpClient = http.Client();

  // Method to dispose of resources
  static void dispose() {
    _httpClient.close();
  }

  // ========================
  // AUTHENTICATION METHODS
  // ========================

  static Future<http.Response> register(
    String name,
    String email,
    String password,
  ) async {
    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.auth}/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> registerPatient(
    String firstName,
    String lastName,
    String email,
    String phone,
    String dob,
    String address,
    String relationship,
    int caregiverId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();

    // Debug: Check if JWT token is included
    print('🔍 registerPatient headers: $headers');
    final hasAuth = headers.containsKey('Authorization');
    print('🔍 Authorization header present: $hasAuth');
    if (hasAuth) {
      print('🔍 Auth header value: ${headers['Authorization']}');
    }

    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.baseUrl}caregivers/$caregiverId/patients'),
          headers: headers,
          body: jsonEncode({
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'phone': phone,
            'dob': dob,
            'address': address,
            'relationship': relationship,
            'caregiverId': caregiverId,
          }),
        )
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> login(String email, String password) async {
    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.auth}/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> logout() async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final response = await _httpClient
        .post(Uri.parse('${ApiConstants.auth}/logout'), headers: headers)
        .timeout(const Duration(seconds: 30));

    // Clear all auth models
    // Clear all auth data
    await AuthTokenManager.clearAuthData();
    return response;
  }

  static Future<http.Response> requestPasswordReset(String email) async {
    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.auth}/password/forgot'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.auth}/password/reset'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': token, 'password': newPassword}),
        )
        .timeout(const Duration(seconds: 30));
  }

  // ========================
  // PROFILE METHODS
  // ========================

  static Future<http.Response> getProfile() async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .get(Uri.parse('${ApiConstants.auth}/profile'), headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  // ========================
  // FEED METHODS
  // ========================

  static Future<http.Response> getAllPosts() async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .get(Uri.parse('${ApiConstants.feed}/all'), headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> getUserPosts(int userId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .get(Uri.parse('${ApiConstants.feed}/user/$userId'), headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> createPost(
    int userId,
    String content, [
    File? image,
  ]) async {
    final uri = Uri.parse('${ApiConstants.feed}/create');
    final headers = await AuthTokenManager.getAuthHeaders();

    var request = http.MultipartRequest('POST', uri)
      ..fields['userId'] = userId.toString()
      ..fields['content'] = content;

    // Add auth headers to multipart request
    request.headers.addAll(headers);

    if (image != null) {
      final imageStream = http.ByteStream(image.openRead());
      final imageLength = await image.length();
      final multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: path.basename(image.path),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // ========================
  // FRIEND METHODS
  // ========================

  static Future<http.Response> searchUsers(
    String query,
    int currentUserId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse(
      '${ApiConstants.users}/search?query=$query&currentUserId=$currentUserId',
    );

    return await _httpClient
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> sendFriendRequest(
    int fromUserId,
    int toUserId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse('${ApiConstants.friends}/request');
    return await _httpClient
        .post(
          url,
          headers: headers,
          body: jsonEncode({'fromUserId': fromUserId, 'toUserId': toUserId}),
        )
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> getPendingFriendRequests(int userId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse('${ApiConstants.friends}/requests/$userId');
    return await _httpClient
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> acceptFriendRequest(int requestId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse('${ApiConstants.friends}/accept');
    return await _httpClient
        .post(url, headers: headers, body: jsonEncode({'requestId': requestId}))
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> rejectFriendRequest(int requestId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse('${ApiConstants.friends}/reject');
    return await _httpClient
        .post(url, headers: headers, body: jsonEncode({'requestId': requestId}))
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> getFriends(int userId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse('${ApiConstants.friends}/list/$userId');
    return await _httpClient
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  // ========================
  // DASHBOARD METHODS
  // ========================

  static Future<http.Response> getCaregiverPatients(int caregiverId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .get(
          Uri.parse('${ApiConstants.baseUrl}caregivers/$caregiverId/patients'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
  }

  /// Check if a user with the given email exists
  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    final headers = await AuthTokenManager.getAuthHeaders();

    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              '${ApiConstants.users}/check-email?email=${Uri.encodeComponent(email)}',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print(
        '🔍 Check email response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'exists': false,
          'error': 'Failed to check email: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error checking email: $e');
      return {'exists': false, 'error': e.toString()};
    }
  }

  /// Send a connection request from a caregiver to a patient
  static Future<http.Response> sendConnectionRequest({
    required int caregiverId,
    required String patientEmail,
    required String relationshipType,
    String? message,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    print('🔍 Sending connection request to $patientEmail');

    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.connectionRequests}/create'),
          headers: headers,
          body: jsonEncode({
            'caregiverId': caregiverId,
            'patientEmail': patientEmail,
            'relationshipType': relationshipType,
            'message':
                message ?? 'I would like to connect with you on CareConnect',
          }),
        )
        .timeout(const Duration(seconds: 20));
  }

  /// Get pending connection requests for a caregiver
  static Future<http.Response> getPendingRequestsByCaregiver(
    int caregiverId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();

    return await _httpClient
        .get(
          Uri.parse(
            '${ApiConstants.connectionRequests}/pending/caregiver/$caregiverId',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));
  }

  static Future<http.Response> suspendCaregiverPatientLink(int linkId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/json'; // Add content type header

    print('🔍 Calling suspendCaregiverPatientLink for linkId: $linkId');

    // Try both formats to determine which one works with the backend
    final url1 =
        '${ApiConstants.baseUrl}caregiver-patient-links/$linkId/suspend';
    final url2 = '${ApiConstants.baseUrl}caregivers/links/$linkId/suspend';

    print('🔍 URL Option 1: $url1');
    print('🔍 URL Option 2: $url2');
    print('🔍 Headers: $headers');

    // Use the first URL format by default
    final String finalUrl = url1;

    return await _httpClient
        .post(
          Uri.parse(finalUrl),
          headers: headers,
          body: jsonEncode({}), // Send empty JSON body
        )
        .timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> reactivateCaregiverPatientLink(
    int linkId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/json'; // Add content type header

    print('🔍 Calling reactivateCaregiverPatientLink for linkId: $linkId');

    // Try both formats to determine which one works with the backend
    final url1 =
        '${ApiConstants.baseUrl}caregiver-patient-links/$linkId/reactivate';
    final url2 = '${ApiConstants.baseUrl}caregivers/links/$linkId/reactivate';

    print('🔍 URL Option 1: $url1');
    print('🔍 URL Option 2: $url2');
    print('🔍 Headers: $headers');

    // Use the first URL format by default
    final String finalUrl = url1;

    return await _httpClient
        .post(
          Uri.parse(finalUrl),
          headers: headers,
          body: jsonEncode({}), // Send empty JSON body
        )
        .timeout(const Duration(seconds: 30));
  }

    // ========================
    // CAREGIVER MOOD SUMMARY
    // ========================
    static Future<Map<String, dynamic>> getCaregiverMoodSummaries(int caregiverId) async {
      final headers = {'Content-Type': 'application/json'};
      final url = Uri.parse('${ApiConstants.mood}/caregiver/$caregiverId/moods');

      try {
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          print('⚠️ getCaregiverMoodSummaries failed: ${response.statusCode}');
          return {};
        }
      } catch (e) {
        print('❌ getCaregiverMoodSummaries error: $e');
        return {};
      }
    }



    // ========================
    // MEDICATIONS
    // ========================
    static Future<List<dynamic>> getActiveMedications(int userId) async {
      final headers = {'Content-Type': 'application/json'};
      final url = Uri.parse('${ApiConstants.patients}/$userId/active');

      try {
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) return data;
          return [];
        } else {
          print('⚠️ getActiveMedications failed: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        print('❌ getActiveMedications error: $e');
        return [];
      }
    }

    // ========================
    // MEDICATION REMINDERS
    // ========================
    static Future<List<dynamic>> getTodaysMedications(int userId) async {
      final headers = {'Content-Type': 'application/json'};
      final url = Uri.parse('${ApiConstants.patient}/$userId/medications/today');

      try {
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) return data;
          return [];
        } else {
          print('⚠️ getTodaysMedications failed: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        print('❌ getTodaysMedications error: $e');
        return [];
      }
    }

  // ========================
  // MOOD TRACKER METHODS
  // ========================

  static Future<http.Response> saveMoodScore({
    required int userId,
    required int score,
    required String label,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final url = Uri.parse('${ApiConstants.mood}/$userId/mood');

    final body = jsonEncode({
      'score': score,
      'label': label,
    });

    try {
      final response = await _httpClient
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      print('🔍 saveMoodScore response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (e) {
      print('❌ saveMoodScore error: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getMoodHistory(int userId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse('${ApiConstants.mood}/$userId/mood');

    try {
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        return [];
      } else {
        print('⚠️ getMoodHistory failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ getMoodHistory error: $e');
      return [];
    }
  }

  // ========================
  // UTILITY METHODS
  // ========================

  // Get auth headers with Authorization bearer token
  static Future<Map<String, String>> getAuthHeaders() async {
    return await AuthTokenManager.getAuthHeaders();
  }

  // allergies tracker
  static Future<String> getJwtToken() async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final auth = (headers['Authorization'] ?? '').trim();

    const prefix = 'Bearer ';
    if (auth.toLowerCase().startsWith(prefix.toLowerCase())) {
      return auth.substring(prefix.length).trim();
    }
    return '';
  }

  // Save JWT token from Set-Cookie header or response body
  static Future<void> saveJWTToken(String token) async {
    // This method is now deprecated - use AuthTokenManager.saveAuthData instead
    print(
      'Warning: saveJWTToken is deprecated. Use AuthTokenManager.saveAuthData instead.',
    );
  }

  // Clear auth cookie/token
  static Future<void> clearAuthCookie() async {
    await AuthTokenManager.clearAuthData();
  }

  // ========================
  //   SYMPTOMS (CRUD)
  // ========================

  // GET /v1/api/symptoms/patient/{patientId}
  static Future<List<Map<String, dynamic>>> getSymptomsForPatient(int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final uri = Uri.parse('${ApiConstants.symptoms}/patient/$patientId');

    final res = await _httpClient.get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('getSymptomsForPatient failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    final list = (decoded is Map && decoded['data'] is List)
        ? decoded['data'] as List
        : const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

// ✅ NEW - GET /v1/api/symptoms/{id}
  static Future<Map<String, dynamic>> getSymptomById(int id) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final uri = Uri.parse('${ApiConstants.symptoms}/$id');

    final res = await _httpClient.get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('getSymptomById failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return (decoded is Map && decoded['data'] is Map)
        ? decoded['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

// POST /v1/api/symptoms
  static Future<Map<String, dynamic>> createSymptom({
    required int patientId,
    required String symptomKey,
    String? symptomValue,
    required int severity,
    String? clinicalNotes,
    bool completed = true,
    DateTime? takenAt,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final payload = <String, dynamic>{
      'patientId': patientId,
      'symptomKey': symptomKey,
      if (symptomValue != null) 'symptomValue': symptomValue,
      'severity': severity,
      'completed': completed,
      'takenAt': (takenAt ?? DateTime.now()).toUtc().toIso8601String(),
      if (clinicalNotes != null && clinicalNotes.trim().isNotEmpty)
        'clinicalNotes': clinicalNotes.trim(),
    };

    final res = await _httpClient
        .post(Uri.parse(ApiConstants.symptoms),
        headers: headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('createSymptom failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return (decoded is Map && decoded['data'] is Map)
        ? decoded['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

// PUT /v1/api/symptoms/{id}
  static Future<Map<String, dynamic>> updateSymptom({
    required int id,
    String? symptomKey,
    String? symptomValue,
    int? severity,
    String? clinicalNotes,
    bool? completed,
    DateTime? takenAt,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final payload = <String, dynamic>{
      if (symptomKey != null) 'symptomKey': symptomKey,
      if (symptomValue != null) 'symptomValue': symptomValue,
      if (severity != null) 'severity': severity,
      if (clinicalNotes != null) 'clinicalNotes': clinicalNotes,
      if (completed != null) 'completed': completed,
      if (takenAt != null) 'takenAt': takenAt.toUtc().toIso8601String(),
    };

    final res = await _httpClient
        .put(Uri.parse('${ApiConstants.symptoms}/$id'),
        headers: headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('updateSymptom failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return (decoded is Map && decoded['data'] is Map)
        ? decoded['data'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

// DELETE /v1/api/symptoms/{id}
  static Future<void> deleteSymptom(int id) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final res = await _httpClient
        .delete(Uri.parse('${ApiConstants.symptoms}/$id'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('deleteSymptom failed: ${res.statusCode} ${res.body}');
    }
  }

  // ========================
  // SUBSCRIPTION METHODS
  // ========================

  // Get the current subscription for a user
  static Future<http.Response> getCurrentSubscription() async {
    final headers = await AuthTokenManager.getAuthHeaders();

    // Get the user session to extract the user ID
    final userSession = await AuthTokenManager.getUserSession();
    final userId = userSession != null ? userSession['id']?.toString() : null;

    if (userId == null) {
      throw Exception('User ID not found. Please ensure you are logged in.');
    }

    return await _httpClient
        .get(
          Uri.parse('${ApiConstants.subscriptions}/user/$userId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
  }

  // Get all available subscription plans
  static Future<http.Response> getAvailablePlans() async {
    final headers = await AuthTokenManager.getAuthHeaders();

    return await _httpClient
        .get(Uri.parse('${ApiConstants.subscriptions}/plans'), headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  // Create a subscription for an existing customer
  static Future<http.Response> createSubscription(
    String customerId,
    String priceId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/x-www-form-urlencoded';

    final uri = Uri.parse('${ApiConstants.subscriptions}/create-direct');

    // Create form models as required by the API
    // Create form data as required by the API
    final formData = {'customerId': customerId, 'priceId': priceId};

    return await _httpClient
        .post(uri, headers: headers, body: formData)
        .timeout(const Duration(seconds: 30));
  }

  // Cancel a subscription
  static Future<http.Response> cancelSubscription(String subscriptionId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.subscriptions}/$subscriptionId/cancel'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
  }

  // Change subscription plan
  static Future<http.Response> changeSubscriptionPlan(
    String oldSubscriptionId,
    String newPriceId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/x-www-form-urlencoded';

    // Create form models as required by the API
    // Create form data as required by the API
    final formData = {
      'oldSubscriptionId': oldSubscriptionId,
      'newPriceId': newPriceId,
    };

    final uri = Uri.parse('${ApiConstants.subscriptions}/upgrade-or-downgrade');

    // Send form models as required by the API
    // Send form data as required by the API
    return await _httpClient
        .post(uri, headers: headers, body: formData)
        .timeout(const Duration(seconds: 30));
  }

  // Upgrade or downgrade a subscription
  static Future<http.Response> upgradeOrDowngradeSubscription(
    String oldSubscriptionId,
    String newPriceId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers['Content-Type'] = 'application/x-www-form-urlencoded';

    final uri = Uri.parse('${ApiConstants.subscriptions}/upgrade-or-downgrade');

    // Create form models
    // Create form data
    final formData = {
      'oldSubscriptionId': oldSubscriptionId,
      'newPriceId': newPriceId,
    };

    return await _httpClient
        .post(uri, headers: headers, body: formData)
        .timeout(const Duration(seconds: 30));
  }

  // Get subscription information for the current user
  static Future<http.Response> getUserSubscriptions() async {
    final headers = await AuthTokenManager.getAuthHeaders();

    // Get the user session to extract the user ID
    final userSession = await AuthTokenManager.getUserSession();
    final userId = userSession != null ? userSession['id']?.toString() : null;

    if (userId == null) {
      throw Exception('User ID not found. Please ensure you are logged in.');
    }

    return await _httpClient
        .get(
          Uri.parse('${ApiConstants.subscriptions}/user/$userId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
  }

  // FAMILY
  // FAMILY
  static Future<List<Map<String, dynamic>>> getAccessiblePatients() async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.familyMembers}/patients',
            ), // Use ApiConstants.familyMembers
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (isAccessDenied(response)) {
        throw Exception('You do not have access to view patients');
      } else {
        throw Exception(handleErrorResponse(response));
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  // Get specific patient models (family member access)
  // Get specific patient data (family member access)
  static Future<Map<String, dynamic>> getPatientData(int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final response = await http.get(
      Uri.parse(
        '${ApiConstants._host}/v1/api/family-members/patients/$patientId',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('Access denied to patient models');
      throw Exception('Access denied to patient data');
    } else {
      throw Exception('Failed to fetch patient models');
      throw Exception('Failed to fetch patient data');
    }
  }

  /// Get a specific patient under a caregiver's care
  static Future<Map<String, dynamic>> getPatientForCaregiver(
    int caregiverId,
    int patientId,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}caregivers/$caregiverId/patients/$patientId',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('Access denied to patient models');
      throw Exception('Access denied to patient data');
    } else if (response.statusCode == 404) {
      throw Exception('Patient not found');
    } else {
      throw Exception('Failed to fetch patient models');
      throw Exception('Failed to fetch patient data');
    }
  }

  // Check if family member has access to patient
  static Future<bool> hasAccessToPatient(int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final response = await http.get(
      Uri.parse(
        '${ApiConstants._host}/v1/api/family-members/patients/$patientId/access',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return false;
  }

  // Get patient dashboard (read-only)
  static Future<Map<String, dynamic>> getPatientDashboard(
    int patientId, {
    int days = 30,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final response = await http.get(
      Uri.parse(
        '${ApiConstants._host}/v1/api/family-members/patients/$patientId/dashboard?days=$days',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('Access denied to patient models');
      throw Exception('Access denied to patient data');
    } else {
      throw Exception('Failed to fetch patient dashboard');
    }
  }

  // Get patient vitals (read-only)
  static Future<http.Response> getPatientVitals(
    int patientId, {
    int days = 7,
  }) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      return await _httpClient
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}analytics/vitals?patientId=$patientId&days=$days',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
          );
    } catch (e) {
      // Convert any errors to an error response
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<Map<String, dynamic>> getPatientStatus(int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final response = await http
        .get(
          Uri.parse(
            '${ApiConstants._host}/v1/api/family-members/patients/$patientId/status',
          ),
          headers: headers,
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
        );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('Access denied to patient status');
    } else if (response.statusCode == 408) {
      throw Exception('Request timed out');
    } else {
      throw Exception('Failed to fetch patient status: ${response.statusCode}');
    }
  }

  // Add method to check if response indicates access denied
  static bool isAccessDenied(http.Response response) {
    return response.statusCode == 403;
  }

  // Add method to handle common error responses
  static String handleErrorResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      return errorData['message'] ??
          errorData['error'] ??
          'Unknown error occurred';
    } catch (e) {
      return 'Failed with status code: ${response.statusCode}';
    }
  }

  static Future<http.Response> getFamilyMembers(int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await http.get(
      Uri.parse('${ApiConstants._host}/v1/api/patients/$patientId'),
      headers: headers,
    );
  }


  static Future<http.Response> getPatientDetails(int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse('${ApiConstants._host}/v1/api/patients/$patientId');
    return await http.get(url, headers: headers);
  }


  static Future<http.Response> addFamilyMember(
    int patientId,
    Map<String, dynamic> familyMemberData,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await http.post(
      Uri.parse(
        '${ApiConstants._host}/v1/api/patients/$patientId/family-members',
      ),
      headers: headers,
      body: jsonEncode(familyMemberData),
    );
  }

  static Future<http.Response> submitMoodAndPainLog({
    required int moodValue,
    required int painValue,
    required String note,
    required DateTime timestamp,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final url = Uri.parse(
      '${ApiConstants._host}/v1/api/patients/mood-pain-log',
    );

    return await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'moodValue': moodValue,
        'painValue': painValue,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
      }),
    );
  }

  static Future<http.Response> registerPatientForCaregiver({
    required int caregiverId,
    required Map<String, dynamic> patientData,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();

    print('🔍 registerPatientForCaregiver caregiverId: $caregiverId');
    print('🔍 patientData with structured address: ${jsonEncode(patientData)}');

    return await _httpClient
        .post(
          Uri.parse('${ApiConstants.baseUrl}caregivers/$caregiverId/patients'),
          headers: headers,
          body: jsonEncode(patientData),
        )
        .timeout(const Duration(seconds: 30));
  }

  /// Add an existing patient to a caregiver's care list by email
  static Future<http.Response> addExistingPatientToCaregiver({
    required int caregiverId,
    required String patientEmail,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    print('addExistingPatientToCaregiver caregiverId: $caregiverId');
    final url = '${ApiConstants.baseUrl}caregivers/$caregiverId/patients/add';

    return await _httpClient
        .post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({'email': patientEmail}),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
        );
  }

  // ========================
  // PROFILE MANAGEMENT METHODS
  // ========================

  /// Get caregiver profile models
  /// Get caregiver profile data
  static Future<http.Response> getCaregiverProfile(int caregiverId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .get(
          Uri.parse('${ApiConstants.caregivers}/$caregiverId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Update caregiver profile
  static Future<http.Response> updateCaregiverProfile(
    int caregiverId,
    Map<String, dynamic> updatedProfile,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .put(
          Uri.parse('${ApiConstants.caregivers}/$caregiverId'),
          headers: headers,
          body: jsonEncode(updatedProfile),
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Get patient profile models
  /// Get patient profile data
  static Future<http.Response> getPatientProfile(int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .get(Uri.parse('${ApiConstants.patients}/$patientId'), headers: headers)
        .timeout(const Duration(seconds: 15));
  }

  /// Update patient profile
  static Future<http.Response> updatePatientProfile(
    int patientId,
    Map<String, dynamic> updatedProfile,
  ) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    return await _httpClient
        .put(
          Uri.parse('${ApiConstants.patients}/$patientId'),
          headers: headers,
          body: jsonEncode(updatedProfile),
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Upload profile picture or other files
  static Future<http.Response> uploadUserFile({
    required int userId,
    required File file,
    required String category,
    String? role,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    // Remove Content-Type as it will be set by multipart request
    headers.remove('Content-Type');

    // Use users endpoint for file uploads
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.files}/users/$userId/upload'),
    );

    // Add headers
    request.headers.addAll(headers);

    // Add file
    var fileStream = http.ByteStream(file.openRead());
    var fileLength = await file.length();
    var multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: path.basename(file.path),
    );

    // Add form fields
    request.files.add(multipartFile);
    request.fields['category'] = category;

    // Send the request
    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    var response = await http.Response.fromStream(streamedResponse);

    return response;
  }

  /// Get user profile picture URL based on role
  static Future<String?> getUserProfilePictureUrl(
    int userId, [
    String? role,
  ]) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    // Use the users endpoint to get files consistently
    const endpoint = 'users';

    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              '${ApiConstants.files}/$endpoint/$userId?category=profilePicture',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.first['fileUrl'];
        } else if (data is Map && data.containsKey('fileUrl')) {
          return data['fileUrl'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting profile picture URL: $e');
      return null;
    }
  }



  // ========================
  // PRIMARY CARE PROVIDER
  // ========================
  static Future<Map<String, dynamic>> getPrimaryCareProvider(int userId) async {
    final headers = {'Content-Type': 'application/json'};
    final url = Uri.parse('${ApiConstants.patients}/$userId/provider');

    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
        return {};
      } else {
        print('⚠️ getPrimaryCareProvider failed: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ getPrimaryCareProvider error: $e');
      return {};
    }
  }






  // ========================
  // MESSAGING METHODS
  // ========================

  static Future<http.Response> sendMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      final body = jsonEncode({
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
      });

      return await _httpClient
          .post(
            Uri.parse('${ApiConstants.baseUrl}messages/send'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));
    }

    static Future<List<dynamic>> getConversation({
      required int user1,
      required int user2,
    }) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      final url = Uri.parse(
        '${ApiConstants.baseUrl}messages/conversation?user1=$user1&user2=$user2',
      );

      final response = await _httpClient.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load conversation');
      }
    }

    static Future<List<dynamic>> getInbox(int userId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}messages/inbox/$userId');

      final response = await _httpClient.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load inbox');
      }
    }

    // ========================
    // TASK METHODS
    // ========================

    // Get patient tasks
    static Future<http.Response> getPatientTasks(int patientId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      return await _httpClient
          .get(
            Uri.parse('${ApiConstants.tasks}/patient/$patientId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));
    }

    // Delete a task by task ID
    static Future<http.Response> deleteTask(int taskId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      return await _httpClient
          .delete(Uri.parse('${ApiConstants.tasks}/$taskId'), headers: headers)
          .timeout(const Duration(seconds: 30));
    }

    // Edit a task by task ID
    static Future<http.Response> editTask(
      int taskId,
      Map<String, dynamic> taskData,
    ) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      return await _httpClient
          .put(
            Uri.parse('${ApiConstants.tasks}/$taskId'),
            headers: headers,
            body: jsonEncode(taskData),
          )
          .timeout(const Duration(seconds: 30));
    }

    // Get task templates
    static Future<http.Response> getTaskTemplates(int patientId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      return await _httpClient
          .get(
            Uri.parse('${ApiConstants.baseUrl}templates/all'), // get all for now
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));
    }

    static Future<http.Response> getTaskTemplate(int templateId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      return await _httpClient
          .get(
            Uri.parse('${ApiConstants.baseUrl}templates/$templateId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));
    }

    // Create a task
    static Future<http.Response> createTask(int patientId, String task) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      return await _httpClient
          .post(
            Uri.parse('${ApiConstants.tasks}/patient/$patientId'),
            headers: headers,
            body: task,
          )
          .timeout(const Duration(seconds: 30));
    }
    // ========================
    // TASK METHODS (V2)
    // ========================

    // Get patient tasks (v2)
    static Future<http.Response> getPatientTasksV2(int patientId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      return await _httpClient
          .get(
            Uri.parse('${ApiConstants.tasksV2}/patient/$patientId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));
    }

    // Delete a task by task ID (v2)
    // Delete a task by task ID (v2), with optional deleteSeries flag
    static Future<http.Response> deleteTaskV2(
      int taskId, {
      bool deleteSeries = false,
    }) async {
      final headers = await AuthTokenManager.getAuthHeaders();

      final url = Uri.parse(
        '${ApiConstants.tasksV2}/$taskId',
      ).replace(queryParameters: {'deleteSeries': deleteSeries.toString()});

      return await _httpClient
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));
    }

    // Edit a task by task ID (v2)
    static Future<http.Response> editTaskV2(
      int taskId,
      Map<String, dynamic> body, {
      bool updateSeries = false,
    }) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final payload = Map<String, dynamic>.from(body);
      payload['updateSeries'] = updateSeries;
      return await _httpClient
          .put(
            Uri.parse('${ApiConstants.tasksV2}/$taskId'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
    }

    /// Update a task's completion status (V2)
    ///
    /// Sends a PUT request to /v2/api/tasks/{id}/complete with a JSON body:
    /// `{ "isComplete": true/false }`
    ///
    /// Throws an [Exception] if the request fails.
    static Future<void> updateTaskCompletionV2(
      int taskId,
      bool isComplete,
    ) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final url = Uri.parse('${ApiConstants.tasksV2}/$taskId/complete');
      final body = jsonEncode({'isComplete': isComplete});

      final response = await _httpClient
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update task completion: ${response.statusCode} ${response.body}',
        );
      }
    }

    // Create a task (v2)
    static Future<http.Response> createTaskV2(
      int patientId,
      String taskJson,
    ) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      return await _httpClient
          .post(
            Uri.parse('${ApiConstants.tasksV2}/patient/$patientId'),
            headers: headers,
            body: taskJson,
          )
          .timeout(const Duration(seconds: 30));
    }

    // Get a single task by ID (v2)
    static Future<http.Response> getTaskByIdV2(int taskId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      return await _httpClient
          .get(Uri.parse('${ApiConstants.tasksV2}/$taskId'), headers: headers)
          .timeout(const Duration(seconds: 30));
    }

    static Future<Map<String, dynamic>?> getEnhancedPatientProfile(
      int patientId,
    ) async {
      try {
        final headers = await AuthTokenManager.getAuthHeaders();
        final url = Uri.parse(
          '${ApiConstants.patients}/$patientId/profile/enhanced',
        );
        final response = await _httpClient
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
            return decoded['data'] as Map<String, dynamic>?;
          } else {
            return decoded as Map<String, dynamic>?;
          }
        } else {
          print('Failed to fetch enhanced profile: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        print('Error fetching enhanced patient profile: ${e.toString()}');
        return null;
      }
    }
    
    static Future<http.Response> getPatientMedicationsForPatient(int patientId) async {
      try {
        final headers = await AuthTokenManager.getAuthHeaders();
        final uri = Uri.parse(
            '${ApiConstants.patients}/$patientId/medications');
        return await httpClient
            .get(uri, headers: headers)
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
        );
      }  catch (e) {
        return http.Response(jsonEncode({'error': e.toString()}), 500);
      }
    }

    /// Add a new medication for a patient
    static Future<http.Response> addPatientMedication(
      int patientId,
      Map<String, dynamic> medicationData,
    ) async {
      try {
        final headers = await AuthTokenManager.getAuthHeaders();
        final uri = Uri.parse(
          '${ApiConstants.patients}/$patientId/medications',
        );

        return await httpClient
            .post(
              uri,
              headers: headers,
              body: jsonEncode(medicationData),
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
            );
      } catch (e) {
        return http.Response(jsonEncode({'error': e.toString()}), 500);
      }
    }

  /// Remove (deactivate) a medication for a patient (Patient-side soft delete)
  static Future<http.Response> removePatientMedication(
    int patientId,
    int medicationId,
  ) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse(
        '${ApiConstants.patients}/$patientId/medications/$medicationId',
      );

        return await httpClient
            .delete(uri, headers: headers)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
            );
      } catch (e) {
        return http.Response(jsonEncode({'error': e.toString()}), 500);
      }
    }


      // Get latest mood and related data
      static Future<Map<String, dynamic>?> getMoodData(int userId) async {
        final String baseUrl = ApiConstants._host;
        final response = await http.get(
          Uri.parse('$baseUrl/patient/$userId/mood'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return null;
        }
      }


      // Get today's average mood and check-ins
      static Future<Map<String, dynamic>?> getDailyMoodAverage(int userId) async {
        final String baseUrl = ApiConstants._host;
        final response = await http.get(
          Uri.parse('$baseUrl/patient/$userId/mood/average'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return null;
        }
      }

      


  /// Delete medication by caregiver (Caregiver-side hard delete)
  static Future<http.Response> deleteMedicationByCaregiver(
    int patientId,
    int medicationId,
    int caregiverId,
  ) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse(
        '${ApiConstants.patients}/$patientId/medications/$medicationId/caregiver/$caregiverId',
      );

      return await httpClient
          .delete(uri, headers: headers)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
          );
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  /// Approve a medication for a patient (sets isActive=true, approval_status='APPROVED')
  static Future<http.Response> approveMedication(
    int patientId,
    int medicationId,
  ) async {
    try {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse(
        '${ApiConstants.patients}/$patientId/medications/$medicationId/approve',
      );

      return await httpClient
          .put(uri, headers: headers)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
          );
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
  
  // fetch from backend
  static Future<List<dynamic>> fetchAllergies(final int patientId) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    final uri = Uri.parse('${ApiConstants.allergies}/patient/$patientId');

    final response = await _httpClient.get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      return list;
    } else {
      throw HttpException('Failed to fetch allergies: ${response.body}');
    }
  }
  
  static Future<Map<String, dynamic>> addAllergy(final Map<String, dynamic> allergyData,
      final int patientId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({
        'patientId': patientId,
        'allergen': allergyData['drug'],
        'severity': allergyData['severity'],
        'reaction': allergyData['reaction'],
        'notes': allergyData['note'],
        'isActive': true
      });

      final response = await _httpClient.post(
        Uri.parse(ApiConstants.allergies),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['data'];
      } else {
        throw HttpException("Failed to add allergy for patient.");
      }
  }

  static Future<bool> removeAllergy(int allergyId) async {
      final headers = await AuthTokenManager.getAuthHeaders();
      final uri = Uri.parse('${ApiConstants.allergies}/$allergyId');

      final response = await _httpClient.delete(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200 || response.statusCode == 204;
  }
  
}

  // Save speech-to-text to a file and upload it to S3
  Future<http.Response> uploadUserFileFromBytes({
    required int userId,
    required Uint8List fileBytes,
    required String fileName,
    required String category,
    String? role,
  }) async {
    final headers = await AuthTokenManager.getAuthHeaders();
    headers.remove('Content-Type'); // Multipart will handle it

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.files}/users/$userId/upload'),
    );

    // Add headers
    request.headers.addAll(headers);

  // Create MultipartFile from bytes
  var fileStream = http.ByteStream(Stream.fromIterable([fileBytes]));
  var fileLength = await fileStream.length;
  var multipartFile = http.MultipartFile(
    'file',
    fileStream,
    fileLength,
    filename: fileName,
  );

  request.files.add(multipartFile);
  request.fields['category'] = category;

  // Send the request
  var streamedResponse = await request.send().timeout(
    const Duration(seconds: 30),
  );
  var response = await http.Response.fromStream(streamedResponse);

  return response;
}

// Get list of files from saved S3 storage
Future<http.Response> getUserFilesByCategory(int userId) async {
  try {
    final headers = await AuthTokenManager.getAuthHeaders();

    final uri = Uri.parse('${ApiConstants.baseUrl}files/users/$userId/list');

    return await httpClient
        .get(uri, headers: headers)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('{"error": "Request timeout"}', 408),
        );
  } catch (e) {
    return http.Response(jsonEncode({'error': e.toString()}), 500);
  }
}