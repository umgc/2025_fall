import 'package:flutter/material.dart';

enum UserMode { patient, caregiver, supervisor }

class AppStateProvider extends ChangeNotifier {
  // App state
  bool _showSplash = true;
  bool _showWelcome = false;
  bool _showCreateAccount = false;
  bool _showSettings = false;
  bool _isDemoMode = true; // Start in demo mode for design showcase
  
  // Navigation state
  String _currentTab = 'home';
  bool _showPatientDashboard = false;
  String? _selectedPatientForChat;
  
  // Advanced features state
  bool _showGamification = false;
  bool _showBilling = false;
  bool _showStripePayment = false;
  String _selectedPlan = 'monthly';
  bool _showInvoiceCapture = false;
  bool _showInvoiceReview = false;
  bool _showInvoiceConfirmation = false;
  bool _showInvoiceDetails = false;
  bool _showInvoiceSearch = false;
  bool _showRoleBasedAccess = false;
  bool _showEVVParticipantSelect = false;
  bool _showEVVSession = false;
  bool _showEVVActiveSession = false;
  bool _showEVVClockOut = false;
  bool _showEVVHistory = false;
  bool _showVisitNotetaker = false;
  bool _showASLConverter = false;
  bool _showASLTelemedicine = false;
  bool _showNotetakerSettings = false;
  bool _showNotesConfiguration = false;
  bool _showExcludedNumbersEditor = false;
  bool _showPIIKeywordsEditor = false;
  bool _showTriggerEditor = false;
  bool _showNoteManagement = false;
  bool _showCustomDateRange = false;
  bool _showAlerts = false;
  bool _showCalendar = false;
  bool _showMailAssistant = false;
  bool _showTools = false;
  bool _showNotificationSettings = false;
  bool _showNotificationPreferences = false;
  bool _showNotificationDemo = false;
  bool _showAdditionalFeatures = false;
  
  // Data state
  Map<String, dynamic>? _currentInvoiceData;
  String? _selectedInvoiceId;
  List<dynamic> _selectedParticipants = [];
  Map<String, dynamic>? _currentSessionData;
  
  // Preferences
  Map<String, dynamic> _snoozePreferences = {
    'enabled': true,
    'defaultMinutes': 15,
  };
  
  // Getters
  bool get showSplash => _showSplash;
  bool get showWelcome => _showWelcome;
  bool get isCreateAccountVisible => _showCreateAccount;
  bool get isSettingsVisible => _showSettings;
  bool get isDemoMode => _isDemoMode;
  String get currentTab => _currentTab;
  bool get showPatientDashboard => _showPatientDashboard;
  String? get selectedPatientForChat => _selectedPatientForChat;
  bool get showGamification => _showGamification;
  bool get showBilling => _showBilling;
  bool get showStripePayment => _showStripePayment;
  String get selectedPlan => _selectedPlan;
  bool get showInvoiceCapture => _showInvoiceCapture;
  bool get showInvoiceReview => _showInvoiceReview;
  bool get showInvoiceConfirmation => _showInvoiceConfirmation;
  bool get showInvoiceDetails => _showInvoiceDetails;
  bool get showInvoiceSearch => _showInvoiceSearch;
  bool get showRoleBasedAccess => _showRoleBasedAccess;
  bool get showEVVParticipantSelect => _showEVVParticipantSelect;
  bool get showEVVSession => _showEVVSession;
  bool get showEVVActiveSession => _showEVVActiveSession;
  bool get showEVVClockOut => _showEVVClockOut;
  bool get showEVVHistory => _showEVVHistory;
  bool get showVisitNotetaker => _showVisitNotetaker;
  bool get showASLConverter => _showASLConverter;
  bool get showASLTelemedicine => _showASLTelemedicine;
  bool get showNotetakerSettings => _showNotetakerSettings;
  bool get showNotesConfiguration => _showNotesConfiguration;
  bool get showExcludedNumbersEditor => _showExcludedNumbersEditor;
  bool get showPIIKeywordsEditor => _showPIIKeywordsEditor;
  bool get showTriggerEditor => _showTriggerEditor;
  bool get showNoteManagement => _showNoteManagement;
  bool get showCustomDateRange => _showCustomDateRange;
  bool get showAlerts => _showAlerts;
  bool get showCalendar => _showCalendar;
  bool get showMailAssistant => _showMailAssistant;
  bool get showTools => _showTools;
  bool get showNotificationSettings => _showNotificationSettings;
  bool get showNotificationPreferences => _showNotificationPreferences;
  bool get showNotificationDemo => _showNotificationDemo;
  bool get showAdditionalFeatures => _showAdditionalFeatures;
  Map<String, dynamic>? get currentInvoiceData => _currentInvoiceData;
  String? get selectedInvoiceId => _selectedInvoiceId;
  List<dynamic> get selectedParticipants => _selectedParticipants;
  Map<String, dynamic>? get currentSessionData => _currentSessionData;
  Map<String, dynamic> get snoozePreferences => _snoozePreferences;
  
