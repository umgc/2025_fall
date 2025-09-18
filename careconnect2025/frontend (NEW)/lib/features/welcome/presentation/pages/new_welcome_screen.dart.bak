import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/user_provider.dart';
import '../../../../config/theme/careconnect_theme.dart';
import '../../../../widgets/careconnect_logo.dart';
import '../../../../widgets/careconnect_button.dart';

class NewWelcomeScreen extends StatefulWidget {
  const NewWelcomeScreen({super.key});

  @override
  State<NewWelcomeScreen> createState() => _NewWelcomeScreenState();
}

class _NewWelcomeScreenState extends State<NewWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _logoController;
  late AnimationController _featureController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _featureAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _featureController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _featureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _featureController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimation() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _featureController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const Spacer(),
                      
                      // Welcome content
                      _buildWelcomeContent(),
                      
                      const Spacer(),
                      
                      // Continue button
                      _buildContinueButton(),
                      
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.primaryColor.withValues(alpha:0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: CareConnectLogo(
              width: 68,
              height: 68,
              useSVG: false,
            ),
          ),
        ),
        
        const SizedBox(height: 32.0),
        
        // Welcome title
        Text(
          'Welcome to CareConnect',
          style: CareConnectTheme.heading1,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16.0),
        
        // Welcome description
        Text(
          'Your comprehensive healthcare management platform. Connect with your care team, track your health, and manage your medical needs all in one place.',
          style: CareConnectTheme.bodyLarge.copyWith(
            color: CareConnectTheme.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32.0),
        
        // Features list
        _buildFeaturesList(),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.person,
        'title': 'Personalized Care',
        'description': 'Tailored healthcare experience for your needs',
      },
      {
        'icon': Icons.schedule,
        'title': 'Easy Scheduling',
        'description': 'Book appointments and manage your calendar',
      },
      {
        'icon': Icons.health_and_safety,
        'title': 'Health Tracking',
        'description': 'Monitor symptoms, medications, and progress',
      },
      {
        'icon': Icons.message,
        'title': 'Secure Communication',
        'description': 'Connect with your care team safely',
      },
    ];

    return Column(
      children: features.map((feature) => _buildFeatureItem(
        icon: feature['icon'] as IconData,
        title: feature['title'] as String,
        description: feature['description'] as String,
      )).toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CareConnectTheme.primaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: CareConnectTheme.primaryColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16.0),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CareConnectTheme.heading4,
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: CareConnectTheme.bodyMedium.copyWith(
                    color: CareConnectTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return CareConnectButton(
      text: 'Get Started',
      onPressed: () {
        context.go('/auth/login');
      },
      type: CareConnectButtonType.primary,
      isFullWidth: true,
    );
  }
}
