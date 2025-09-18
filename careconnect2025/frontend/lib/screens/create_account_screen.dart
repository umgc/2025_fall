import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/careconnect_theme.dart';
import '../widgets/careconnect_logo.dart';
import '../widgets/careconnect_card.dart';
import '../widgets/careconnect_button.dart';
import '../widgets/careconnect_input.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserMode _selectedUserType = UserMode.patient;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      // For demo purposes, we'll simulate account creation
      await Future.delayed(const Duration(seconds: 1));
      
      // Create account based on selected user type
      switch (_selectedUserType) {
        case UserMode.patient:
          authProvider.loginAsPatient(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
          break;
        case UserMode.caregiver:
          authProvider.loginAsCaregiver(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
          break;
        case UserMode.supervisor:
          authProvider.loginAsSupervisor(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
          break;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareConnectTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: CareConnectTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppStateProvider>().hideCreateAccount();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CareConnectTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: CareConnectTheme.spacingL),

              // Logo and title with animation
              ScaleTransition(
                scale: _logoAnimation,
                child: _buildHeader(),
              ),

              const SizedBox(height: CareConnectTheme.spacingXL),

              // Create account form with animations
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildCreateAccountForm(),
                ),
              ),

              const SizedBox(height: CareConnectTheme.spacingL),

              // Login link with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildLoginLink(),
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
          'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: CareConnectTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: CareConnectTheme.spacingS),

        Text(
          'Join CareConnect and start managing your health',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: CareConnectTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCreateAccountForm() {
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

          // User type selection
          _buildUserTypeSelection(),

          const SizedBox(height: CareConnectTheme.spacingL),

          // Name field
          CareConnectInput(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),

          const SizedBox(height: CareConnectTheme.spacingL),

          // Email field
          CareConnectInput(
            label: 'Email',
            hint: 'Enter your email address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
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
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: CareConnectTheme.spacingL),

          // Confirm password field
          CareConnectInput(
            label: 'Confirm Password',
            hint: 'Confirm your password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: CareConnectTheme.spacingXL),

          // Create account button
          CareConnectButton(
            text: 'Create Account',
            onPressed: _handleCreateAccount,
            isLoading: _isLoading,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return CareConnectCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildUserTypeOption(
                  UserMode.patient,
                  'Patient',
                  Icons.person,
                  'Track your health and connect with caregivers',
                ),
              ),
              const SizedBox(width: CareConnectTheme.spacingM),
              Expanded(
                child: _buildUserTypeOption(
                  UserMode.caregiver,
                  'Caregiver',
                  Icons.health_and_safety,
                  'Care for patients and manage schedules',
                ),
              ),
            ],
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          _buildUserTypeOption(
            UserMode.supervisor,
            'Supervisor',
            Icons.supervisor_account,
            'Oversee caregivers and manage operations',
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption(UserMode userType, String title, IconData icon, String description) {
    final isSelected = _selectedUserType == userType;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserType = userType;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(CareConnectTheme.spacingM),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? CareConnectTheme.primaryColor : CareConnectTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? CareConnectTheme.primaryColor.withValues(alpha:0.05) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? CareConnectTheme.primaryColor : CareConnectTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: CareConnectTheme.spacingS),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? CareConnectTheme.primaryColor : CareConnectTheme.textPrimary,
              ),
            ),
            const SizedBox(height: CareConnectTheme.spacingXS),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: CareConnectTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            color: CareConnectTheme.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<AppStateProvider>().hideCreateAccount();
          },
          child: const Text(
            'Sign In',
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
