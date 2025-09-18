import 'package:flutter/material.dart';
import '../config/theme/careconnect_theme.dart';

/// Enhanced CareConnect button with modern styling
class CareConnectButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CareConnectButtonType type;
  final CareConnectButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const CareConnectButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CareConnectButtonType.primary,
    this.size = CareConnectButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget buttonChild = _buildButtonChild(context, isDark);
    
    switch (type) {
      case CareConnectButtonType.primary:
        return _buildPrimaryButton(context, buttonChild, isDark);
      case CareConnectButtonType.secondary:
        return _buildSecondaryButton(context, buttonChild, isDark);
      case CareConnectButtonType.outline:
        return _buildOutlineButton(context, buttonChild, isDark);
      case CareConnectButtonType.text:
        return _buildTextButton(context, buttonChild, isDark);
      case CareConnectButtonType.success:
        return _buildSuccessButton(context, buttonChild, isDark);
      case CareConnectButtonType.warning:
        return _buildWarningButton(context, buttonChild, isDark);
      case CareConnectButtonType.error:
        return _buildErrorButton(context, buttonChild, isDark);
    }
  }

  Widget _buildButtonChild(BuildContext context, bool isDark) {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getTextColor(context, isDark),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: CareConnectTheme.spacingS),
          Text(text, style: _getTextStyle(context, isDark)),
        ],
      );
    }

    return Text(text, style: _getTextStyle(context, isDark));
  }

  Widget _buildPrimaryButton(BuildContext context, Widget child, bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: CareConnectTheme.primaryColor.withValues(alpha:0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
          ),
          padding: _getPadding(),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, Widget child, bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.secondaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: CareConnectTheme.secondaryColor.withValues(alpha:0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
          ),
          padding: _getPadding(),
        ),
        child: child,
      ),
    );
  }

  Widget _buildOutlineButton(BuildContext context, Widget child, bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CareConnectTheme.primaryColor,
          side: const BorderSide(color: CareConnectTheme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
          ),
          padding: _getPadding(),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, Widget child, bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: CareConnectTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
          ),
          padding: _getPadding(),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSuccessButton(BuildContext context, Widget child, bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.successColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: CareConnectTheme.successColor.withValues(alpha:0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
          ),
          padding: _getPadding(),
        ),
        child: child,
      ),
    );
  }

  Widget _buildWarningButton(BuildContext context, Widget child, bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.warningColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: CareConnectTheme.warningColor.withValues(alpha:0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
          ),
          padding: _getPadding(),
        ),
        child: child,
      ),
    );
  }

  Widget _buildErrorButton(BuildContext context, Widget child, bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CareConnectTheme.errorColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: CareConnectTheme.errorColor.withValues(alpha:0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
          ),
          padding: _getPadding(),
        ),
        child: child,
      ),
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case CareConnectButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: CareConnectTheme.spacingM,
          vertical: CareConnectTheme.spacingS,
        );
      case CareConnectButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: CareConnectTheme.spacingL,
          vertical: CareConnectTheme.spacingM,
        );
      case CareConnectButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: CareConnectTheme.spacingXL,
          vertical: CareConnectTheme.spacingL,
        );
    }
  }

  TextStyle _getTextStyle(BuildContext context, bool isDark) {
    final baseStyle = CareConnectTheme.button.copyWith(
      color: _getTextColor(context, isDark),
    );

    switch (size) {
      case CareConnectButtonSize.small:
        return baseStyle.copyWith(fontSize: 12);
      case CareConnectButtonSize.medium:
        return baseStyle.copyWith(fontSize: 14);
      case CareConnectButtonSize.large:
        return baseStyle.copyWith(fontSize: 16);
    }
  }

  Color _getTextColor(BuildContext context, bool isDark) {
    switch (type) {
      case CareConnectButtonType.primary:
      case CareConnectButtonType.secondary:
      case CareConnectButtonType.success:
      case CareConnectButtonType.warning:
      case CareConnectButtonType.error:
        return Colors.white;
      case CareConnectButtonType.outline:
      case CareConnectButtonType.text:
        return CareConnectTheme.primaryColor;
    }
  }

  double _getIconSize() {
    switch (size) {
      case CareConnectButtonSize.small:
        return 16;
      case CareConnectButtonSize.medium:
        return 20;
      case CareConnectButtonSize.large:
        return 24;
    }
  }
}

enum CareConnectButtonType {
  primary,
  secondary,
  outline,
  text,
  success,
  warning,
  error,
}

enum CareConnectButtonSize {
  small,
  medium,
  large,
}
