import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/user_provider.dart';
import '../../../../config/theme/careconnect_theme.dart';
import '../../../../widgets/careconnect_logo.dart';
import '../../../../widgets/careconnect_button.dart';
import '../../../../widgets/careconnect_input.dart';
import '../../../../widgets/careconnect_card.dart';

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen> 
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
      final userProvider = context.read<UserProvider>();
      
      // For demo purposes, we'll simulate login
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate successful login
      if (_usernameController.text.trim().isNotEmpty && 
          _passwordController.text.isNotEmpty) {
        
        // Create a demo user session based on the username
        String role = 'PATIENT'; // Default role
        String name = 'Demo User';
        
        // Check if it's a demo account
        if (_usernameController.text.trim().toLowerCase().contains('demo')) {
          role = 'PATIENT';
          name = 'Demo Patient';
        } else if (_usernameController.text.trim().toLowerCase().contains('caregiver')) {
          role = 'CAREGIVER';
          name = 'Demo Caregiver';
        } else if (_usernameController.text.trim().toLowerCase().contains('supervisor')) {
          role = 'CAREGIVER'; // Supervisor is also a caregiver role
          name = 'Demo Supervisor';
        }
        
        // Create user session
        final userSession = UserSession(
          id: 1,
          email: _usernameController.text.trim(),
          role: role,
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
        );
        
        // Set user in provider
        userProvider.setUser(userSession);
        
        // Navigate to dashboard
        if (mounted) {
          context.go('/dashboard');
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your email address'),
            backgroundColor: CareConnectTheme.errorColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _isResetLoading = true;
    });

    try {
      // Simulate password reset
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: CareConnectTheme.successColor,
          ),
        );
      }
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32.0),
              
              // Logo and title with animation
              ScaleTransition(
                scale: _logoAnimation,
                child: _buildHeader(),
              ),
              
              const SizedBox(height: 48.0),
              
              // Login form with animations
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginForm(),
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Create account link with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCreateAccountLink(),
              ),
              
              const SizedBox(height: 32.0),
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
                color: CareConnectTheme.primaryColor.withValues(alpha: 0.3),
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
        
        const SizedBox(height: 24.0),
        
        Text(
          'Welcome Back',
          style: CareConnectTheme.heading1,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8.0),
        
        Text(
          'Sign in to your CareConnect account',
          style: CareConnectTheme.bodyLarge.copyWith(
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
            backgroundColor: CareConnectTheme.errorColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: CareConnectTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: CareConnectTheme.bodyMedium.copyWith(
                        color: CareConnectTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
          ],

          // Demo accounts hint
          CareConnectCard(
            backgroundColor: CareConnectTheme.primaryColor.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: CareConnectTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      'Demo Accounts Available',
                      style: CareConnectTheme.bodyMedium.copyWith(
                        color: CareConnectTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                
                // Patient Demo Account
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: CareConnectTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: CareConnectTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Patient Demo',
                            style: CareConnectTheme.bodySmall.copyWith(
                              color: CareConnectTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Email: demo@careconnect\nPassword: demo123',
                        style: CareConnectTheme.bodySmall.copyWith(
                          color: CareConnectTheme.primaryColor,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8.0),
                
                // Caregiver Demo Account
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: CareConnectTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.health_and_safety,
                            color: CareConnectTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Caregiver Demo',
                            style: CareConnectTheme.bodySmall.copyWith(
                              color: CareConnectTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Email: test@caregiver\nPassword: 1234',
                        style: CareConnectTheme.bodySmall.copyWith(
                          color: CareConnectTheme.primaryColor,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8.0),
                
                // Supervisor Demo Account
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: CareConnectTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.supervisor_account,
                            color: CareConnectTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Supervisor Demo',
                            style: CareConnectTheme.bodySmall.copyWith(
                              color: CareConnectTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Email: test@supervisor\nPassword: 1234',
                        style: CareConnectTheme.bodySmall.copyWith(
                          color: CareConnectTheme.primaryColor,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24.0),
          
          // Username field
          CareConnectInput(
            controller: _usernameController,
            label: 'Username or Email',
            hint: 'Enter your username or email',
            prefixIcon: const Icon(Icons.person_outline),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your username or email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16.0),
          
          // Password field
          CareConnectInput(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: _obscurePassword,
            onSubmitted: (_) => _handleLogin(),
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
          
          const SizedBox(height: 8.0),
          
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showForgotPassword = true;
                });
              },
              child: const Text('Forgot Password?'),
            ),
          ),
          
          const SizedBox(height: 24.0),
          
          // Login button
          CareConnectButton(
            text: 'Sign In',
            onPressed: _isLoading ? null : _handleLogin,
            type: CareConnectButtonType.primary,
            isFullWidth: true,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: CareConnectTheme.bodyMedium.copyWith(
            color: CareConnectTheme.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.go('/auth/signup');
          },
          child: const Text('Create Account'),
        ),
      ],
    );
  }

  // Forgot password dialog
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16.0),
            CareConnectInput(
              controller: _resetEmailController,
              label: 'Email Address',
              hint: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _handleForgotPassword(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showForgotPassword = false;
                _resetEmailController.clear();
              });
            },
            child: const Text('Cancel'),
          ),
          CareConnectButton(
            text: 'Send Reset Link',
            onPressed: _isResetLoading ? null : _handleForgotPassword,
            type: CareConnectButtonType.primary,
            isLoading: _isResetLoading,
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showForgotPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showForgotPasswordDialog();
      });
    }
  }
}
