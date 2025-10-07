import 'package:flutter/material.dart';

class AppTheme {
  // ===== Palette from your tokens =====
  // Light tokens
  static const _bgLight = Color(0xFFFFFFFF);
  static const _fgLight = Color(0xFF1F2937);
  static const _cardLight = Color(0xFFFFFFFF);
  static const _secondaryLight = Color(0xFFF1F5F9);
  static const _mutedLight = Color(0xFFF8FAFC);
  static const _borderLight = Color(0xFFE2E8F0);
  static const _inputBgLight = Color(0xFFF8FAFC);
  static const _inputBorderLight = Color(0xFFCBD5E1);

  static const _primaryLight = Color(0xFF1E40AF);
  static const _accentLight = Color(0xFF3B82F6);
  static const _successLight = Color(0xFF059669);
  static const _warningLight = Color(0xFFF59E0B);
  static const _errorLight = Color(0xFFDC2626);
  static const _infoLight = Color(0xFF60A5FA); // used in a few widgets

  // Dark tokens
  static const _bgDark = Color(0xFF0F172A);
  static const _fgDark = Color(0xFFF1F5F9);
  static const _cardDark = Color(0xFF1E293B);
  static const _secondaryDark = Color(0xFF334155);
  static const _mutedDark = Color(0xFF1E293B);
  static const _borderDark = Color(0xFF334155);
  static const _inputBgDark = Color(0xFF334155);
  static const _inputBorderDark = Color(0xFF475569);

  static const _primaryDark = Color(0xFF3B82F6);
  static const _accentDark = Color(0xFF60A5FA);
  static const _successDark = Color(0xFF10B981);
  static const _warningDark = Color(0xFFF59E0B);
  static const _errorDark = Color(0xFFEF4444);
  static const _infoDark = Color(0xFF60A5FA);

  // Radii to mirror --radius: 12px
  static const _radius = 12.0;

  // ===== Public ThemeData (used by MaterialApp) =====
  static ThemeData get lightTheme {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primaryLight,
      onPrimary: Colors.white,
      secondary: _secondaryLight,
      onSecondary: const Color(0xFF475569),
      surface: _cardLight,
      onSurface: _fgLight,
      background: _bgLight,
      onBackground: _fgLight,
      error: _errorLight,
      onError: Colors.white,
      primaryContainer: _accentLight,
      onPrimaryContainer: Colors.white,
      secondaryContainer: _mutedLight,
      onSecondaryContainer: const Color(0xFF64748B),
      outline: _borderLight,
      outlineVariant: _inputBorderLight,
      surfaceTint: Colors.transparent,
      tertiary: _accentLight,
      onTertiary: Colors.white,
      inverseSurface: Colors.black,
      onInverseSurface: Colors.white,
      scrim: Colors.black54,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: _primaryLight,
      scaffoldBackgroundColor: _bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgLight,
        foregroundColor: _fgLight,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: _borderLight),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: _inputBgLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _inputBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _inputBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _primaryLight, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _errorLight),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryDark,
      onPrimary: Colors.white,
      secondary: _secondaryDark,
      onSecondary: const Color(0xFFCBD5E1),
      surface: _cardDark,
      onSurface: _fgDark,
      background: _bgDark,
      onBackground: _fgDark,
      error: _errorDark,
      onError: Colors.white,
      primaryContainer: _accentDark,
      onPrimaryContainer: Colors.white,
      secondaryContainer: _secondaryDark,
      onSecondaryContainer: const Color(0xFFCBD5E1),
      outline: _borderDark,
      outlineVariant: _inputBorderDark,
      surfaceTint: Colors.transparent,
      tertiary: _accentDark,
      onTertiary: Colors.white,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      scrim: Colors.black54,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: _primaryDark,
      scaffoldBackgroundColor: _bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgDark,
        foregroundColor: _fgDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: _borderDark),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: _inputBgDark,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _inputBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _inputBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _primaryDark, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
          borderSide: BorderSide(color: _errorDark),
        ),
      ),
    );
  }

  // ===== Compatibility layer for existing code =====
  // Static colors previously referenced directly
  static const primary = _primaryLight;
  static const primaryLight = _accentLight; // brighter primary
  static const primaryDark = _primaryDark;
  static const accent = _accentLight;

  static const success = _successLight;
  static const successDarkTheme = _successDark;

  static const warning = _warningLight;
  static const warningDarkTheme = _warningDark;

  static const error = _errorLight;
  static const errorDarkTheme = _errorDark;

  static const info = _infoLight;
  static const infoDarkTheme = _infoDark;

  static const borderColor = _borderLight;

  static const textPrimary = _fgLight;
  static const textSecondary = Color(0xFF64748B);
  static const textLight = Colors.white;

  static const backgroundPrimary = _bgLight;
  static const backgroundSecondary = _secondaryLight;
  static const backgroundSecondaryDarkTheme = _secondaryDark;
  static const cardBackground = _cardLight;

  static const primaryDarkTheme = _primaryDark;
  static const primaryDarkThemeLight = _accentDark;

  // Video call specific colors used in widgets
  static const videoCallBackground = Color(0xFF0B1220); // tasteful dark navy
  static const videoCallBackgroundDarkTheme = Color(0xFF0B1220);
  static const videoCallText = Color(0xFFF1F5F9);
  static const videoCallTextSecondary = Color(0xFFCBD5E1);
  static const videoCallTextTertiary = Color(0xFF94A3B8);
  static const videoCallEndCall = _errorLight;
  static const videoCallEndCallDarkTheme = _errorDark;

  // Chat bubble color referenced once
  static const chatUserMessage = Color(0xFFEFF6FF); // light blue bubble

  // ===== Text styles your code references =====
  // Use neutral families. You already apply Roboto in main.dart.
  static const headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ===== Button styles your code references =====
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(44),
    side: const BorderSide(color: borderColor),
    foregroundColor: textPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static final ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: accent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static final ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: error,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  // ===== Input decoration helper your screens call =====
  static InputDecoration inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: _inputBgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
        borderSide: BorderSide(color: _inputBorderLight),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
        borderSide: BorderSide(color: _inputBorderLight),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
        borderSide: BorderSide(color: _primaryLight, width: 1.6),
      ),
<<<<<<< HEAD
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
        borderSide: BorderSide(color: _errorLight),
=======
      scaffoldBackgroundColor: backgroundPrimary,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardBackground,
        contentTextStyle: TextStyle(color: textPrimary),
        actionTextColor: primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary, // Using our UX blue color
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
        onPrimary: textDarkThemeDark,
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
        backgroundColor: primaryDarkTheme, // Using our primary dark theme color
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
          borderSide: const BorderSide(color: borderColorDarkTheme)
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
>>>>>>> origin/team_d_ocr_textract
      ),
    );
  }
}
