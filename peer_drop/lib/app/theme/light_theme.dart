import 'package:flutter/material.dart';
import 'package:peer_drop/app/theme/app_text.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF5B5CEB),
    secondary: Color(0xFF7C6CFF),
    surface: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFF3F4F6),
    error: Color(0xFFEF4444),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF111827),
    outline: Color(0xFFE5E7EB),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  dividerColor: const Color(0xFFE5E7EB),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF111827),
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
  ),
  textTheme: AppTextTheme.textTheme,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: const Color(0x225B5CEB),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF5B5CEB), width: 2),
    ),
  ),
);
