import 'package:flutter/material.dart';
import '../config/theme/careconnect_theme.dart';

/// Modern CareConnect card widget with enhanced styling
class CareConnectCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CareConnectCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(CareConnectTheme.spacingL),
      decoration: BoxDecoration(
        color: backgroundColor ?? 
               (isDark ? CareConnectTheme.darkSurfaceColor : CareConnectTheme.surfaceColor),
        borderRadius: borderRadius ?? BorderRadius.circular(CareConnectTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(CareConnectTheme.radiusL),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

/// Specialized card for displaying health metrics
class HealthMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const HealthMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CareConnectCard(
      onTap: onTap,
      padding: const EdgeInsets.all(CareConnectTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(CareConnectTheme.spacingS),
                  decoration: BoxDecoration(
                    color: (iconColor ?? CareConnectTheme.primaryColor).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(CareConnectTheme.radiusM),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? CareConnectTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: CareConnectTheme.spacingM),
              ],
              Expanded(
                child: Text(
                  title,
                  style: CareConnectTheme.bodyMedium.copyWith(
                    color: isDark ? CareConnectTheme.darkTextSecondary : CareConnectTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CareConnectTheme.spacingS),
          Text(
            value,
            style: CareConnectTheme.heading4.copyWith(
              color: valueColor ?? (isDark ? CareConnectTheme.darkTextPrimary : CareConnectTheme.textPrimary),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: CareConnectTheme.spacingXS),
            Text(
              subtitle!,
              style: CareConnectTheme.bodySmall.copyWith(
                color: isDark ? CareConnectTheme.darkTextTertiary : CareConnectTheme.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card for displaying quick actions
class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? CareConnectTheme.primaryColor;
    
    return CareConnectCard(
      onTap: onTap,
      padding: const EdgeInsets.all(CareConnectTheme.spacingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(CareConnectTheme.radiusL),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: CareConnectTheme.spacingS),
          Text(
            title,
            style: CareConnectTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? CareConnectTheme.darkTextPrimary : CareConnectTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
