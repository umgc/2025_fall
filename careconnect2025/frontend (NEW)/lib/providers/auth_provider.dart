import 'package:flutter/material.dart';
import 'app_state_provider.dart';

class AuthProvider extends ChangeNotifier {
  UserMode? _userMode;
  String? _userName;
  String? _userEmail;
  
  // Getters
  UserMode? get userMode => _userMode;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  
  // Demo user data
  String getDisplayName() {
    if (_userName != null) return _userName!;
    switch (_userMode) {
      case UserMode.patient:
        return 'Demo Patient';
      case UserMode.caregiver:
        return 'Demo Caregiver';
      case UserMode.supervisor:
        return 'Demo Supervisor';
      default:
        return 'Demo User';
    }
  }
  
  // Login methods
  void loginAsPatient({String? name, String? email}) {
    _userMode = UserMode.patient;
    _userName = name ?? 'Demo Patient';
    _userEmail = email ?? 'patient@demo.com';
    notifyListeners();
  }
  
  void loginAsCaregiver({String? name, String? email}) {
    _userMode = UserMode.caregiver;
    _userName = name ?? 'Demo Caregiver';
    _userEmail = email ?? 'caregiver@demo.com';
    notifyListeners();
  }
  
  void loginAsSupervisor({String? name, String? email}) {
    _userMode = UserMode.supervisor;
    _userName = name ?? 'Demo Supervisor';
    _userEmail = email ?? 'supervisor@demo.com';
    notifyListeners();
  }
  
  // Logout
  void logout() {
    _userMode = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
  
  // Check if logged in
  bool get isLoggedIn => _userMode != null;
}
