import 'package:flutter/material.dart';
import '../widgets/careconnect_logo.dart';
import '../widgets/careconnect_card.dart';
import '../widgets/careconnect_button.dart';
import '../widgets/careconnect_input.dart';
import '../config/theme/careconnect_theme.dart';

/// Demo page showcasing the new CareConnect design components
/// This page demonstrates the new theme and UI components
class DesignShowcasePage extends StatefulWidget {
  const DesignShowcasePage({super.key});

  @override
  State<DesignShowcasePage> createState() => _DesignShowcasePageState();
}

class _DesignShowcasePageState extends State<DesignShowcasePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareConnect Design Showcase'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // Toggle theme - this would be handled by ThemeProvider in real app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme toggle would be implemented here')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CareConnectTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            _buildSection(
              'Logo & Branding',
              [
                const CareConnectLogo(
                  width: 200,
                  height: 60,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectLogoIcon(
                  size: 48,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectLogo(
                  width: 100,
                  height: 30,
                  useSVG: true,
                ),
              ],
            ),

            const SizedBox(height: CareConnectTheme.spacingXL),

            // Color Palette Section
            _buildSection(
              'Color Palette',
              [
                _buildColorSwatch('Primary', CareConnectTheme.primaryColor),
                _buildColorSwatch('Secondary', CareConnectTheme.secondaryColor),
                _buildColorSwatch('Success', CareConnectTheme.successColor),
                _buildColorSwatch('Warning', CareConnectTheme.warningColor),
                _buildColorSwatch('Error', CareConnectTheme.errorColor),
              ],
            ),

            const SizedBox(height: CareConnectTheme.spacingXL),

            // Typography Section
            _buildSection(
              'Typography',
              [
                const Text('Heading 1', style: CareConnectTheme.heading1),
                const Text('Heading 2', style: CareConnectTheme.heading2),
                const Text('Heading 3', style: CareConnectTheme.heading3),
                const Text('Heading 4', style: CareConnectTheme.heading4),
                const Text('Body Large', style: CareConnectTheme.bodyLarge),
                const Text('Body Medium', style: CareConnectTheme.bodyMedium),
                const Text('Body Small', style: CareConnectTheme.bodySmall),
                const Text('Caption', style: CareConnectTheme.caption),
              ],
            ),

            const SizedBox(height: CareConnectTheme.spacingXL),

            // Buttons Section
            _buildSection(
              'Buttons',
              [
                const CareConnectButton(
                  text: 'Primary Button',
                  type: CareConnectButtonType.primary,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Secondary Button',
                  type: CareConnectButtonType.secondary,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Outline Button',
                  type: CareConnectButtonType.outline,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Text Button',
                  type: CareConnectButtonType.text,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Success Button',
                  type: CareConnectButtonType.success,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Warning Button',
                  type: CareConnectButtonType.warning,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Error Button',
                  type: CareConnectButtonType.error,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                CareConnectButton(
                  text: 'Loading Button',
                  isLoading: _isLoading,
                  onPressed: () {
                    setState(() {
                      _isLoading = !_isLoading;
                    });
                  },
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Button with Icon',
                  icon: Icons.add,
                  type: CareConnectButtonType.primary,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectButton(
                  text: 'Full Width Button',
                  isFullWidth: true,
                  type: CareConnectButtonType.primary,
                ),
              ],
            ),

            const SizedBox(height: CareConnectTheme.spacingXL),

            // Input Fields Section
            _buildSection(
              'Input Fields',
              [
                CareConnectSearchInput(
                  controller: _searchController,
                  hint: 'Search patients...',
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                CareConnectInput(
                  label: 'Email Address',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                CareConnectInput(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectInput(
                  label: 'Disabled Input',
                  hint: 'This input is disabled',
                  enabled: false,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                const CareConnectInput(
                  label: 'Input with Error',
                  hint: 'This input has an error',
                  errorText: 'This field is required',
                ),
              ],
            ),

            const SizedBox(height: CareConnectTheme.spacingXL),

            // Cards Section
            _buildSection(
              'Cards',
              [
                CareConnectCard(
                  child: const Text(
                    'Basic Card\nThis is a simple card with default styling.',
                    style: CareConnectTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                CareConnectCard(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card tapped!')),
                    );
                  },
                  child: const Text(
                    'Tappable Card\nTap this card to see the interaction.',
                    style: CareConnectTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                HealthMetricCard(
                  title: 'Blood Pressure',
                  value: '120/80',
                  subtitle: 'Normal',
                  icon: Icons.favorite,
                  iconColor: CareConnectTheme.successColor,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                HealthMetricCard(
                  title: 'Heart Rate',
                  value: '72 bpm',
                  subtitle: 'Normal',
                  icon: Icons.monitor_heart,
                  iconColor: CareConnectTheme.primaryColor,
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                QuickActionCard(
                  title: 'Check-in',
                  icon: Icons.check_circle_outline,
                  iconColor: CareConnectTheme.successColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Check-in action tapped!')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: CareConnectTheme.spacingXL),

            // Spacing Section
            _buildSection(
              'Spacing & Layout',
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(CareConnectTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: CareConnectTheme.primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(CareConnectTheme.radiusS),
                  ),
                  child: const Text('XS Spacing (4px)', style: CareConnectTheme.bodySmall),
                ),
                const SizedBox(height: CareConnectTheme.spacingS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(CareConnectTheme.spacingS),
                  decoration: BoxDecoration(
                    color: CareConnectTheme.primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(CareConnectTheme.radiusS),
                  ),
                  child: const Text('S Spacing (8px)', style: CareConnectTheme.bodySmall),
                ),
                const SizedBox(height: CareConnectTheme.spacingM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(CareConnectTheme.spacingM),
                  decoration: BoxDecoration(
                    color: CareConnectTheme.primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
                  ),
                  child: const Text('M Spacing (16px)', style: CareConnectTheme.bodySmall),
                ),
                const SizedBox(height: CareConnectTheme.spacingL),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(CareConnectTheme.spacingL),
                  decoration: BoxDecoration(
                    color: CareConnectTheme.primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(CareConnectTheme.radiusL),
                  ),
                  child: const Text('L Spacing (24px)', style: CareConnectTheme.bodySmall),
                ),
              ],
            ),

            const SizedBox(height: CareConnectTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CareConnectTheme.heading3,
        ),
        const SizedBox(height: CareConnectTheme.spacingM),
        ...children,
      ],
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CareConnectTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(CareConnectTheme.radiusS),
              border: Border.all(
                color: CareConnectTheme.borderColor,
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: CareConnectTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: CareConnectTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: CareConnectTheme.bodySmall.copyWith(
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
}
