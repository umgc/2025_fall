import 'package:flutter/material.dart';
import '../config/theme/careconnect_theme.dart';

/// Enhanced CareConnect button with micro-interactions and animations
class EnhancedCareConnectButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final CareConnectButtonType type;
  final CareConnectButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool enableHapticFeedback;
  final Duration animationDuration;

  const EnhancedCareConnectButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CareConnectButtonType.primary,
    this.size = CareConnectButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<EnhancedCareConnectButton> createState() => _EnhancedCareConnectButtonState();
}

class _EnhancedCareConnectButtonState extends State<EnhancedCareConnectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
      
      if (widget.enableHapticFeedback) {
        // Haptic feedback for better UX
        // HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buttonChild = _buildButtonChild(context, isDark);

    Widget button = _buildButton(context, buttonChild);

    if (widget.isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: button,
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context, Widget child) {
    switch (widget.type) {
      case CareConnectButtonType.primary:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CareConnectTheme.primaryColor,
                CareConnectTheme.primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: _getPadding(widget.size),
                child: child,
              ),
            ),
          ),
        );
      case CareConnectButtonType.secondary:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CareConnectTheme.secondaryColor,
                CareConnectTheme.secondaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.secondaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: _getPadding(widget.size),
                child: child,
              ),
            ),
          ),
        );
      case CareConnectButtonType.outline:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CareConnectTheme.primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: _getPadding(widget.size),
                child: child,
              ),
            ),
          ),
        );
      case CareConnectButtonType.text:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: _getPadding(widget.size),
              child: child,
            ),
          ),
        );
      case CareConnectButtonType.success:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CareConnectTheme.successColor,
                CareConnectTheme.successColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.successColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: _getPadding(widget.size),
                child: child,
              ),
            ),
          ),
        );
      case CareConnectButtonType.warning:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CareConnectTheme.warningColor,
                CareConnectTheme.warningColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.warningColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: _getPadding(widget.size),
                child: child,
              ),
            ),
          ),
        );
      case CareConnectButtonType.error:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CareConnectTheme.errorColor,
                CareConnectTheme.errorColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CareConnectTheme.errorColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: _getPadding(widget.size),
                child: child,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildButtonChild(BuildContext context, bool isDark) {
    final textStyle = _getTextStyle(context, widget.size).copyWith(
      color: widget.type == CareConnectButtonType.outline || widget.type == CareConnectButtonType.text
          ? (isDark ? CareConnectTheme.primaryColor.withValues(alpha: 0.8) : CareConnectTheme.primaryColor)
          : Colors.white,
      fontWeight: FontWeight.w600,
    );

    if (widget.isLoading) {
      return SizedBox(
        height: textStyle.fontSize! * 1.2,
        width: textStyle.fontSize! * 1.2,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textStyle.color!),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: textStyle.fontSize,
            color: textStyle.color,
          ),
          const SizedBox(width: CareConnectTheme.spacingS),
          Text(
            widget.text,
            style: textStyle,
          ),
        ],
      );
    }
    
    return Text(
      widget.text,
      style: textStyle,
      textAlign: TextAlign.center,
    );
  }

  EdgeInsetsGeometry _getPadding(CareConnectButtonSize size) {
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

  TextStyle _getTextStyle(BuildContext context, CareConnectButtonSize size) {
    switch (size) {
      case CareConnectButtonSize.small:
        return Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 12);
      case CareConnectButtonSize.medium:
        return Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 16);
      case CareConnectButtonSize.large:
        return Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 18);
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
