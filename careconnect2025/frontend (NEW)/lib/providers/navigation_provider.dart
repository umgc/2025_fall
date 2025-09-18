import 'package:flutter/material.dart';
import 'app_state_provider.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String _currentRoute = '/';
  List<String> _navigationHistory = [];
  
  // Getters
  int get currentIndex => _currentIndex;
  String get currentRoute => _currentRoute;
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  
  // Navigation methods
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void setCurrentRoute(String route) {
    if (_currentRoute != route) {
      _navigationHistory.add(_currentRoute);
      _currentRoute = route;
      notifyListeners();
    }
  }
  
  void goBack() {
    if (_navigationHistory.isNotEmpty) {
      _currentRoute = _navigationHistory.removeLast();
      notifyListeners();
    }
  }
  
  void clearHistory() {
    _navigationHistory.clear();
    notifyListeners();
  }
  
  // Tab-specific navigation
  void navigateToTab(String tab, UserMode userMode) {
    switch (userMode) {
      case UserMode.patient:
        _navigatePatientTab(tab);
        break;
      case UserMode.caregiver:
        _navigateCaregiverTab(tab);
        break;
      case UserMode.supervisor:
        _navigateSupervisorTab(tab);
        break;
    }
  }
  
  void _navigatePatientTab(String tab) {
    switch (tab) {
      case 'home':
        setCurrentIndex(0);
        setCurrentRoute('/patient/home');
        break;
      case 'checkin':
        setCurrentIndex(1);
        setCurrentRoute('/patient/checkin');
        break;
      case 'symptoms':
        setCurrentIndex(2);
        setCurrentRoute('/patient/symptoms');
        break;
      case 'medications':
        setCurrentIndex(3);
        setCurrentRoute('/patient/medications');
        break;
      case 'messages':
        setCurrentIndex(4);
        setCurrentRoute('/patient/messages');
        break;
    }
  }
  
  void _navigateCaregiverTab(String tab) {
    switch (tab) {
      case 'home':
        setCurrentIndex(0);
        setCurrentRoute('/caregiver/home');
        break;
      case 'patientlist':
        setCurrentIndex(1);
        setCurrentRoute('/caregiver/patients');
        break;
      case 'schedule':
        setCurrentIndex(2);
        setCurrentRoute('/caregiver/schedule');
        break;
      case 'calendar':
        setCurrentIndex(3);
        setCurrentRoute('/caregiver/calendar');
        break;
      case 'messages':
        setCurrentIndex(4);
        setCurrentRoute('/caregiver/messages');
        break;
    }
  }
  
  void _navigateSupervisorTab(String tab) {
    switch (tab) {
      case 'home':
        setCurrentIndex(0);
        setCurrentRoute('/supervisor/home');
        break;
      case 'caregiverlist':
        setCurrentIndex(1);
        setCurrentRoute('/supervisor/caregivers');
        break;
      case 'calendar':
        setCurrentIndex(2);
        setCurrentRoute('/supervisor/calendar');
        break;
      case 'mail':
        setCurrentIndex(3);
        setCurrentRoute('/supervisor/mail');
        break;
      case 'messages':
        setCurrentIndex(4);
        setCurrentRoute('/supervisor/messages');
        break;
    }
  }
  
  // Feature navigation
  void navigateToFeature(String feature) {
    setCurrentRoute('/feature/$feature');
    notifyListeners();
  }
  
  // Reset navigation
  void reset() {
    _currentIndex = 0;
    _currentRoute = '/';
    _navigationHistory.clear();
    notifyListeners();
  }
}