  // App flow methods
  void hideSplash() {
    _showSplash = false;
    _showWelcome = false; // Skip welcome screen for cleaner startup
    notifyListeners();
  }
  
  void hideWelcome() {
    _showWelcome = false;
    notifyListeners();
  }
  
  void showCreateAccount() {
    _showCreateAccount = true;
    notifyListeners();
  }
  
  void hideCreateAccount() {
    _showCreateAccount = false;
    notifyListeners();
  }
  
  void showSettings() {
    _showSettings = true;
    notifyListeners();
  }
  
  void handleCloseSettings() {
    _showSettings = false;
    notifyListeners();
  }
  
  // Demo mode
  void setDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }
  
  // Navigation
  void setCurrentTab(String tab) {
    _currentTab = tab;
    notifyListeners();
  }
  
  // Reset app state
  void reset() {
    _showSplash = true;
    _showWelcome = false; // Keep welcome screen disabled
    _showCreateAccount = false;
    _showSettings = false;
    _currentTab = 'home';
    _showPatientDashboard = false;
    _selectedPatientForChat = null;
    _showGamification = false;
    _showBilling = false;
    _showStripePayment = false;
    _showInvoiceCapture = false;
    _showInvoiceReview = false;
    _showInvoiceConfirmation = false;
    _showInvoiceDetails = false;
    _showInvoiceSearch = false;
    _showRoleBasedAccess = false;
    _showEVVParticipantSelect = false;
    _showEVVSession = false;
    _showEVVActiveSession = false;
    _showEVVClockOut = false;
    _showEVVHistory = false;
    _showVisitNotetaker = false;
    _showASLConverter = false;
    _showASLTelemedicine = false;
    _showNotetakerSettings = false;
    _showNotesConfiguration = false;
    _showExcludedNumbersEditor = false;
    _showPIIKeywordsEditor = false;
    _showTriggerEditor = false;
    _showNoteManagement = false;
    _showCustomDateRange = false;
    _showAlerts = false;
    _showCalendar = false;
    _showMailAssistant = false;
    _showTools = false;
    _showNotificationSettings = false;
    _showNotificationPreferences = false;
    _showNotificationDemo = false;
    _showAdditionalFeatures = false;
    _currentInvoiceData = null;
    _selectedInvoiceId = null;
    _selectedParticipants = [];
    _currentSessionData = null;
    notifyListeners();
  }

  // Login handler
  void handleLogin(UserMode mode) {
    _currentTab = 'home';
    _showPatientDashboard = false;
    _selectedPatientForChat = null;
    _showSettings = false;
    _showCreateAccount = false;
    notifyListeners();
  }

  // Patient chat handler
  void handleOpenPatientChat(String patientId) {
    _selectedPatientForChat = patientId;
    _currentTab = 'messages';
    _showPatientDashboard = false;
    _showSettings = false;
    notifyListeners();
  }

  // Gamification handlers
  void handleOpenGamification() {
    _showSettings = false;
    _showTools = false;
    _showGamification = true;
    notifyListeners();
  }

  void handleCloseGamification() {
    _showGamification = false;
    _currentTab = 'home';
    notifyListeners();
  }

  // Billing handlers
  void handleOpenBilling() {
    _showSettings = false;
    _showTools = false;
    _showBilling = true;
    notifyListeners();
  }

  void handleCloseBilling() {
    _showBilling = false;
    _currentTab = 'home';
    notifyListeners();
  }

  // Stripe payment handlers
  void handleOpenStripePayment([String plan = 'monthly']) {
    _selectedPlan = plan;
    _showStripePayment = true;
    _showBilling = false;
    notifyListeners();
  }

  void handleCloseStripePayment() {
    _showStripePayment = false;
    _showBilling = true;
    notifyListeners();
  }

  void handlePaymentSuccess() {
    _showStripePayment = false;
    _showBilling = false;
    _currentTab = 'home';
    notifyListeners();
  }

  // Calendar handlers
  void handleOpenCalendar() {
    _showCalendar = true;
    notifyListeners();
  }

  void handleCloseCalendar() {
    _showCalendar = false;
    _currentTab = 'home';
    notifyListeners();
  }

  // Mail Assistant handlers
  void handleOpenMailAssistant() {
    _showMailAssistant = true;
    notifyListeners();
  }

  void handleCloseMailAssistant() {
    _showMailAssistant = false;
    notifyListeners();
  }

  // Tools handlers
  void handleOpenTools() {
    _showTools = true;
    notifyListeners();
  }

  void handleCloseTools() {
    _showTools = false;
    notifyListeners();
  }

  // Additional Features handlers
  void handleOpenAdditionalFeatures() {
    _showAdditionalFeatures = true;
    notifyListeners();
  }

  void handleCloseAdditionalFeatures() {
    _showAdditionalFeatures = false;
    notifyListeners();
  }

  // Feature handlers from Additional Features menu
  void handleOpenGamificationFromMenu() {
    _showAdditionalFeatures = false;
    _showGamification = true;
    notifyListeners();
  }

  void handleOpenBillingFromMenu() {
    _showAdditionalFeatures = false;
    _showBilling = true;
    notifyListeners();
  }

  void handleOpenMailAssistantFromMenu() {
    _showAdditionalFeatures = false;
    _showMailAssistant = true;
    notifyListeners();
  }

  void handleOpenEVVFromMenu() {
    _showAdditionalFeatures = false;
    _showEVVParticipantSelect = true;
    notifyListeners();
  }

  void handleOpenVisitNotetakerFromMenu() {
    _showAdditionalFeatures = false;
    _showVisitNotetaker = true;
    notifyListeners();
  }

  void handleOpenASLConverterFromMenu() {
    _showAdditionalFeatures = false;
    _showASLConverter = true;
    notifyListeners();
  }

  void handleOpenASLTelemedicineFromMenu() {
    _showAdditionalFeatures = false;
    _showASLTelemedicine = true;
    notifyListeners();
  }

  void handleOpenRoleBasedAccessFromMenu() {
    _showAdditionalFeatures = false;
    _showRoleBasedAccess = true;
    notifyListeners();
  }

  void handleOpenInvoiceCaptureFromMenu() {
    _showAdditionalFeatures = false;
    _showInvoiceCapture = true;
    notifyListeners();
  }

  void handleOpenInvoiceSearchFromMenu() {
    _showAdditionalFeatures = false;
    _showInvoiceSearch = true;
    notifyListeners();
  }

  // Snooze preferences change
  void handleSnoozePreferencesChange(Map<String, dynamic> preferences) {
    _snoozePreferences = preferences;
    notifyListeners();
  }
}
