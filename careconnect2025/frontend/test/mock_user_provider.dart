import 'package:care_connect_app/providers/user_provider.dart';
import 'package:care_connect_app/services/user_role_storage_service.dart'
    show UserData;

/// Lightweight fake user for testing.
class MockUser extends UserSession {
  MockUser({
    super.id = 1,
    super.email = 'test@example.com',
    super.role = 'PATIENT',
    super.token = 'mock_token',
    super.patientId = 1,
    super.caregiverId,
    super.name = 'Test User',
    super.emailVerified = true,
  });
}

/// Mock UserProvider for tests (no HTTP/storage calls).
class MockUserProvider extends UserProvider {
  MockUserProvider({UserSession? mockUser}) {
    _mockUser = mockUser ?? MockUser();
  }

  late UserSession _mockUser;

  // ==== required getters ====
  @override
  UserSession? get user => _mockUser;

  @override
  bool get isLoggedIn => true;

  @override
  bool get isPatient => _mockUser.role.toUpperCase() == 'PATIENT';

  @override
  bool get isCaregiver => _mockUser.role.toUpperCase() == 'CAREGIVER';

  // ==== stub external/async behavior ====
  @override
  Future<void> initializeUser() async {}

  @override
  Future<void> fetchUserDetails() async {}

  @override
  Future<void> clearUser() async {}

  @override
  Future<void> updateActivity() async {}

  @override
  Future<bool> validateSession() async => true;

  @override
  Future<bool> refreshToken() async => true;

  @override
  Future<void> updateUserRole(String newRole) async {}

  @override
  Future<void> updatePatientId(int? patientId) async {}

  // In your real provider this is `void updateUserName(String)`, not Future.
  @override
  void updateUserName(String newName) {}

  //match exact signature from real provider
  @override
  Future<UserData?> getUserDataFromStorage() async => null;

  // helper for tests
  void setMockRole(String role, {int? patientId, int? caregiverId}) {
    _mockUser = MockUser(
      role: role,
      patientId: patientId,
      caregiverId: caregiverId,
    );
    notifyListeners();
  }
}
