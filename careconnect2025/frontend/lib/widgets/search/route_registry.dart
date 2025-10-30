// lib/navigation/route_registry.dart
// Central catalog for search and navigation.
// Supports both GoRouter routes and direct widget pushes.

import 'package:flutter/material.dart';

// Imports for widgetBuilder entries used below
import 'package:care_connect_app/features/dashboard/caregiver-dashboard/pages/caregiver-dashboard.dart';
import 'package:care_connect_app/features/tasks/presentation/tasks_screen.dart';
import 'package:care_connect_app/features/tasks/presentation/assign_task_screen.dart';
import 'package:care_connect_app/features/tasks/presentation/custom_task_screen.dart';
import 'package:care_connect_app/features/tasks/presentation/pre_defined_task_screen.dart';
import 'package:care_connect_app/features/calls/presentation/pages/jitsi_meeting_screen.dart';
import 'package:care_connect_app/widgets/hybrid_video_call_widget.dart'; // VideoCallTestPage
import 'package:care_connect_app/features/invoices/models/invoice_models.dart'; // for comment only

enum AppRole { PATIENT, CAREGIVER, FAMILY_LINK, ADMIN }
enum NavKind { routePath, routeName, widgetBuilder }

class RouteParam {
  final String key;           // query or path param name
  final String label;         // prompt text
  final bool isPathParam;     // set true if this is a :param in path
  final String? defaultValue;
  const RouteParam({
    required this.key,
    required this.label,
    this.isPathParam = false,
    this.defaultValue,
  });
}

class RouteMeta {
  final String title;
  final String description;
  final List<String> keywords;

  final NavKind kind;
  final String? path;     // use when kind == routePath
  final String? routeName; // use when kind == routeName
  final Widget Function(Map<String, String> args)? builder; // when kind == widgetBuilder

  final Set<AppRole> roles;
  final List<RouteParam> params;
  final IconData icon;
  final bool launchable;  // false when page requires complex extras

  const RouteMeta({
    required this.title,
    required this.description,
    required this.keywords,
    required this.kind,
    this.path,
    this.routeName,
    this.builder,
    required this.roles,
    this.params = const [],
    this.icon = Icons.arrow_forward,
    this.launchable = true,
  });
}

AppRole? toAppRole(String role) {
  switch (role.toUpperCase()) {
    case 'PATIENT':
      return AppRole.PATIENT;
    case 'CAREGIVER':
      return AppRole.CAREGIVER;
    case 'FAMILY_LINK':
      return AppRole.FAMILY_LINK;
    case 'ADMIN':
      return AppRole.ADMIN;
  }
  return null;
}

const Set<AppRole> allRoles = {
  AppRole.PATIENT,
  AppRole.CAREGIVER,
  AppRole.FAMILY_LINK,
  AppRole.ADMIN,
};

const Set<AppRole> staffRoles = {
  AppRole.CAREGIVER,
  AppRole.ADMIN,
};

