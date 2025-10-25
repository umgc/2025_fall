import 'package:care_connect_app/core/services/api_service.dart';
import 'package:care_connect_app/widgets/email_verification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegistrationPage extends StatefulWidget {
  /// Optional: preselect an initial role (e.g., 'Patient' or 'Caregiver')
  final String? initialRole;

  /// When true, the role selector is disabled and remains fixed to [initialRole]
  final bool lockRole;

  /// When true, skip the email verification dialog and just close the modal
  final bool skipEmailVerification;

  const RegistrationPage({
    super.key,
    this.initialRole,
    this.lockRole = false,
    this.skipEmailVerification = false,
  });

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  int _currentStep = 0;
  String? _selectedRole;
  final _formKey = GlobalKey<FormState>();

  // Form controllers for Patient registration
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _addressPhoneController = TextEditingController();

  // Additional controllers for Caregiver registration
  final _licenseNumberController = TextEditingController();
  final _issuingStateController = TextEditingController();
  final _yearsExperienceController = TextEditingController();

  String? _selectedGender;
  String? _selectedCaregiverType;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    // If an initial role is provided, preselect it
    if (widget.initialRole != null) {
      _selectedRole = widget.initialRole;
    }

    // Add listeners to form fields to update button state dynamically
    _firstNameController.addListener(_updateButtonState);
    _lastNameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
    _dobController.addListener(_updateButtonState);
    _addressLine1Controller.addListener(_updateButtonState);
    _cityController.addListener(_updateButtonState);
    _stateController.addListener(_updateButtonState);
    _zipController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _licenseNumberController.addListener(_updateButtonState);
    _issuingStateController.addListener(_updateButtonState);
    _yearsExperienceController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild and update the button state
    });
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _firstNameController.removeListener(_updateButtonState);
    _lastNameController.removeListener(_updateButtonState);
    _emailController.removeListener(_updateButtonState);
    _phoneController.removeListener(_updateButtonState);
    _dobController.removeListener(_updateButtonState);
    _addressLine1Controller.removeListener(_updateButtonState);
    _cityController.removeListener(_updateButtonState);
    _stateController.removeListener(_updateButtonState);
    _zipController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _confirmPasswordController.removeListener(_updateButtonState);
    _licenseNumberController.removeListener(_updateButtonState);
    _issuingStateController.removeListener(_updateButtonState);
    _yearsExperienceController.removeListener(_updateButtonState);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _addressPhoneController.dispose();
    _licenseNumberController.dispose();
    _issuingStateController.dispose();
    _yearsExperienceController.dispose();
    super.dispose();
  }

  // Role definitions
  final Map<String, Map<String, dynamic>> _roles = {
    'Patient': {
      'icon': Icons.person,
      'subtitle': 'Managing my own health',
      'description':
          'As a patient, you\'ll have access to track your health, communicate with caregivers, manage medications, and monitor symptoms.',
      'totalSteps': 5,
    },
    'Caregiver': {
      'icon': Icons.favorite,
      'subtitle': 'Caring for someone else',
      'description':
          'As a caregiver, you\'ll be able to monitor and assist with healthcare management for your loved ones, coordinate care, and communicate with healthcare providers.',
      'totalSteps': 5,
    },
  };

  int get _totalSteps =>
      _selectedRole != null ? _roles[_selectedRole]!['totalSteps'] : 5;

  double get _progress => (_currentStep + 1) / _totalSteps;

  int get _progressPercentage =>
      ((_currentStep + 1) / _totalSteps * 100).round();

  bool get _isLastStep => _currentStep == _totalSteps - 1;

  void _nextStep() {
    // Validate current step before proceeding
    if (_currentStep == 1 && _formKey.currentState != null) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedRole != null;
      case 1:
        return _validatePersonalInformation();
      case 2:
        return _validateContactInformation();
      case 3:
        return _validateSecurity();
      case 4:
        return true;
      default:
        return false;
    }
  }

  bool _validatePersonalInformation() {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _dobController.text.isNotEmpty &&
        _selectedGender != null &&
        (_selectedRole != 'Caregiver' || _selectedCaregiverType != null);
  }

  bool _validateContactInformation() {
    final emailValid =
        _emailController.text.isNotEmpty &&
        RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text);
    final addressValid =
        _addressLine1Controller.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _stateController.text.isNotEmpty &&
        _zipController.text.isNotEmpty;
    final professionalValid =
        _selectedRole != 'Caregiver' ||
        _selectedCaregiverType != 'Professional' ||
        (_licenseNumberController.text.isNotEmpty &&
            _issuingStateController.text.isNotEmpty &&
            _yearsExperienceController.text.isNotEmpty);

    return emailValid &&
        _phoneController.text.isNotEmpty &&
        addressValid &&
        professionalValid;
  }

  bool _validateSecurity() {
    return _passwordController.text.isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _confirmPasswordController.text == _passwordController.text;
  }

  Future<void> _submitRegistration() async {
    try {
      if (_selectedRole == 'Patient') {
        await _submitPatientRegistration();
      } else if (_selectedRole == 'Caregiver') {
        await _submitCaregiverRegistration();
      }

      if (!mounted) return;

      // If skipEmailVerification is true, just close the modal and return true
      if (widget.skipEmailVerification) {
        Navigator.of(context).pop(true);
        return;
      }

      // Show email verification dialog and wait for result
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            EmailVerificationDialog(email: _emailController.text),
      );

      // If email was verified, navigate to login screen
      if (verified == true && mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _submitPatientRegistration() async {
    // For now, use the basic auth registration endpoint
    // In the future, this should be a dedicated patient registration endpoint
    final registrationData = {
      'name': '${_firstNameController.text} ${_lastNameController.text}',
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': 'PATIENT',
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phone': _phoneController.text,
      'dob': _dobController.text,
      'gender': _selectedGender?.toUpperCase(),
      'address': {
        'line1': _addressLine1Controller.text,
        'line2': _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip': _zipController.text,
        'phone': _addressPhoneController.text,
      },
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.auth}/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
        'Origin': 'http://localhost:50030', // TODO - update this to use .env
        'Referer': 'http://localhost:50030/', // TODO - update to use .env
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-site',
      },
      body: json.encode(registrationData),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        debugPrint('✅ Patient registration successful: ${response.body}');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '❌ Patient registration failed: ${response.statusCode} - ${response.body}',
        );
      }
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> _submitCaregiverRegistration() async {
    const baseUrl = 'http://localhost:8080/v1/api';

    final caregiverData = {
      'name': '${_firstNameController.text} ${_lastNameController.text}',
      'email': _emailController.text,
      'password': _passwordController.text,
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phone': _phoneController.text,
      'dob': _dobController.text,
      'role': "CAREGIVER",
      'gender': _selectedGender?.toUpperCase(),
      'caregiverType': _selectedCaregiverType,
      'address': {
        'line1': _addressLine1Controller.text,
        'line2': _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip': _zipController.text,
        'phone': _addressPhoneController.text,
      },
      'credentials': {
        'email': _emailController.text,
        'password': _passwordController.text,
      },
    };

    // Add professional info if it's a professional caregiver
    if (_selectedCaregiverType == 'Professional') {
      caregiverData['professional'] = {
        'licenseNumber': _licenseNumberController.text,
        'issuingState': _issuingStateController.text,
        'yearsExperience': int.tryParse(_yearsExperienceController.text) ?? 0,
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
        'Origin': 'http://localhost:50030', // TODO - update to use .env
        'Referer': 'http://localhost:50030/', // TODO - update to use .env
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-site',
      },
      body: json.encode(caregiverData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (kDebugMode) {
        debugPrint('✅ Caregiver registration successful: ${response.body}');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '❌ Caregiver registration failed: ${response.statusCode} - ${response.body}',
        );
      }
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAccountRoleStep();
      case 1:
        return _buildPersonalInformationStep();
      case 2:
        return _buildContactInformationStep();
      case 3:
        return _buildSecurityStep();
      case 4:
        return _buildReviewStep();
      default:
        return _buildAccountRoleStep();
    }
  }

  Widget _buildAccountRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who is this account for?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Choose the role that best describes your relationship to healthcare management',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),

        const SizedBox(height: 32),

        const Text(
          'Account Role *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              hint: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Text(
                  'Select account role',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
              isExpanded: true,
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ),
              items: _roles.keys.map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          _roles[role]!['icon'],
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              role,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '(${_roles[role]!['subtitle']})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: widget.lockRole
                  ? null
                  : (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                        // Reset to step 0 when role changes to recalculate total steps
                        _currentStep = 0;
                      });
                    },
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (_selectedRole != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _roles[_selectedRole]!['description'],
              style: const TextStyle(fontSize: 14, color: AppTheme.primary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalInformationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your basic details',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // First Name and Last Name
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _firstNameController,
                  label: 'First Name',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFormField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date of Birth
          _buildDateFormField(
            controller: _dobController,
            label: 'Date of Birth',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Date of birth is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Gender
          _buildDropdownFormField(
            value: _selectedGender,
            label: 'Gender',
            isRequired: true,
            items: ['Male', 'Female', 'Other', 'Prefer not to say'],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Gender is required';
              }
              return null;
            },
          ),

          // Caregiver Type (only for caregivers)
          if (_selectedRole == 'Caregiver') ...[
            const SizedBox(height: 20),
            _buildDropdownFormField(
              value: _selectedCaregiverType,
              label: 'Caregiver Type',
              isRequired: true,
              items: ['Professional', 'Family Member', 'Friend', 'Other'],
              onChanged: (value) {
                setState(() {
                  _selectedCaregiverType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Caregiver type is required';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInformationStep() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your contact details and address',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Email and Phone
          _buildTextFormField(
            controller: _emailController,
            label: 'Email Address',
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildTextFormField(
            controller: _phoneController,
            label: 'Phone Number',
            isRequired: true,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Address Section
          const Text(
            'Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildTextFormField(
            controller: _addressLine1Controller,
            label: 'Address Line 1',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Address line 1 is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildTextFormField(
            controller: _addressLine2Controller,
            label: 'Address Line 2 (Optional)',
            isRequired: false,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextFormField(
                  controller: _cityController,
                  label: 'City',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFormField(
                  controller: _stateController,
                  label: 'State',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFormField(
                  controller: _zipController,
                  label: 'ZIP Code',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ZIP code is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          // Professional Information (only for caregivers)
          if (_selectedRole == 'Caregiver' &&
              _selectedCaregiverType == 'Professional') ...[
            const SizedBox(height: 32),
            const Text(
              'Professional Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextFormField(
              controller: _licenseNumberController,
              label: 'License Number',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'License number is required for professional caregivers';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _issuingStateController,
                    label: 'Issuing State',
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Issuing state is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    controller: _yearsExperienceController,
                    label: 'Years of Experience',
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Years of experience is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Setup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your password to secure your account',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          _buildPasswordFormField(
            controller: _passwordController,
            label: 'Password',
            isRequired: true,
            isVisible: _isPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildPasswordFormField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            isRequired: true,
            isVisible: _isConfirmPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
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
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Password Requirements:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• At least 8 characters long\n• Use a combination of letters, numbers, and symbols\n• Avoid using personal information',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review & Confirm',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review your information before creating your account',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),

        _buildReviewSection('Account Type', _selectedRole ?? ''),
        _buildReviewSection(
          'Name',
          '${_firstNameController.text} ${_lastNameController.text}',
        ),
        _buildReviewSection('Email', _emailController.text),
        _buildReviewSection('Phone', _phoneController.text),
        _buildReviewSection('Date of Birth', _dobController.text),
        _buildReviewSection('Gender', _selectedGender ?? ''),

        if (_selectedRole == 'Caregiver')
          _buildReviewSection('Caregiver Type', _selectedCaregiverType ?? ''),

        _buildReviewSection(
          'Address',
          '${_addressLine1Controller.text}${_addressLine2Controller.text.isNotEmpty ? ', ${_addressLine2Controller.text}' : ''}\n${_cityController.text}, ${_stateController.text} ${_zipController.text}',
        ),

        if (_selectedRole == 'Caregiver' &&
            _selectedCaregiverType == 'Professional') ...[
          _buildReviewSection('License Number', _licenseNumberController.text),
          _buildReviewSection('Issuing State', _issuingStateController.text),
          _buildReviewSection(
            'Years of Experience',
            _yearsExperienceController.text,
          ),
        ],

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF4FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFormField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: const Icon(Icons.calendar_today, size: 20),
            hintText: 'Select date',
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(
                const Duration(days: 365 * 18),
              ),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              controller.text =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          hint: Text('Select $label'),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
              onPressed: onVisibilityToggle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 600,
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo section
                  Container(
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/CareConnectLogo.png',
                          width: isMobile ? 70 : 90,
                          height: isMobile ? 70 : 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if PNG doesn't load
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: isMobile ? 20 : 24,
                                  height: isMobile ? 20 : 24,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: isMobile ? 14 : 16,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 2 : 4),
                                Icon(
                                  Icons.monitor_heart,
                                  color: AppTheme.primary,
                                  size: isMobile ? 16 : 24,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Create Your CareConnect Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Join our secure healthcare platform',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Progress section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Step ${_currentStep + 1} of $_totalSteps',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '$_progressPercentage% Complete',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Progress bar
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Step title
                        Row(
                          children: [
                            Icon(
                              _currentStep == 0
                                  ? Icons.person
                                  : Icons.edit_document,
                              size: 20,
                              color: const Color(0xFF374151),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentStep == 0
                                  ? 'Account Role'
                                  : 'Step ${_currentStep + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main content card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.cardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildStepContent(),
                  ),

                  const SizedBox(height: 32),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: _currentStep > 0
                            ? _previousStep
                            : () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(
                          _currentStep > 0 ? 'Previous' : 'Back to Login',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),

                      // Next/Sign Up button
                      ElevatedButton.icon(
                        onPressed: _canProceed()
                            ? (_isLastStep ? _submitRegistration : _nextStep)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        icon: Icon(
                          _isLastStep ? Icons.check : Icons.arrow_forward,
                          size: 18,
                        ),
                        label: Text(_isLastStep ? 'Sign Up' : 'Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
