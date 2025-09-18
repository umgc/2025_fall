import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/careconnect_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: CareConnectTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppStateProvider>().handleCloseSettings();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CareConnectTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo Mode Section
            _buildSectionHeader(context, 'Demo Mode'),
            const SizedBox(height: CareConnectTheme.spacingM),
            _buildDemoModeToggle(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Account Section
            _buildSectionHeader(context, 'Account'),
            const SizedBox(height: CareConnectTheme.spacingM),
            _buildAccountInfo(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // App Info Section
            _buildSectionHeader(context, 'App Information'),
            const SizedBox(height: CareConnectTheme.spacingM),
            _buildAppInfo(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Splash Screen Button
            _buildSplashScreenButton(context),
            
            const SizedBox(height: CareConnectTheme.spacingM),
            
            // Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: CareConnectTheme.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDemoModeToggle(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Card(
          child: SwitchListTile(
            title: const Text('Demo Mode'),
            subtitle: Text(
              appState.isDemoMode 
                ? 'Showing sample data for demonstration'
                : 'Use real data from your account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CareConnectTheme.textSecondary,
              ),
            ),
            value: appState.isDemoMode,
            onChanged: (value) {
              appState.setDemoMode(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value 
                      ? 'Demo mode enabled - showing sample data'
                      : 'Demo mode disabled - using real data',
                  ),
                  backgroundColor: value ? CareConnectTheme.successColor : CareConnectTheme.primaryColor,
                ),
              );
            },
            activeColor: CareConnectTheme.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildAccountInfo(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(CareConnectTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                _buildInfoRow('Name', authProvider.getDisplayName()),
                const SizedBox(height: CareConnectTheme.spacingS),
                _buildInfoRow('Email', authProvider.userEmail ?? 'demo@example.com'),
                const SizedBox(height: CareConnectTheme.spacingS),
                _buildInfoRow('Role', _getRoleDisplayName(authProvider.userMode)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: CareConnectTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(UserMode? userMode) {
    switch (userMode) {
      case UserMode.patient:
        return 'Patient';
      case UserMode.caregiver:
        return 'Caregiver';
      case UserMode.supervisor:
        return 'Supervisor';
      default:
        return 'Unknown';
    }
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CareConnectTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CareConnect Healthcare App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            _buildInfoRow('Version', '1.0.0'),
            const SizedBox(height: CareConnectTheme.spacingS),
            _buildInfoRow('Build', 'Demo Build'),
            const SizedBox(height: CareConnectTheme.spacingS),
            _buildInfoRow('Platform', 'Flutter'),
          ],
        ),
      ),
    );
  }

  Widget _buildSplashScreenButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<AppStateProvider>().reset();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: CareConnectTheme.spacingM),
        ),
        child: const Text('Reset to Splash Screen'),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showLogoutDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.errorColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: CareConnectTheme.spacingM),
        ),
        child: const Text('Logout'),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
                context.read<AppStateProvider>().reset();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