// IMPORTANT: final (not const) so we can include closures and other non-constant values.
final routeCatalog = <RouteMeta>[
  // Entry point and auth
  RouteMeta(
    title: 'Welcome',
    description: 'Welcome page',
    keywords: ['root', 'start', 'landing'],
    kind: NavKind.routePath,
    path: '/',
    roles: allRoles,
    icon: Icons.home,
  ),
  RouteMeta(
    title: 'Login',
    description: 'Login page',
    keywords: ['signin', 'auth'],
    kind: NavKind.routePath,
    path: '/login',
    roles: allRoles,
    icon: Icons.login,
  ),
  RouteMeta(
    title: 'Sign Up',
    description: 'Registration page',
    keywords: ['signup', 'register'],
    kind: NavKind.routePath,
    path: '/signup',
    roles: allRoles,
    icon: Icons.person_add,
  ),

  // Dashboards and role flows
  RouteMeta(
    title: 'Dashboard',
    description: 'Main dashboard',
    keywords: ['home', 'main'],
    kind: NavKind.routePath,
    path: '/dashboard',
    roles: allRoles,
    icon: Icons.dashboard,
  ),
  RouteMeta(
    title: 'Dashboard (Patient direct)',
    description: 'Patient dashboard via path',
    keywords: ['dashboard', 'patient'],
    kind: NavKind.routePath,
    path: '/dashboard/patient',
    roles: {AppRole.PATIENT, AppRole.ADMIN},
    icon: Icons.person,
  ),
  RouteMeta(
    title: 'Dashboard (Caregiver via backend redirect)',
    description: 'Caregiver dashboard via path with caregiverId and optional patientId',
    keywords: ['dashboard', 'caregiver'],
    kind: NavKind.routePath,
    path: '/dashboard/caregiver',
    roles: {AppRole.CAREGIVER, AppRole.ADMIN},
    icon: Icons.health_and_safety,
  ),
  RouteMeta(
    title: 'Caregiver Dashboard (direct widget)',
    description: 'Opens CaregiverDashboard widget',
    keywords: ['caregiver', 'dashboard'],
    kind: NavKind.widgetBuilder,
    builder: (_) => const CaregiverDashboard(),
    roles: {AppRole.CAREGIVER, AppRole.ADMIN},
    icon: Icons.monitor_heart,
  ),
  RouteMeta(
    title: 'Home Redirect',
    description: 'Redirects to dashboard if logged in',
    keywords: ['home'],
    kind: NavKind.routePath,
    path: '/home',
    roles: allRoles,
    icon: Icons.refresh,
  ),

  // Registration flows
  RouteMeta(
    title: 'Register Caregiver',
    description: 'Caregiver registration',
    keywords: ['caregiver', 'register'],
    kind: NavKind.routePath,
    path: '/register/caregiver',
    roles: allRoles,
    icon: Icons.app_registration,
  ),
  RouteMeta(
    title: 'Register Patient',
    description: 'Patient registration',
    keywords: ['patient', 'register'],
    kind: NavKind.routePath,
    path: '/register/patient',
    roles: allRoles,
    icon: Icons.app_registration,
  ),
  RouteMeta(
    title: 'Add Patient',
    description: 'Add a patient',
    keywords: ['patient', 'add'],
    kind: NavKind.routePath,
    path: '/add-patient',
    roles: staffRoles,
    icon: Icons.person_add_alt_1,
  ),

  // Social
  RouteMeta(
    title: 'Social Feed',
    description: 'Main social feed',
    keywords: ['social', 'feed'],
    kind: NavKind.routePath,
    path: '/social-feed',
    roles: allRoles,
    icon: Icons.dynamic_feed,
  ),

  // Payments and subscriptions
  RouteMeta(
    title: 'Select Package',
    description: 'Select subscription package',
    keywords: ['subscription', 'plan', 'package'],
    kind: NavKind.routePath,
    path: '/select-package',
    roles: allRoles,
    icon: Icons.shopping_cart,
  ),
  RouteMeta(
    title: 'Subscription',
    description: 'Subscription management',
    keywords: ['subscription', 'billing'],
    kind: NavKind.routePath,
    path: '/subscription',
    roles: allRoles,
    icon: Icons.subscriptions,
  ),
  RouteMeta(
    title: 'Stripe Checkout',
    description: 'Stripe checkout page',
    keywords: ['stripe', 'checkout'],
    kind: NavKind.routePath,
    path: '/stripe-checkout',
    roles: allRoles,
    icon: Icons.payment,
  ),
  RouteMeta(
    title: 'Payment Success',
    description: 'Payment success callback',
    keywords: ['payment', 'success'],
    kind: NavKind.routePath,
    path: '/payment-success',
    roles: allRoles,
    icon: Icons.verified,
  ),
  RouteMeta(
    title: 'Payment Cancel',
    description: 'Payment canceled',
    keywords: ['payment', 'cancel'],
    kind: NavKind.routePath,
    path: '/payment-cancel',
    roles: allRoles,
    icon: Icons.cancel,
  ),

  // Password flows
  RouteMeta(
    title: 'Reset Password',
    description: 'Reset password screen',
    keywords: ['password', 'reset'],
    kind: NavKind.routePath,
    path: '/reset-password',
    roles: allRoles,
    icon: Icons.lock_reset,
  ),
  RouteMeta(
    title: 'Setup Password',
    description: 'Setup password using token',
    keywords: ['password', 'setup', 'token'],
    kind: NavKind.routePath,
    path: '/setup-password',
    roles: allRoles,
    icon: Icons.password,
  ),

  // Gamification
  RouteMeta(
    title: 'Gamification',
    description: 'Gamification screen',
    keywords: ['game', 'points'],
    kind: NavKind.routePath,
    path: '/gamification',
    roles: allRoles,
    icon: Icons.sports_esports,
  ),

  // OAuth
  RouteMeta(
    title: 'OAuth Callback',
    description: 'OAuth callback handler',
    keywords: ['oauth', 'callback'],
    kind: NavKind.routePath,
    path: '/oauth/callback',
    roles: allRoles,
    icon: Icons.link,
  ),

  // Video and calls
  RouteMeta(
    title: 'Video Call',
    description: 'Start a Jitsi call for a patient',
    keywords: ['video', 'call', 'jitsi'],
    kind: NavKind.routePath,
    path: '/video-call',
    roles: allRoles,
    icon: Icons.video_call,
  ),
  RouteMeta(
    title: 'Video Call Test',
    description: 'Video call test page',
    keywords: ['video', 'test'],
    kind: NavKind.widgetBuilder,
    builder: (_) => const VideoCallTestPage(),
    roles: allRoles,
    icon: Icons.video_camera_front,
  ),
  RouteMeta(
    title: 'Jitsi Meeting (ad hoc)',
    description: 'Open ad hoc Jitsi meeting by room name',
    keywords: ['jitsi', 'meeting', 'call'],
    kind: NavKind.widgetBuilder,
    builder: (args) => JitsiMeetingScreen(
      roomName: args['roomName'] ?? 'room_${DateTime.now().millisecondsSinceEpoch}',
    ),
    roles: allRoles,
    params: [
      RouteParam(key: 'roomName', label: 'Room Name', defaultValue: ''),
    ],
    icon: Icons.call,
  ),

  // Wearables and integrations
  RouteMeta(
    title: 'Wearables',
    description: 'Wearables screen',
    keywords: ['wearables', 'fitbit', 'devices'],
    kind: NavKind.routePath,
    path: '/wearables',
    roles: allRoles,
    icon: Icons.watch,
  ),
  RouteMeta(
    title: 'Home Monitoring',
    description: 'Home monitoring screen',
    keywords: ['home', 'monitoring'],
    kind: NavKind.routePath,
    path: '/home-monitoring',
    roles: allRoles,
    icon: Icons.sensor_occupied,
  ),
  RouteMeta(
    title: 'Smart Devices',
    description: 'Smart devices page',
    keywords: ['smart', 'devices', 'iot'],
    kind: NavKind.routePath,
    path: '/smart-devices',
    roles: allRoles,
    icon: Icons.devices_other,
  ),
  RouteMeta(
    title: 'Medication Management',
    description: 'Medication management',
    keywords: ['medication', 'rx'],
    kind: NavKind.routePath,
    path: '/medication',
    roles: allRoles,
    icon: Icons.medication,
  ),

  // EVV flows
  RouteMeta(
    title: 'EVV Dashboard',
    description: 'Electronic Visit Verification dashboard',
    keywords: ['evv', 'visit'],
    kind: NavKind.routePath,
    path: '/evv',
    roles: staffRoles,
    icon: Icons.verified,
  ),
  RouteMeta(
    title: 'EVV Select Patient',
    description: 'Select patient for EVV',
    keywords: ['evv', 'select', 'patient'],
    kind: NavKind.routePath,
    path: '/evv/select-patient',
    roles: staffRoles,
    icon: Icons.person_search,
  ),
  RouteMeta(
    title: 'EVV Start Visit',
    description: 'Start visit for patient',
    keywords: ['evv', 'start', 'visit'],
    kind: NavKind.routePath,
    path: '/evv/start-visit',
    roles: staffRoles,
    icon: Icons.play_arrow,
  ),
  RouteMeta(
    title: 'EVV Checkin Location',
    description: 'Check in to a location',
    keywords: ['evv', 'checkin'],
    kind: NavKind.routePath,
    path: '/evv/checkin-location',
    roles: staffRoles,
    icon: Icons.login,
  ),
  RouteMeta(
    title: 'EVV Visit In Progress',
    description: 'Visit in progress',
    keywords: ['evv', 'progress'],
    kind: NavKind.routePath,
    path: '/evv/visit-progress',
    roles: staffRoles,
    icon: Icons.timelapse,
  ),
  RouteMeta(
    title: 'EVV Checkout Location',
    description: 'Checkout from a location',
    keywords: ['evv', 'checkout'],
    kind: NavKind.routePath,
    path: '/evv/checkout-location',
    roles: staffRoles,
    icon: Icons.logout,
  ),
  RouteMeta(
    title: 'EVV Visit Complete',
    description: 'Visit complete summary',
    keywords: ['evv', 'complete'],
    kind: NavKind.routePath,
    path: '/evv/visit-complete',
    roles: staffRoles,
    icon: Icons.assignment_turned_in,
  ),
  RouteMeta(
    title: 'EVV Visit Completed Success',
    description: 'Visit completed success screen',
    keywords: ['evv', 'success'],
    kind: NavKind.routePath,
    path: '/evv/visit-completed-success',
    roles: staffRoles,
    icon: Icons.check_circle,
  ),
  RouteMeta(
    title: 'EVV Record Review',
    description: 'Review EVV records',
    keywords: ['evv', 'review'],
    kind: NavKind.routePath,
    path: '/evv/review-records',
    roles: staffRoles,
    icon: Icons.fact_check,
  ),
  RouteMeta(
    title: 'EVV Visit History',
    description: 'Visit history',
    keywords: ['evv', 'history'],
    kind: NavKind.routePath,
    path: '/evv/visit-history',
    roles: staffRoles,
    icon: Icons.history,
  ),
  RouteMeta(
    title: 'EVV Corrections',
    description: 'EVV corrections',
    keywords: ['evv', 'corrections'],
    kind: NavKind.routePath,
    path: '/evv/corrections',
    roles: staffRoles,
    icon: Icons.edit,
  ),
  RouteMeta(
    title: 'EVV Offline Sync',
    description: 'Sync when offline',
    keywords: ['evv', 'offline', 'sync'],
    kind: NavKind.routePath,
    path: '/evv/offline-sync',
    roles: staffRoles,
    icon: Icons.sync,
  ),

  // Profile and settings
  RouteMeta(
    title: 'Profile Settings',
    description: 'Update profile settings',
    keywords: ['profile', 'settings'],
    kind: NavKind.routePath,
    path: '/profile-settings',
    roles: allRoles,
    icon: Icons.settings,
  ),
  RouteMeta(
    title: 'Profile',
    description: 'Profile page',
    keywords: ['profile', 'account'],
    kind: NavKind.routePath,
    path: '/profile',
    roles: allRoles,
    icon: Icons.person_outline,
  ),
  RouteMeta(
    title: 'Settings',
    description: 'App settings',
    keywords: ['settings', 'preferences'],
    kind: NavKind.routePath,
    path: '/settings',
    roles: allRoles,
    icon: Icons.tune,
  ),
  RouteMeta(
    title: 'File Management',
    description: 'Manage files',
    keywords: ['files', 'documents'],
    kind: NavKind.routePath,
    path: '/file-management',
    roles: allRoles,
    icon: Icons.folder,
  ),
  RouteMeta(
    title: 'AI Configuration',
    description: 'Configure AI features',
    keywords: ['ai', 'config'],
    kind: NavKind.routePath,
    path: '/ai-configuration',
    roles: allRoles,
    icon: Icons.psychology,
  ),
  RouteMeta(
    title: 'Notetaker Configuration',
    description: 'Configure notetaker',
    keywords: ['notetaker', 'config'],
    kind: NavKind.routePath,
    path: '/notetaker-configuration',
    roles: staffRoles,
    icon: Icons.notes,
  ),

  // Notetaker search and detail
  RouteMeta(
    title: 'Notetaker Search',
    description: 'Search notes',
    keywords: ['notetaker', 'notes', 'search'],
    kind: NavKind.routePath,
    path: '/notetaker-search',
    roles: staffRoles,
    icon: Icons.search,
  ),
  RouteMeta(
    title: 'Notetaker Detail',
    description: 'Requires PatientNote extra. Listed for discoverability only.',
    keywords: ['notetaker', 'detail'],
    kind: NavKind.routePath,
    path: '/notetaker/detail/:noteId',
    roles: staffRoles,
    params: [RouteParam(key: 'noteId', label: 'Note ID', isPathParam: true)],
    icon: Icons.description,
    launchable: false, // needs a PatientNote in state.extra
  ),

  // Calendar and check in
  RouteMeta(
    title: 'Calendar Assistant',
    description: 'Calendar assistant screen',
    keywords: ['calendar', 'schedule'],
    kind: NavKind.routePath,
    path: '/calendar',
    roles: allRoles,
    icon: Icons.calendar_today,
  ),
  RouteMeta(
    title: 'Virtual Check In',
    description: 'Patient virtual check in',
    keywords: ['checkin', 'virtual'],
    kind: NavKind.routePath,
    path: '/virtual-checkin',
    roles: allRoles,
    icon: Icons.how_to_reg,
  ),

  // Alexa and USPS informed delivery
  RouteMeta(
    title: 'Alexa Login',
    description: 'Login with Alexa',
    keywords: ['alexa', 'login'],
    kind: NavKind.routePath,
    path: '/alexaLogin',
    roles: allRoles,
    icon: Icons.speaker,
  ),
  RouteMeta(
    title: 'Informed Delivery',
    description: 'USPS informed delivery screen',
    keywords: ['mail', 'usps', 'delivery'],
    kind: NavKind.routePath,
    path: '/informed-delivery',
    roles: allRoles,
    icon: Icons.mark_email_read,
  ),

  // Legacy menu redirects listed for discoverability
  RouteMeta(
    title: 'Legacy Task Scheduling',
    description: 'Legacy route that redirects to dashboard tasks tab when logged in',
    keywords: ['legacy', 'taskscheduling'],
    kind: NavKind.routePath,
    path: '/taskscheduling',
    roles: allRoles,
    icon: Icons.history_toggle_off,
  ),
  RouteMeta(
    title: 'Legacy Chat and Calls',
    description: 'Legacy route that redirects to messages tab when logged in',
    keywords: ['legacy', 'chat', 'calls'],
    kind: NavKind.routePath,
    path: '/chatandcalls',
    roles: allRoles,
    icon: Icons.chat,
  ),
  RouteMeta(
    title: 'Legacy AI Assistant',
    description: 'Legacy route that redirects to dashboard',
    keywords: ['legacy', 'ai'],
    kind: NavKind.routePath,
    path: '/aiassistant',
    roles: allRoles,
    icon: Icons.smart_toy,
  ),
  RouteMeta(
    title: 'Legacy Fitbit',
    description: 'Legacy route that redirects to wearables',
    keywords: ['legacy', 'fitbit'],
    kind: NavKind.routePath,
    path: '/fitbit',
    roles: allRoles,
    icon: Icons.fitness_center,
  ),
  RouteMeta(
    title: 'Legacy SOS',
    description: 'Legacy route that redirects to dashboard when logged in',
    keywords: ['legacy', 'sos', 'alert'],
    kind: NavKind.routePath,
    path: '/sos',
    roles: allRoles,
    icon: Icons.sos,
  ),

  // Patient flows
  RouteMeta(
    title: 'Patient Status',
    description: 'View patient status by ID',
    keywords: ['patient', 'status'],
    kind: NavKind.routePath,
    path: '/patient/:id',
    roles: staffRoles,
    params: [RouteParam(key: 'id', label: 'Patient ID', isPathParam: true)],
    icon: Icons.personal_injury,
  ),
  RouteMeta(
    title: 'Analytics',
    description: 'Patient analytics by patientId',
    keywords: ['analytics', 'charts'],
    kind: NavKind.routePath,
    path: '/analytics',
    roles: staffRoles,
    params: [RouteParam(key: 'patientId', label: 'Patient ID')],
    icon: Icons.analytics,
  ),

  // Patient task pages pushed as widgets
  RouteMeta(
    title: 'Patient Tasks',
    description: 'Tasks for a specific patient',
    keywords: ['tasks', 'patient'],
    kind: NavKind.widgetBuilder,
    builder: (args) => TasksScreen(
      patientId: int.tryParse(args['patientId'] ?? '0') ?? 0,
      patientName: args['patientName'] ?? 'Name Not Found',
    ),
    roles: staffRoles,
    params: [
      RouteParam(key: 'patientId', label: 'Patient ID'),
      RouteParam(key: 'patientName', label: 'Patient Name', defaultValue: 'Name Not Found'),
    ],
    icon: Icons.check_circle,
  ),
  RouteMeta(
    title: 'Assign Task',
    description: 'Assign a task to a patient',
    keywords: ['tasks', 'assign'],
    kind: NavKind.widgetBuilder,
    builder: (args) => AssignTaskScreen(
      patientId: int.tryParse(args['patientId'] ?? '0') ?? 0,
      patientName: args['patientName'] ?? 'Name Not Found',
    ),
    roles: staffRoles,
    params: [
      RouteParam(key: 'patientId', label: 'Patient ID'),
      RouteParam(key: 'patientName', label: 'Patient Name', defaultValue: 'Name Not Found'),
    ],
    icon: Icons.assignment_ind,
  ),
  RouteMeta(
    title: 'Custom Task Scheduling',
    description: 'Create a custom task schedule',
    keywords: ['tasks', 'custom', 'schedule'],
    kind: NavKind.widgetBuilder,
    builder: (args) => CustomTaskScreen(
      patientId: int.tryParse(args['patientId'] ?? '0') ?? 0,
      patientName: args['patientName'] ?? 'Name Not Found',
    ),
    roles: staffRoles,
    params: [
      RouteParam(key: 'patientId', label: 'Patient ID'),
      RouteParam(key: 'patientName', label: 'Patient Name', defaultValue: 'Name Not Found'),
    ],
    icon: Icons.schedule,
  ),
  RouteMeta(
    title: 'Pre Defined Task',
    description: 'Schedule a pre defined task template for a patient',
    keywords: ['tasks', 'template'],
    kind: NavKind.widgetBuilder,
    builder: (args) => PreDefinedTaskScreen(
      patientId: int.tryParse(args['patientId'] ?? '0') ?? 0,
      templateId: int.tryParse(args['templateId'] ?? '0') ?? 0,
      patientName: args['patientName'] ?? 'Name Not Found',
    ),
    roles: staffRoles,
    params: [
      RouteParam(key: 'patientId', label: 'Patient ID'),
      RouteParam(key: 'templateId', label: 'Template ID'),
      RouteParam(key: 'patientName', label: 'Patient Name', defaultValue: 'Name Not Found'),
    ],
    icon: Icons.fact_check,
  ),

  // Invoices (named routes)
  RouteMeta(
    title: 'Invoice Dashboard',
    description: 'Invoices dashboard',
    keywords: ['invoice', 'billing', 'dashboard'],
    kind: NavKind.routeName,
    routeName: 'invoiceDashboard',
    roles: staffRoles,
    icon: Icons.receipt_long,
  ),
  RouteMeta(
    title: 'Invoice Upload',
    description: 'Upload invoices',
    keywords: ['invoice', 'upload'],
    kind: NavKind.routeName,
    routeName: 'invoiceUpload',
    roles: staffRoles,
    icon: Icons.upload_file,
  ),
  RouteMeta(
    title: 'Invoice List',
    description: 'List of invoices',
    keywords: ['invoice', 'list'],
    kind: NavKind.routeName,
    routeName: 'invoiceList',
    roles: staffRoles,
    icon: Icons.list_alt,
  ),
  RouteMeta(
    title: 'Invoice List (Filtered)',
    description: 'List invoices by filter',
    keywords: ['invoice', 'list', 'filter'],
    kind: NavKind.routeName,
    routeName: 'invoiceListFiltered',
    roles: staffRoles,
    params: [
      RouteParam(key: 'filter', label: 'Filter', isPathParam: true),
    ],
    icon: Icons.filter_alt,
  ),
  RouteMeta(
    title: 'Invoice Detail',
    description: 'Requires Invoice extra at runtime',
    keywords: ['invoice', 'detail'],
    kind: NavKind.routeName,
    routeName: 'invoiceDetail',
    roles: staffRoles,
    params: [
      RouteParam(key: 'id', label: 'Invoice ID', isPathParam: true),
    ],
    icon: Icons.description,
    launchable: false, // needs Invoice model in state.extra
  ),

  // Menu and alerts
  RouteMeta(
    title: 'Menu',
    description: 'Main menu page',
    keywords: ['menu', 'nav'],
    kind: NavKind.routeName,
    routeName: 'menupage',
    roles: allRoles,
    icon: Icons.menu,
  ),
  RouteMeta(
    title: 'Fall Alert Lab',
    description: 'Mock fall alert page',
    keywords: ['alert', 'fall'],
    kind: NavKind.routePath,
    path: '/alertpage',
    roles: allRoles,
    icon: Icons.warning_amber,
  ),
  RouteMeta(
    title: 'Fall Alert Patient',
    description: 'Fall prompt for patients',
    keywords: ['alert', 'fall', 'patient'],
    kind: NavKind.routePath,
    path: '/alertpage-patient',
    roles: allRoles,
    icon: Icons.emergency,
  ),
];
