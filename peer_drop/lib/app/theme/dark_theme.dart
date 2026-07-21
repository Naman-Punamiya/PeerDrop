import 'package:flutter/material.dart';
import 'package:peer_drop/app/theme/app_text.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF7C6CFF),
    secondary: Color(0xFF9D8DFF),
    surface: Color(0xFF1A1B26),
    surfaceContainerHighest: Color(0xFF25273A),
    error: Color(0xFFEF4444),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFFF8FAFC),
    outline: Color(0xFF35374B),
  ),
  scaffoldBackgroundColor: const Color(0xFF0F111A),
  dividerColor: const Color(0xFF2D2F45),
  cardTheme: CardThemeData(
    color: const Color(0xFF1A1B26),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
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
