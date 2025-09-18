import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/careconnect_logo.dart';
import '../widgets/careconnect_card.dart';
import '../widgets/careconnect_button.dart';
import '../widgets/careconnect_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Forgot password states
  bool _showForgotPassword = false;
  final _resetEmailController = TextEditingController();
  bool _isResetLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _slideController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      // For demo purposes, we'll simulate login
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate successful login
      if (_usernameController.text.trim().isNotEmpty && 
          _passwordController.text.isNotEmpty) {
        
        // Create a demo user session based on the username
        String username = _usernameController.text.trim().toLowerCase();
        
        // Check if it's a demo account
        if (username.contains('demo')) {
          authProvider.loginAsPatient(name: 'Demo Patient', email: 'patient@demo.com');
        } else if (username.contains('caregiver')) {
          authProvider.loginAsCaregiver(name: 'Demo Caregiver', email: 'caregiver@demo.com');
        } else if (username.contains('supervisor')) {
          authProvider.loginAsSupervisor(name: 'Demo Supervisor', email: 'supervisor@demo.com');
        } else {
          // Default to patient
          authProvider.loginAsPatient(name: 'Demo Patient', email: 'patient@demo.com');
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_resetEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: CareConnectTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isResetLoading = true;
    });

    try {
      // Simulate password reset
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: CareConnectTheme.successColor,
        ),
      );
      setState(() {
        _showForgotPassword = false;
        _resetEmailController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: CareConnectTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isResetLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CareConnectTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: CareConnectTheme.spacingXL),

              // Logo and title with animation
              ScaleTransition(
                scale: _logoAnimation,
                child: _buildHeader(),
              ),

              const SizedBox(height: CareConnectTheme.spacingXXL),

              // Login form with animations
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginForm(),
                ),
              ),

              const SizedBox(height: CareConnectTheme.spacingL),

              // Create account link with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCreateAccountLink(),
              ),

              const SizedBox(height: CareConnectTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.primaryColor.withValues(alpha:0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: CareConnectLogo(
              width: 56,
              height: 56,
              useSVG: false,
            ),
          ),
        ),

        const SizedBox(height: CareConnectTheme.spacingL),

        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: CareConnectTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: CareConnectTheme.spacingS),

        Text(
          'Sign in to your CareConnect account',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: CareConnectTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Error message
          if (_errorMessage != null) ...[
            CareConnectCard(
              backgroundColor: CareConnectTheme.errorColor.withValues(alpha:0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: CareConnectTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: CareConnectTheme.spacingS),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: CareConnectTheme.errorColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingM),
          ],

          // Username field
          CareConnectInput(
            label: 'Username or Email',
            hint: 'Enter your username or email',
            controller: _usernameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your username or email';
              }
              return null;
            },
          ),

          const SizedBox(height: CareConnectTheme.spacingL),

          // Password field
          CareConnectInput(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),

          const SizedBox(height: CareConnectTheme.spacingM),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showForgotPassword = true;
                });
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: CareConnectTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: CareConnectTheme.spacingXL),

          // Login button
          CareConnectButton(
            text: 'Sign In',
            onPressed: _handleLogin,
            isLoading: _isLoading,
            isFullWidth: true,
          ),

          const SizedBox(height: CareConnectTheme.spacingL),

          // Demo accounts info
          CareConnectCard(
            backgroundColor: CareConnectTheme.primaryColor.withValues(alpha:0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Demo Accounts:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CareConnectTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: CareConnectTheme.spacingS),
                const Text(
                  '• Patient: demo / password\n• Caregiver: caregiver / password\n• Supervisor: supervisor / password',
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: CareConnectTheme.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<AppStateProvider>().showCreateAccount();
          },
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: CareConnectTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
