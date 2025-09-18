import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'create_account_screen.dart';
import 'patient_home_screen.dart';
import 'caregiver_home_screen.dart';
import 'supervisor_home_screen.dart';
import 'check_in_screen.dart';
import 'symptoms_screen.dart';
import 'medications_screen.dart';
import 'reports_screen.dart';
import 'messages_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';
import 'features/gamification_screen.dart';
import 'features/patient_list_screen.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/additional_features_menu.dart';

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateProvider, AuthProvider>(
      builder: (context, appState, authProvider, child) {
        // Show splash screen first
        if (appState.showSplash) {
          return const SplashScreen();
        }

        // Show welcome screen after splash
        if (appState.showWelcome) {
          return const WelcomeScreen();
        }

        // If not logged in, show login or create account page
        if (authProvider.userMode == null) {
          if (appState.isCreateAccountVisible) {
            return const CreateAccountScreen();
          }
          return const LoginScreen();
        }

        // If settings is open, show settings page
        if (appState.isSettingsVisible) {
          return const SettingsScreen();
        }

        // If gamification is open, show gamification page
        if (appState.showGamification) {
          return const GamificationScreen();
        }

        // Main app with bottom navigation
        return Scaffold(
          body: _buildCurrentPage(context, appState, authProvider),
          bottomNavigationBar: const BottomNavigation(),
          floatingActionButton: authProvider.userMode != null ? const AdditionalFeaturesMenu() : null,
        );
      },
    );
  }

  Widget _buildCurrentPage(BuildContext context, AppStateProvider appState, AuthProvider authProvider) {
    
    if (authProvider.userMode == UserMode.supervisor) {
      switch (appState.currentTab) {
        case 'home':
          return const SupervisorHomeScreen();
        case 'caregiverlist':
          return const Center(child: Text('Caregiver List - Coming Soon'));
        case 'calendar':
          return const Center(child: Text('Calendar - Coming Soon'));
        case 'mail':
          return const Center(child: Text('Mail - Coming Soon'));
        case 'messages':
          return const MessagesScreen();
        default:
          return const SupervisorHomeScreen();
      }
    }

    // Caregiver mode
    if (authProvider.userMode == UserMode.caregiver) {
      switch (appState.currentTab) {
        case 'home':
          return const CaregiverHomeScreen();
        case 'patientlist':
          return const PatientListScreen();
        case 'schedule':
          return const ScheduleScreen();
        case 'calendar':
          return const Center(child: Text('Calendar - Coming Soon'));
        case 'mail':
          return const Center(child: Text('Mail - Coming Soon'));
        case 'messages':
          return const MessagesScreen();
        default:
          return const CaregiverHomeScreen();
      }
    }

    // Patient mode
    switch (appState.currentTab) {
      case 'home':
        return const PatientHomeScreen();
      case 'checkin':
        return const CheckInScreen();
      case 'symptoms':
        return const SymptomsScreen();
      case 'medications':
        return const MedicationsScreen();
      case 'reports':
        return const ReportsScreen();
      case 'messages':
        return const MessagesScreen();
      default:
        return const PatientHomeScreen();
    }
  }
}
