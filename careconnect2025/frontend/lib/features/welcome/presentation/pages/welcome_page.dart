import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Show spinner for 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A5FBF), // Blue gradient top
              Color(0xFF3B4DBF), // Blue gradient bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 48,
              vertical: isMobile ? 32 : 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo container with SVG
                Container(
                  width: isMobile ? 100 : 200,
                  height: isMobile ? 100 : 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/CareConnectLogo.png',
                          width: isMobile ? 90 : 190,
                          fit: BoxFit.contain,
                          color: Colors.white, // Optional: to tint the image white
                          colorBlendMode: BlendMode.srcIn, // Optional: for white tinting
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isMobile ? 40 : 48),

                // Main title
                Text(
                  'CareConnect',
                  style: TextStyle(
                    fontSize: isMobile ? 36 : 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isMobile ? 12 : 16),

                // Subtitle
                Text(
                  'Connecting Care, Empowering Health',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isMobile ? 32 : 40),

                // Description text
                Text(
                  'Your healthcare companion for',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isMobile ? 8 : 12),

                Text(
                  'Better Care • Better Outcomes • Better Life',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isMobile ? 40 : 48),

                // Loading state or ready message
                if (_isLoading) ...[
                  Text(
                    'Initializing your healthcare experience...',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Ready to connect your care!',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 24 : 32),

                  // Continue button
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the original welcome page or next screen
                      context.go('/dashboard'); // Update this route as needed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A5FBF),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 32 : 40,
                        vertical: isMobile ? 16 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Compliance badges at bottom
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      _buildComplianceBadge('🔒 HIPAA Compliant', isMobile),
                      _buildComplianceBadge('♿ WCAG AA', isMobile),
                      _buildComplianceBadge('🛡️ Secure', isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceBadge(String text, bool isMobile) {
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 6 : 8,
          vertical: isMobile ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
