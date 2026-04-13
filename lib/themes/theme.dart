import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF6200EE),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFBB86FC),
  onPrimaryContainer: Colors.black,
  secondary: Color(0xFF03DAC6),
  onSecondary: Colors.black,
  secondaryContainer: Color(0xFF018786),
  onSecondaryContainer: Colors.white,
  error: Color(0xFFB00020),
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Colors.black,
  surfaceContainerHighest: Color(0xFFF3F3F3),
  onSurfaceVariant: Color(0xFF757575),
  outline: Color(0xFF757575),
  shadow: Colors.black,
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFBB86FC),
  onPrimary: Colors.black,
  primaryContainer: Color(0xFF3700B3),
  onPrimaryContainer: Colors.white,
  secondary: Color(0xFF03DAC6),
  onSecondary: Colors.black,
  secondaryContainer: Color(0xFF018786),
  onSecondaryContainer: Colors.white,
  error: Color(0xFFCF6679),
  onError: Colors.black,
  surface: Color(0xFF121212),
  onSurface: Colors.white,
  surfaceContainerHighest: Color(0xFF2C2C2C),
  onSurfaceVariant: Color(0xFFBDBDBD),
  outline: Color(0xFFBDBDBD),
  shadow: Colors.black,
);

final ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: lightColorScheme.surface,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          WidgetStateProperty.all(lightColorScheme.primary),
      foregroundColor: WidgetStateProperty.all(
          lightColorScheme.onPrimary),
      elevation: WidgetStateProperty.all(2.0),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 8.0),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.primary,
    foregroundColor: lightColorScheme.onPrimary,
    elevation: 4,
    centerTitle: true,
  ),
  cardTheme: CardTheme(
    color: lightColorScheme.surface,
    shadowColor: lightColorScheme.shadow,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ).data,
);

final ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          WidgetStateProperty.all(darkColorScheme.primary),
      foregroundColor: WidgetStateProperty.all(
          darkColorScheme.onPrimary),
      elevation: WidgetStateProperty.all(2.0),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 8.0),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
  ),
);
