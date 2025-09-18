import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/careconnect_theme.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateProvider, AuthProvider>(
      builder: (context, appState, authProvider, child) {
        if (authProvider.userMode == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CareConnectTheme.spacingM,
                vertical: CareConnectTheme.spacingS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildNavigationItems(context, authProvider.userMode!),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildNavigationItems(BuildContext context, UserMode userMode) {
    switch (userMode) {
      case UserMode.patient:
        return _buildPatientNavigationItems(context);
      case UserMode.caregiver:
        return _buildCaregiverNavigationItems(context);
      case UserMode.supervisor:
        return _buildSupervisorNavigationItems(context);
    }
  }

  List<Widget> _buildPatientNavigationItems(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final currentTab = appState.currentTab;

    return [
      _buildNavItem(
        context: context,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        isActive: currentTab == 'home',
        onTap: () => appState.setCurrentTab('home'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.check_circle_outline,
        activeIcon: Icons.check_circle,
        label: 'Check-in',
        isActive: currentTab == 'checkin',
        onTap: () => appState.setCurrentTab('checkin'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.health_and_safety_outlined,
        activeIcon: Icons.health_and_safety,
        label: 'Symptoms',
        isActive: currentTab == 'symptoms',
        onTap: () => appState.setCurrentTab('symptoms'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.medication_outlined,
        activeIcon: Icons.medication,
        label: 'Medications',
        isActive: currentTab == 'medications',
        onTap: () => appState.setCurrentTab('medications'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.message_outlined,
        activeIcon: Icons.message,
        label: 'Messages',
        isActive: currentTab == 'messages',
        onTap: () => appState.setCurrentTab('messages'),
      ),
    ];
  }

  List<Widget> _buildCaregiverNavigationItems(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final currentTab = appState.currentTab;

    return [
      _buildNavItem(
        context: context,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        isActive: currentTab == 'home',
        onTap: () => appState.setCurrentTab('home'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Patients',
        isActive: currentTab == 'patientlist',
        onTap: () => appState.setCurrentTab('patientlist'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.schedule_outlined,
        activeIcon: Icons.schedule,
        label: 'Schedule',
        isActive: currentTab == 'schedule',
        onTap: () => appState.setCurrentTab('schedule'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Calendar',
        isActive: currentTab == 'calendar',
        onTap: () => appState.setCurrentTab('calendar'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.message_outlined,
        activeIcon: Icons.message,
        label: 'Messages',
        isActive: currentTab == 'messages',
        onTap: () => appState.setCurrentTab('messages'),
      ),
    ];
  }

  List<Widget> _buildSupervisorNavigationItems(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final currentTab = appState.currentTab;

    return [
      _buildNavItem(
        context: context,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        isActive: currentTab == 'home',
        onTap: () => appState.setCurrentTab('home'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Caregivers',
        isActive: currentTab == 'caregiverlist',
        onTap: () => appState.setCurrentTab('caregiverlist'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Calendar',
        isActive: currentTab == 'calendar',
        onTap: () => appState.setCurrentTab('calendar'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.mail_outline,
        activeIcon: Icons.mail,
        label: 'Mail',
        isActive: currentTab == 'mail',
        onTap: () => appState.setCurrentTab('mail'),
      ),
      _buildNavItem(
        context: context,
        icon: Icons.message_outlined,
        activeIcon: Icons.message,
        label: 'Messages',
        isActive: currentTab == 'messages',
        onTap: () => appState.setCurrentTab('messages'),
      ),
    ];
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: CareConnectTheme.spacingS,
            horizontal: CareConnectTheme.spacingXS,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive 
                      ? CareConnectTheme.primaryColor.withValues(alpha:0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive 
                      ? CareConnectTheme.primaryColor
                      : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive 
                      ? CareConnectTheme.primaryColor
                      : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
