import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/careconnect_theme.dart';

class AdditionalFeaturesMenu extends StatefulWidget {
  const AdditionalFeaturesMenu({super.key});

  @override
  State<AdditionalFeaturesMenu> createState() => _AdditionalFeaturesMenuState();
}

class _AdditionalFeaturesMenuState extends State<AdditionalFeaturesMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    final appState = context.read<AppStateProvider>();
    if (appState.showAdditionalFeatures) {
      _animationController.reverse();
      appState.handleCloseAdditionalFeatures();
    } else {
      _animationController.forward();
      appState.handleOpenAdditionalFeatures();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateProvider, AuthProvider>(
      builder: (context, appState, authProvider, child) {
        return Stack(
          children: [
            // Menu items
            if (appState.showAdditionalFeatures)
              Positioned(
                bottom: 80,
                right: 0,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildMenuItems(context, appState, authProvider),
                    ),
                  ),
                ),
              ),
            
            // Floating action button
            Positioned(
              bottom: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: FloatingActionButton(
                      onPressed: _toggleMenu,
                      backgroundColor: CareConnectTheme.primaryColor,
                      child: Icon(
                        appState.showAdditionalFeatures ? Icons.close : Icons.add,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, AppStateProvider appState, AuthProvider authProvider) {
    final userMode = authProvider.userMode;
    
    switch (userMode) {
      case UserMode.patient:
        return _buildPatientMenuItems(context, appState);
      case UserMode.caregiver:
        return _buildCaregiverMenuItems(context, appState);
      case UserMode.supervisor:
        return _buildSupervisorMenuItems(context, appState);
      default:
        return [];
    }
  }

  List<Widget> _buildPatientMenuItems(BuildContext context, AppStateProvider appState) {
    return [
      _buildMenuItem(
        context,
        icon: Icons.emoji_events,
        title: 'Gamification',
        onTap: () => appState.handleOpenGamificationFromMenu(),
      ),
      _buildMenuItem(
        context,
        icon: Icons.payment,
        title: 'Billing',
        onTap: () => appState.handleOpenBillingFromMenu(),
      ),
      _buildMenuItem(
        context,
        icon: Icons.email,
        title: 'Mail Assistant',
        onTap: () => appState.handleOpenMailAssistantFromMenu(),
      ),
    ];
  }

  List<Widget> _buildCaregiverMenuItems(BuildContext context, AppStateProvider appState) {
    return [
      _buildMenuItem(
        context,
        icon: Icons.access_time,
        title: 'EVV',
        onTap: () => appState.handleOpenEVVFromMenu(),
      ),
      _buildMenuItem(
        context,
        icon: Icons.note_add,
        title: 'Visit Notetaker',
        onTap: () => appState.handleOpenVisitNotetakerFromMenu(),
      ),
      _buildMenuItem(
        context,
        icon: Icons.record_voice_over,
        title: 'ASL Converter',
        onTap: () => appState.handleOpenASLConverterFromMenu(),
      ),
      _buildMenuItem(
        context,
        icon: Icons.video_call,
        title: 'ASL Telemedicine',
        onTap: () => appState.handleOpenASLTelemedicineFromMenu(),
      ),
    ];
  }

  List<Widget> _buildSupervisorMenuItems(BuildContext context, AppStateProvider appState) {
    return [
      _buildMenuItem(
        context,
        icon: Icons.security,
        title: 'Role-Based Access',
        onTap: () => appState.handleOpenRoleBasedAccessFromMenu(),
      ),
      _buildMenuItem(
        context,
        icon: Icons.receipt,
        title: 'Invoice Capture',
        onTap: () => appState.handleOpenInvoiceCaptureFromMenu(),
      ),
      _buildMenuItem(
        context,
        icon: Icons.search,
        title: 'Invoice Search',
        onTap: () => appState.handleOpenInvoiceSearchFromMenu(),
      ),
    ];
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        _toggleMenu();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CareConnectTheme.spacingM,
          vertical: CareConnectTheme.spacingS,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: CareConnectTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: CareConnectTheme.spacingM),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CareConnectTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}