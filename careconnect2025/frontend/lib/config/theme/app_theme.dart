import 'package:flutter/material.dart';

/// Centralized theme configuration for the CareConnect app
/// This ensures consistent colors, typography, and component styles across the app
class AppTheme {
  // Light Theme Colors
  // Main app colors
  static const Color primaryDark = Color(0xFF0B4D4D); // deep teal
  static const Color primary = Color(0xFF0F6D6D); // calm healthcare teal
  static const Color primaryLight = Color(0xFF2FA7A6); // lighter teal for hover/focus
  static const Color accent = Color(0xFF2FA7A6); // secondary teal accent

  // Status colors
  static const Color success = Color(0xFF2E7D32); // accessible green
  static const Color warning = Color(0xFFB7791F); // warm amber
  static const Color error = Color(0xFFC0362C); // softened red
  static const Color info = Color(0xFF2A84B5); // calm clinical blue

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937); // slate-900
  static const Color textSecondary = Color(0xFF6B7280); // slate-500/600
  static const Color textLight = Color(0xFFFFFFFF); // white

  // Background colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF); // white
  static const Color backgroundSecondary = Color(0xFFF7FAFC); // soft cool gray-blue
  static const Color cardBackground = Color(0xFFFFFFFF); // white

  // Border colors
  static const Color borderColor = Color(0xFFE5E7EB); // light divider

  // Dark Theme Colors
  // Main app colors (brighter on dark so onPrimary can remain dark text)
  static const Color primaryDarkThemeDark = Color(0xFF5FD6D5); // high-visibility teal
  static const Color primaryDarkTheme = Color(0xFF3EC4C3); // main teal on dark
  static const Color primaryDarkThemeLight = Color(0xFF7DE9E7); // lighter teal for focus
  static const Color accentDarkTheme = Color(0xFF7AD9D7); // accent for dark theme

  // Status colors - tuned for dark backgrounds
  static const Color successDarkTheme = Color(0xFF4FD067); // friendly green
  static const Color warningDarkTheme = Color(0xFFF8C26B); // warm amber
  static const Color errorDarkTheme = Color(0xFFF16A5B); // softer red
  static const Color infoDarkTheme = Color(0xFF6DD3F5); // light cyan-blue

  // Text colors for dark theme
  static const Color textPrimaryDarkTheme = Color(0xFFE5F2F1); // near-white with a hint of teal
  static const Color textSecondaryDarkTheme = Color(0xFFA8B8BE); // muted light slate
  static const Color textDarkThemeDark = Color(0xFF0B0F14); // deep near-black for onPrimary

  // Background colors for dark theme
  static const Color backgroundPrimaryDarkTheme = Color(0xFF0B0F14); // deep blue-charcoal
  static const Color backgroundSecondaryDarkTheme = Color(0xFF131A22); // slightly lighter
  static const Color cardBackgroundDarkTheme = Color(0xFF0F151C); // card surface

  // Border colors for dark theme
  static const Color borderColorDarkTheme = Color(0xFF2A3440); // muted blue-gray

  // Video call specific colors
  static const Color videoCallBackground = Color(0xFF000000); // black
  static const Color videoCallBackgroundDarkTheme = Color(0xFF0B0F14); // dark background
  static const Color videoCallText = Color(0xFFFFFFFF); // white
  static const Color videoCallTextSecondary = Color(0xFFB7C4CC); // subtle secondary text
  static const Color videoCallTextTertiary = Color(0xFF8FA0AA); // tertiary text
  static const Color videoCallEndCall = Color(0xFFD92D20); // end call red
  static const Color videoCallEndCallDarkTheme = Color(0xFFF04438); // lighter red for dark theme

  // Chat/messaging specific colors
  static const Color chatUserMessage = Color(0xFF0F6D6D); // primary teal
  static const Color chatUserMessageDarkTheme = Color(0xFF3EC4C3); // dark theme primary
  static const Color chatBotMessage = Color(0xFFF2F6F9); // gentle cool surface
  static const Color chatBotMessageDarkTheme = Color(0xFF0F151C); // card background dark theme
  static const Color chatTextOnPrimary = Color(0xFFFFFFFF); // white text on primary
  static const Color chatTextOnSecondary = Color(0xFF1F2937); // dark text on light background
  static const Color chatTextOnSecondaryDarkTheme = Color(0xFFE5F2F1); // light text on dark background

  // Typography styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textLight,
  );

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary, // calm healthcare teal
    foregroundColor: textLight,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: buttonText,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primary, // teal outline
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: primary, width: 1.5),
    ),
    textStyle: buttonText,
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primary, // teal text button
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  );

  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: error,
    foregroundColor: textLight,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: buttonText,
  );

  // Card styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Input decoration
  static InputDecoration inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Generate theme data for MaterialApp
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        error: error,
        surface: cardBackground,
        onPrimary: textLight,
        onSecondary: textLight,
        onSurface: textPrimary,
        onError: textLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardBackground,
        contentTextStyle: TextStyle(color: textPrimary),
        actionTextColor: primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary, // teal app bar
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: cardBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        fillColor: backgroundPrimary,
        filled: true,
      ),
      textTheme: const TextTheme(
        displayLarge: headingLarge,
        displayMedium: headingMedium,
        displaySmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      dividerTheme: const DividerThemeData(thickness: 1, color: borderColor),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return textSecondary.withOpacity(0.3);
          }
          return primary;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundPrimary,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
      ),
      useMaterial3: true,
    );
  }

  // Generate dark theme data for MaterialApp
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryDarkTheme,
      colorScheme: const ColorScheme.dark(
        primary: primaryDarkTheme,
        secondary: accentDarkTheme,
        error: errorDarkTheme,
        surface: cardBackgroundDarkTheme,
        onPrimary: textDarkThemeDark, // deep near-black for readability
        onSecondary: textDarkThemeDark,
        onSurface: textPrimaryDarkTheme,
        onError: textDarkThemeDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundPrimaryDarkTheme,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardBackgroundDarkTheme,
        contentTextStyle: TextStyle(color: textPrimaryDarkTheme),
        actionTextColor: primaryDarkThemeLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDarkTheme, // teal on dark
        foregroundColor: textDarkThemeDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDarkThemeDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textDarkThemeDark),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: cardBackgroundDarkTheme,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkTheme,
          foregroundColor: textDarkThemeDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDarkThemeLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColorDarkTheme),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDarkThemeLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        fillColor: backgroundSecondaryDarkTheme,
        filled: true,
        labelStyle: const TextStyle(color: textSecondaryDarkTheme),
        hintStyle: const TextStyle(color: textSecondaryDarkTheme),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryDarkTheme,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryDarkTheme,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryDarkTheme,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimaryDarkTheme),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimaryDarkTheme),
        bodySmall: TextStyle(fontSize: 12, color: textSecondaryDarkTheme),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: borderColorDarkTheme,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return textSecondaryDarkTheme.withOpacity(0.3);
          }
          return primaryDarkTheme;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      iconTheme: const IconThemeData(color: textPrimaryDarkTheme),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundPrimaryDarkTheme,
        selectedItemColor: primaryDarkThemeLight,
        unselectedItemColor: textSecondaryDarkTheme,
      ),
      useMaterial3: true,
      dialogTheme: const DialogThemeData(
        backgroundColor: cardBackgroundDarkTheme,
      ),
    );
  }
}
