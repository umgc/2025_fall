import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme/careconnect_theme.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gamification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppStateProvider>().handleCloseGamification();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CareConnectTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Points and Level
            _buildPointsAndLevel(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Achievements
            _buildAchievements(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Daily Challenges
            _buildDailyChallenges(context),
            
            const SizedBox(height: CareConnectTheme.spacingXL),
            
            // Leaderboard
            _buildLeaderboard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer2<AuthProvider, AppStateProvider>(
      builder: (context, authProvider, appState, child) {
        final isDemoMode = appState.isDemoMode;
        final userRole = authProvider.userMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Gamification' : 'Gamification',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingS),
            Text(
              _getGamificationDescription(userRole),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: CareConnectTheme.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsAndLevel(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(CareConnectTheme.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CareConnectTheme.primaryColor,
                CareConnectTheme.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDemoMode ? 'Demo Level 5' : 'Level 3',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isDemoMode ? 'Demo Caregiver' : 'Healthcare Hero',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CareConnectTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Points',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    isDemoMode ? '2,450' : '1,250',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CareConnectTheme.spacingS),
              LinearProgressIndicator(
                value: isDemoMode ? 0.8 : 0.6,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
              const SizedBox(height: CareConnectTheme.spacingS),
              Text(
                isDemoMode ? '450 points to next level' : '750 points to next level',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievements(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Achievements' : 'Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CareConnectTheme.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isDemoMode) ...[
                    _buildAchievementItem('First Check-in', 'Completed your first daily check-in', Icons.check_circle, true),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildAchievementItem('Week Warrior', 'Completed 7 consecutive check-ins', Icons.calendar_today, true),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildAchievementItem('Medication Master', 'Took medications on time for 30 days', Icons.medication, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildAchievementItem('Communication Champion', 'Sent 50 messages to care team', Icons.message, false),
                  ] else ...[
                    _buildAchievementItem('First Check-in', 'Complete your first daily check-in', Icons.check_circle, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildAchievementItem('Week Warrior', 'Complete 7 consecutive check-ins', Icons.calendar_today, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildAchievementItem('Medication Master', 'Take medications on time for 30 days', Icons.medication, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildAchievementItem('Communication Champion', 'Send 50 messages to care team', Icons.message, false),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, bool isUnlocked) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnlocked 
                ? CareConnectTheme.successColor.withOpacity(0.1)
                : CareConnectTheme.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: isUnlocked 
                ? CareConnectTheme.successColor
                : CareConnectTheme.textSecondary,
            size: 24,
          ),
        ),
        const SizedBox(width: CareConnectTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked 
                      ? CareConnectTheme.textPrimary
                      : CareConnectTheme.textSecondary,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: CareConnectTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isUnlocked)
          const Icon(
            Icons.check_circle,
            color: CareConnectTheme.successColor,
            size: 24,
          ),
      ],
    );
  }

  Widget _buildDailyChallenges(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Daily Challenges' : 'Daily Challenges',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CareConnectTheme.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isDemoMode) ...[
                    _buildChallengeItem('Complete Daily Check-in', '50 points', Icons.check_circle_outline, true),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildChallengeItem('Log Symptoms', '30 points', Icons.health_and_safety_outlined, true),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildChallengeItem('Take Morning Medication', '40 points', Icons.medication_outlined, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildChallengeItem('Send Message to Care Team', '25 points', Icons.message_outlined, false),
                  ] else ...[
                    _buildChallengeItem('Complete Daily Check-in', '50 points', Icons.check_circle_outline, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildChallengeItem('Log Symptoms', '30 points', Icons.health_and_safety_outlined, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildChallengeItem('Take Morning Medication', '40 points', Icons.medication_outlined, false),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildChallengeItem('Send Message to Care Team', '25 points', Icons.message_outlined, false),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChallengeItem(String title, String points, IconData icon, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted 
                ? CareConnectTheme.successColor.withOpacity(0.1)
                : CareConnectTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isCompleted 
                ? CareConnectTheme.successColor
                : CareConnectTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: CareConnectTheme.spacingM),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isCompleted 
                  ? CareConnectTheme.textSecondary
                  : CareConnectTheme.textPrimary,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted 
                ? CareConnectTheme.successColor.withOpacity(0.1)
                : CareConnectTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            points,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCompleted 
                  ? CareConnectTheme.successColor
                  : CareConnectTheme.primaryColor,
            ),
          ),
        ),
        if (isCompleted)
          const SizedBox(width: CareConnectTheme.spacingS),
        if (isCompleted)
          const Icon(
            Icons.check_circle,
            color: CareConnectTheme.successColor,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isDemoMode = appState.isDemoMode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode ? 'Demo Leaderboard' : 'Leaderboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CareConnectTheme.primaryColor,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CareConnectTheme.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isDemoMode) ...[
                    _buildLeaderboardItem(1, 'Sarah Johnson', '3,200 pts', Icons.emoji_events, Colors.amber),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(2, 'Michael Chen', '2,850 pts', Icons.emoji_events, Colors.grey),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(3, 'You', '2,450 pts', Icons.person, CareConnectTheme.primaryColor),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(4, 'Emily Davis', '2,100 pts', null, null),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(5, 'David Wilson', '1,950 pts', null, null),
                  ] else ...[
                    _buildLeaderboardItem(1, 'Top Performer', '2,500 pts', Icons.emoji_events, Colors.amber),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(2, 'Second Place', '2,200 pts', Icons.emoji_events, Colors.grey),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(3, 'You', '1,250 pts', Icons.person, CareConnectTheme.primaryColor),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(4, 'Fourth Place', '1,100 pts', null, null),
                    const SizedBox(height: CareConnectTheme.spacingM),
                    _buildLeaderboardItem(5, 'Fifth Place', '950 pts', null, null),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardItem(int position, String name, String points, IconData? icon, Color? iconColor) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: position <= 3 
                ? CareConnectTheme.primaryColor.withOpacity(0.1)
                : CareConnectTheme.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              position.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: position <= 3 
                    ? CareConnectTheme.primaryColor
                    : CareConnectTheme.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: CareConnectTheme.spacingM),
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: CareConnectTheme.spacingS),
        ],
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: name == 'You' ? FontWeight.w600 : FontWeight.normal,
              color: name == 'You' 
                  ? CareConnectTheme.primaryColor
                  : CareConnectTheme.textPrimary,
            ),
          ),
        ),
        Text(
          points,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CareConnectTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getGamificationDescription(UserMode? userRole) {
    switch (userRole) {
      case UserMode.patient:
        return 'Earn points and achievements by taking care of your health!';
      case UserMode.caregiver:
        return 'Track your caregiving progress and compete with other caregivers!';
      case UserMode.supervisor:
        return 'Monitor team performance and celebrate achievements!';
      default:
        return 'Make healthcare fun with points, achievements, and challenges!';
    }
  }
}
