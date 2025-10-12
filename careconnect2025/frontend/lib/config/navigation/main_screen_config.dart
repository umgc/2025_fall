import 'package:flutter/material.dart';
import 'bottom_nav_config.dart';

class MainScreenConfig {
  final String userRole;
  final int userId;
  final int? patientId;
  final int? caregiverId;
  final List<BottomNavItem>? customNavItems;
  final Color? primaryColor;
  final Color? backgroundColor;
  final bool enablePageAnimation;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showAppBar;
  final String? appBarTitle;
  final List<Widget>? appBarActions;

  const MainScreenConfig({
    required this.userRole,
    required this.userId,
    this.patientId,
    this.caregiverId,
    this.customNavItems,
    this.primaryColor,
    this.backgroundColor,
    this.enablePageAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.showAppBar = false,
    this.appBarTitle,
    this.appBarActions,
  });

  List<BottomNavItem> getNavItems() {
    return customNavItems ?? BottomNavConfig.getNavItemsForRole(userRole);
  }

  MainScreenConfig copyWith({
    String? userRole,
    int? userId,
    int? patientId,
    int? caregiverId,
    List<BottomNavItem>? customNavItems,
    Color? primaryColor,
    Color? backgroundColor,
    bool? enablePageAnimation,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? showAppBar,
    String? appBarTitle,
    List<Widget>? appBarActions,
  }) {
    return MainScreenConfig(
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      customNavItems: customNavItems ?? this.customNavItems,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      enablePageAnimation: enablePageAnimation ?? this.enablePageAnimation,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      showAppBar: showAppBar ?? this.showAppBar,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      appBarActions: appBarActions ?? this.appBarActions,
    );
  }

  static MainScreenConfig forPatient({
    required int userId,
    int? patientId,
    List<BottomNavItem>? customNavItems,
    Color? primaryColor,
  }) {
    return MainScreenConfig(
      userRole: 'PATIENT',
      userId: userId,
      patientId: patientId,
      customNavItems: customNavItems,
      primaryColor: primaryColor,
    );
  }

  static MainScreenConfig forCaregiver({
    required int userId,
    int? caregiverId,
    int? patientId,
    List<BottomNavItem>? customNavItems,
    Color? primaryColor,
  }) {
    return MainScreenConfig(
      userRole: 'CAREGIVER',
      userId: userId,
      caregiverId: caregiverId,
      patientId: patientId,
      customNavItems: customNavItems,
      primaryColor: primaryColor,
    );
  }

  static MainScreenConfig forFamilyMember({
    required int userId,
    int? patientId,
    List<BottomNavItem>? customNavItems,
    Color? primaryColor,
  }) {
    return MainScreenConfig(
      userRole: 'FAMILY_LINK',
      userId: userId,
      patientId: patientId,
      customNavItems: customNavItems,
      primaryColor: primaryColor,
    );
  }
}
