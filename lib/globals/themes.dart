import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
final ThemeData lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(),
  textTheme: const TextTheme(),
);

@NowaGenerated()
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF0A84FF),
    secondary: Color(0xFF0A84FF),
    surface: Color(0xFF1C1C1E),
    error: Color(0xFFFF453A),
    onPrimary: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: -1,
    ),
    titleLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Color(0xFFEBEBF5)),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF38383A),
    thickness: 0.5,
  ),
);
