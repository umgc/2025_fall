import 'package:flutter/material.dart';
import '../config/theme/careconnect_theme.dart';

/// Enhanced CareConnect card widget with subtle animations and hover effects
class EnhancedCareConnectCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool enableHoverEffect;
  final bool enableTapAnimation;
  final Duration animationDuration;

  const EnhancedCareConnectCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.onTap,
    this.borderRadius,
    this.enableHoverEffect = true,
    this.enableTapAnimation = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<EnhancedCareConnectCard> createState() => _EnhancedCareConnectCardState();
}

class _EnhancedCareConnectCardState extends State<EnhancedCareConnectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  bool _isHovered = false;
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
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enableTapAnimation) {
      setState(() {
        _isPressed = true;
      });
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
    }
  }

  void _handleHoverEnter(PointerEvent event) {
    if (widget.enableHoverEffect) {
      setState(() {
        _isHovered = true;
      });
      _animationController.forward();
    }
  }

  void _handleHoverExit(PointerEvent event) {
    if (widget.enableHoverEffect) {
      setState(() {
        _isHovered = false;
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
    final baseElevation = widget.elevation ?? 8.0;
    final currentElevation = _isHovered ? baseElevation + _elevationAnimation.value : baseElevation;

    Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(CareConnectTheme.spacingL),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? 
               (isDark ? CareConnectTheme.darkSurfaceColor : CareConnectTheme.surfaceColor),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey[300]!).withValues(alpha:0.3),
            blurRadius: currentElevation,
            offset: Offset(0, currentElevation / 2),
            spreadRadius: _isHovered ? 2.0 : 0.0,
          ),
        ],
        border: _isHovered ? Border.all(
          color: CareConnectTheme.primaryColor.withValues(alpha:0.2),
          width: 1,
        ) : null,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardContent = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: cardContent,
      );
    }

    Widget animatedCard = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isHovered ? _scaleAnimation.value : 1.0,
          child: child!,
        );
      },
      child: cardContent,
    );

    if (widget.enableHoverEffect) {
      animatedCard = MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        child: animatedCard,
      );
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: animatedCard,
    );
  }
}

/// Specialized card for feature highlights with enhanced animations
class FeatureHighlightCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;
  final VoidCallback? onTap;

  const FeatureHighlightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.onTap,
  });

  @override
  State<FeatureHighlightCard> createState() => _FeatureHighlightCardState();
}

class _FeatureHighlightCardState extends State<FeatureHighlightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;

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

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedCareConnectCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _iconAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _iconAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (widget.iconColor ?? CareConnectTheme.primaryColor).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ?? CareConnectTheme.primaryColor,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: CareConnectTheme.spacingM),
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _textAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CareConnectTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: CareConnectTheme.spacingXS),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CareConnectTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
