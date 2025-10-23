import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf_io.dart' show logRequests;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

class MockData {
  static List<Map<String, dynamic>> users = [];
  static List<Map<String, dynamic>> patients = [];
  static List<Map<String, dynamic>> caregivers = [];
  static List<Map<String, dynamic>> posts = [];
  static List<Map<String, dynamic>> messages = [];
  static List<Map<String, dynamic>> tasks = [];
  static List<Map<String, dynamic>> subscriptions = [];
  static List<Map<String, dynamic>> connectionRequests = [];
}

/// Simple mock server to test frontend
class MockServer {
  static const String jwtSecret = 'mock-secret-key';
  static const int port = 9090;
  static final Uuid uuid = Uuid();
  static final Random random = Random();

  static Response jsonResponse(dynamic data, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static void initializeMockData() {
    // Mock users
    MockData.users = [
      {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'password': 'password123',
        'role': 'patient',
        'patientId': 1,
        'caregiverId': null,
        'stripeCustomerId': 'cus_mock_patient1'
      },
      {
        'id': 2,
        'name': 'Dr. Sarah Smith',
        'email': 'sarah@example.com',
        'password': 'password123',
        'role': 'caregiver',
        'patientId': null,
        'caregiverId': 1,
        'stripeCustomerId': 'cus_mock_caregiver1'
      }
    ];

    // Mock patients
    MockData.patients = [
      {
        'id': 1,
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john@example.com',
        'phone': '555-0123',
        'dob': '1980-01-01',
        'address': {
          'line1': '123 Main St',
          'line2': '',
          'city': 'Anytown',
          'state': 'VA',
          'zip': '12345'
        },
        'caregiverId': 1,
        'userId': 1
      }
    ];

    // Mock caregivers
    MockData.caregivers = [
      {
        'id': 1,
        'firstName': 'Dr. Sarah',
        'lastName': 'Smith',
        'email': 'sarah@example.com',
        'phone': '555-0456',
        'licenseNumber': 'MD12345',
        'yearsExperience': 10,
        'userId': 2
      }
    ];

    // Mock posts
    MockData.posts = [
      {
        'id': 1,
        'userId': 1,
        'content': 'Feeling great today! Had a wonderful walk in the park.',
        'timestamp': DateTime.now().toIso8601String(),
        'likes': 5
      }
    ];

    // Mock subscription plans
    MockData.subscriptions = [
      {
        'id': 'basic',
        'name': 'Basic Plan',
        'price': 9.99,
        'features': ['Basic monitoring', 'Monthly reports']
      },
      {
        'id': 'premium',
        'name': 'Premium Plan',
        'price': 19.99,
        'features': ['Advanced monitoring', 'Weekly reports', '24/7 support']
      }
    ];
  }

  static String generateToken(Map<String, dynamic> user) {
    final jwt = JWT({
      'id': user['id'],
      'email': user['email'],
      'role': user['role']
    });
    return jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(hours: 24));
  }

  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      return jwt.payload;
    } catch (e) {
      return null;
    }
  }

  static Middleware authMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return jsonResponse({'error': 'Access token required'}, status: 401);
        }

        final token = authHeader.substring(7);
        final payload = verifyToken(token);
        if (payload == null) {
          return jsonResponse({'error': 'Invalid token'}, status: 403);
        }

        final updatedRequest = request.change(context: {'user': payload});
        return await innerHandler(updatedRequest);
      };
    };
  }

  static Router createRouter() {
    final router = Router();

    // Health check
    router.get('/health', (Request request) {
      return jsonResponse({
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    // Authentication endpoints
    router.post('/v1/api/auth/register', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'];
      final email = data['email'];
      final password = data['password'];
      final role = data['role'] ?? 'patient';

      // Check if user exists
      if (MockData.users.any((user) => user['email'] == email)) {
        return jsonResponse({'error': 'User already exists'}, status: 400);
      }

      final newUser = {
        'id': MockData.users.length + 1,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'patientId': role == 'patient' ? MockData.patients.length + 1 : null,
        'caregiverId': role == 'caregiver' ? MockData.caregivers.length + 1 : null,
        'stripeCustomerId': 'cus_mock_$role${MockData.users.length + 1}'
      };

      MockData.users.add(newUser);

      return jsonResponse({
        'message': 'Registration successful! Please check your email to verify your account.',
        'userId': newUser['id']
      }, status: 201);
    });

    router.post('/v1/api/auth/login', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'];
      final password = data['password'];

      final user = MockData.users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => <String, dynamic>{}
      );

      if (user.isEmpty) {
        return jsonResponse({'error': 'Invalid credentials'}, status: 401);
      }

      final token = generateToken(user);

      return jsonResponse({
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'role': user['role'],
        'token': token,
        'patientId': user['patientId'],
        'caregiverId': user['caregiverId'],
        'stripeCustomerId': user['stripeCustomerId']
      });
    });

    // Protected routes with auth middleware
    final protectedRoutes = Router();

    protectedRoutes.post('/v1/api/auth/logout', (Request request) {
      return jsonResponse({'message': 'Logout successful'});
    });

    protectedRoutes.get('/v1/api/auth/profile', (Request request) {
      final userPayload = request.context['user'] as Map<String, dynamic>;
      final user = MockData.users.firstWhere(
        (u) => u['id'] == userPayload['id'],
        orElse: () => <String, dynamic>{}
      );

      if (user.isEmpty) {
        return jsonResponse({'error': 'User not found'}, status: 404);
      }

      return jsonResponse({
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'role': user['role'],
        'patientId': user['patientId'],
        'caregiverId': user['caregiverId']
      });
    });

    // Caregiver endpoints
    protectedRoutes.post('/v1/api/caregivers', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final firstName = data['firstName'];
      final lastName = data['lastName'];
      final email = data['email'];
      final credentials = data['credentials'];

      // Check if user exists
      if (MockData.users.any((user) => user['email'] == email)) {
        return jsonResponse({'error': 'Email already exists'}, status: 400);
      }

      final userId = MockData.users.length + 1;
      final caregiverId = MockData.caregivers.length + 1;

      final newUser = {
        'id': userId,
        'name': '$firstName $lastName',
        'email': email,
        'password': credentials['password'],
        'role': 'caregiver',
        'patientId': null,
        'caregiverId': caregiverId,
        'stripeCustomerId': 'cus_mock_caregiver$caregiverId'
      };

      final newCaregiver = {
        'id': caregiverId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'userId': userId,
        ...data
      };

      MockData.users.add(newUser);
      MockData.caregivers.add(newCaregiver);

      return jsonResponse({
        'id': caregiverId,
        'user': newUser,
        ...newCaregiver
      }, status: 201);
    });

    protectedRoutes.get('/v1/api/caregivers/<id>', (Request request) {
      final caregiverId = int.tryParse(request.params['id'] ?? '');
      if (caregiverId == null) {
        return jsonResponse({'error': 'Invalid caregiver ID'}, status: 400);
      }

      final caregiver = MockData.caregivers.firstWhere(
        (c) => c['id'] == caregiverId,
        orElse: () => <String, dynamic>{}
      );

      if (caregiver.isEmpty) {
        return jsonResponse({'error': 'Caregiver not found'}, status: 404);
      }

      return jsonResponse(caregiver);
    });

    protectedRoutes.get('/v1/api/caregivers/<id>/patients', (Request request) {
      final caregiverId = int.tryParse(request.params['id'] ?? '');
      if (caregiverId == null) {
        return jsonResponse({'error': 'Invalid caregiver ID'}, status: 400);
      }

      final caregiverPatients = MockData.patients.where(
        (p) => p['caregiverId'] == caregiverId
      ).toList();

      return jsonResponse(caregiverPatients);
    });

    protectedRoutes.post('/v1/api/caregivers/<id>/patients', (Request request) async {
      final caregiverId = int.tryParse(request.params['id'] ?? '');
      if (caregiverId == null) {
        return jsonResponse({'error': 'Invalid caregiver ID'}, status: 400);
      }

      final body = await request.readAsString();
      final patientData = jsonDecode(body) as Map<String, dynamic>;

      final newPatient = {
        'id': MockData.patients.length + 1,
        'caregiverId': caregiverId,
        'userId': MockData.users.length + 1,
        ...patientData
      };

      // Create user for patient
      final newUser = {
        'id': MockData.users.length + 1,
        'name': '${patientData['firstName']} ${patientData['lastName']}',
        'email': patientData['email'],
        'password': 'tempPassword123',
        'role': 'patient',
        'patientId': newPatient['id'],
        'caregiverId': null,
        'stripeCustomerId': 'cus_mock_patient${newPatient['id']}'
      };

      MockData.patients.add(newPatient);
      MockData.users.add(newUser);

      return jsonResponse(newPatient, status: 201);
    });

    // Patient endpoints
    protectedRoutes.get('/v1/api/patients/<id>', (Request request) {
      final patientId = int.tryParse(request.params['id'] ?? '');
      if (patientId == null) {
        return jsonResponse({'error': 'Invalid patient ID'}, status: 400);
      }

      final patient = MockData.patients.firstWhere(
        (p) => p['id'] == patientId,
        orElse: () => <String, dynamic>{}
      );

      if (patient.isEmpty) {
        return jsonResponse({'error': 'Patient not found'}, status: 404);
      }

      return jsonResponse(patient);
    });

    protectedRoutes.get('/v1/api/patients/<id>/profile/enhanced', (Request request) {
      final patientId = int.tryParse(request.params['id'] ?? '');
      if (patientId == null) {
        return jsonResponse({'error': 'Invalid patient ID'}, status: 400);
      }

      final patient = MockData.patients.firstWhere(
        (p) => p['id'] == patientId,
        orElse: () => <String, dynamic>{}
      );

      if (patient.isEmpty) {
        return jsonResponse({'error': 'Patient not found'}, status: 404);
      }

      final enhancedProfile = {
        ...patient,
        'vitals': {
          'heartRate': 72,
          'bloodPressure': '120/80',
          'temperature': 98.6,
          'weight': 150
        },
        'lastCheckIn': DateTime.now().toIso8601String(),
        'mood': 7,
        'painLevel': 2
      };

      return jsonResponse({'data': enhancedProfile});
    });

    // Feed endpoints
    protectedRoutes.get('/v1/api/feed/all', (Request request) {
      return jsonResponse(MockData.posts);
    });

    protectedRoutes.get('/v1/api/feed/user/<userId>', (Request request) {
      final userId = int.tryParse(request.params['userId'] ?? '');
      if (userId == null) {
        return jsonResponse({'error': 'Invalid user ID'}, status: 400);
      }

      final userPosts = MockData.posts.where(
        (p) => p['userId'] == userId
      ).toList();

      return jsonResponse(userPosts);
    });

    protectedRoutes.post('/v1/api/feed/create', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = int.tryParse(data['userId']?.toString() ?? '');
      final content = data['content'];

      if (userId == null) {
        return jsonResponse({'error': 'Invalid user ID'}, status: 400);
      }

      final newPost = {
        'id': MockData.posts.length + 1,
        'userId': userId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'likes': 0,
        'image': null // Simplified for now
      };

      MockData.posts.add(newPost);
      return jsonResponse(newPost, status: 201);
    });

    // Subscription endpoints
    protectedRoutes.get('/v1/api/subscriptions/plans', (Request request) {
      return jsonResponse(MockData.subscriptions);
    });

    protectedRoutes.get('/v1/api/subscriptions/user/<userId>', (Request request) {
      return jsonResponse({
        'id': 'sub_mock_123',
        'planId': 'basic',
        'status': 'active',
        'currentPeriodEnd': DateTime.now().add(Duration(days: 30)).toIso8601String()
      });
    });

    // Analytics endpoints
    protectedRoutes.get('/v1/api/analytics/vitals', (Request request) {
      final daysParam = request.url.queryParameters['days'];
      final days = int.tryParse(daysParam ?? '7') ?? 7;

      final vitalsData = <Map<String, dynamic>>[];
      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));

        vitalsData.add({
          'date': date.toIso8601String().split('T')[0],
          'heartRate': 70 + random.nextInt(20),
          'bloodPressure': '${120 + random.nextInt(20)}/${80 + random.nextInt(10)}',
          'weight': 150 + random.nextInt(10) - 5,
          'mood': random.nextInt(10) + 1,
          'painLevel': random.nextInt(5)
        });
      }

      return jsonResponse(vitalsData);
    });

    // Family members endpoints
    protectedRoutes.get('/v1/api/family-members/patients', (Request request) {
      final accessiblePatients = MockData.patients.map((p) => {
        ...p,
        'accessLevel': 'read-only'
      }).toList();

      return jsonResponse(accessiblePatients);
    });

    protectedRoutes.get('/v1/api/family-members/patients/<id>/dashboard', (Request request) {
      final patientId = int.tryParse(request.params['id'] ?? '');
      if (patientId == null) {
        return jsonResponse({'error': 'Invalid patient ID'}, status: 400);
      }

      return jsonResponse({
        'patientId': patientId,
        'recentActivity': [
          {'type': 'mood_log', 'value': 8, 'timestamp': DateTime.now().toIso8601String()},
          {'type': 'medication', 'value': 'taken', 'timestamp': DateTime.now().toIso8601String()}
        ],
        'vitals': {
          'latest': {'heartRate': 72, 'bloodPressure': '120/80'},
          'trend': 'stable'
        }
      });
    });

    // Tasks endpoints
    protectedRoutes.get('/v1/api/tasks/patient/<patientId>', (Request request) {
      final patientId = int.tryParse(request.params['patientId'] ?? '');
      if (patientId == null) {
        return jsonResponse({'error': 'Invalid patient ID'}, status: 400);
      }

      final patientTasks = MockData.tasks.where(
        (t) => t['patientId'] == patientId
      ).toList();

      return jsonResponse(patientTasks);
    });

    protectedRoutes.post('/v1/api/tasks/patient/<patientId>', (Request request) async {
      final patientId = int.tryParse(request.params['patientId'] ?? '');
      if (patientId == null) {
        return jsonResponse({'error': 'Invalid patient ID'}, status: 400);
      }

      final body = await request.readAsString();
      final taskData = jsonDecode(body) as Map<String, dynamic>;

      final newTask = {
        'id': MockData.tasks.length + 1,
        'patientId': patientId,
        ...taskData,
        'createdAt': DateTime.now().toIso8601String()
      };

      MockData.tasks.add(newTask);
      return jsonResponse(newTask, status: 201);
    });

    protectedRoutes.delete('/v1/api/tasks/<taskId>', (Request request) {
      final taskId = int.tryParse(request.params['taskId'] ?? '');
      if (taskId == null) {
        return jsonResponse({'error': 'Invalid task ID'}, status: 400);
      }

      final taskIndex = MockData.tasks.indexWhere((t) => t['id'] == taskId);
      if (taskIndex == -1) {
        return jsonResponse({'error': 'Task not found'}, status: 404);
      }

      MockData.tasks.removeAt(taskIndex);
      return jsonResponse({'message': 'Task deleted successfully'});
    });

    // Files endpoints
    protectedRoutes.post('/v1/api/files/users/<userId>/upload', (Request request) async {
      final category = request.url.queryParameters['category'];

      // Simplified file upload simulation
      final fileUrl = 'https://mock-s3-bucket.s3.amazonaws.com/uploads/${uuid.v4()}-mock-file.jpg';

      return jsonResponse({
        'fileUrl': fileUrl,
        'category': category,
        'uploadedAt': DateTime.now().toIso8601String()
      });
    });

    protectedRoutes.get('/v1/api/files/users/<userId>', (Request request) {
      final category = request.url.queryParameters['category'];

      return jsonResponse([{
        'fileUrl': 'https://mock-s3-bucket.s3.amazonaws.com/uploads/profile-picture.jpg',
        'category': category ?? 'profilePicture',
        'uploadedAt': DateTime.now().toIso8601String()
      }]);
    });

    // Connection requests
    protectedRoutes.post('/v1/api/connection-requests/create', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final newRequest = {
        'id': MockData.connectionRequests.length + 1,
        'caregiverId': data['caregiverId'],
        'patientEmail': data['patientEmail'],
        'relationshipType': data['relationshipType'],
        'message': data['message'],
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String()
      };

      MockData.connectionRequests.add(newRequest);
      return jsonResponse(newRequest, status: 201);
    });

    // Mood and pain log
    protectedRoutes.post('/v1/api/patients/mood-pain-log', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      return jsonResponse({
        'id': DateTime.now().millisecondsSinceEpoch,
        'moodValue': data['moodValue'],
        'painValue': data['painValue'],
        'note': data['note'],
        'timestamp': data['timestamp'],
        'submitted': true
      });
    });

    // Mount protected routes with auth middleware
    router.mount('/v1/api/', Pipeline().addMiddleware(authMiddleware()).addHandler(protectedRoutes));

    return router;
  }

  static Future<void> start() async {
    initializeMockData();

    final app = Router();
    final apiRouter = createRouter();

    app.mount('/', apiRouter);

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
        }))
        .addHandler(app);

    final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    print('CareConnect Mock Server running on http://localhost:$port');
    print('Available endpoints:');
    print('   - POST /v1/api/auth/login');
    print('   - POST /v1/api/auth/register');
    print('   - GET  /v1/api/auth/profile');
    print('   - GET  /v1/api/caregivers/:id/patients');
    print('   - POST /v1/api/caregivers/:id/patients');
    print('   - GET  /v1/api/feed/all');
    print('   - POST /v1/api/feed/create');
    print('   - GET  /v1/api/subscriptions/plans');
    print('   - GET  /health');
    print('');
    print('Demo credentials:');
    print('   Patient: john@example.com / password123');
    print('   Caregiver: sarah@example.com / password123');
    print('Press Ctrl+C to stop the server.');

    // Keep the server running indefinitely
    await ProcessSignal.sigint.watch().first;
  }
}

void main() async {
  await MockServer.start();
}