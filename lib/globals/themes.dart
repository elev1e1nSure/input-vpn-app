import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Просека design-system tokens (oklch → sRGB)
// --background:   oklch(0.13 0 0)      → #1A1A1A
// --muted:        oklch(0.20 0 0)      → #262626
// --border:       oklch(0.24 0 0)      → #303030
// --muted-fg:     oklch(0.62 0 0)      → #8C8C8C
// --foreground:   oklch(0.97 0 0)      → #F5F5F5
// --accent-green: oklch(0.78 0.22 145) → #4ADE80
// --font-sans: 'Geist', 'Inter', system-ui — using Inter (google_fonts)
const _bg      = Color(0xFF1A1A1A);
const _muted   = Color(0xFF262626);
const _border  = Color(0xFF303030);
const _mutedFg = Color(0xFF8C8C8C);
const _fg      = Color(0xFFF5F5F5);
const _green   = Color(0xFF4ADE80);
const _red     = Color(0xFFFF453A);

TextTheme _buildTextTheme() => GoogleFonts.interTextTheme(const TextTheme(
      displayLarge: TextStyle(
          color: _fg, fontWeight: FontWeight.w800, letterSpacing: -1.0),
      titleLarge: TextStyle(
          color: _fg, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      titleMedium: TextStyle(
          color: _fg, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      bodyLarge:  TextStyle(color: _fg),
      bodyMedium: TextStyle(color: _mutedFg),
      bodySmall:  TextStyle(color: _mutedFg),
      labelSmall: TextStyle(color: _mutedFg, letterSpacing: 0),
    ));

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _bg,
  colorScheme: ColorScheme.dark(
    primary:          _green,
    secondary:        _green,
    surface:          _muted,
    error:            _red,
    onPrimary:        _bg,
    onSecondary:      _bg,
    onSurface:        _fg,
    onError:          _fg,
    errorContainer:   _red.withValues(alpha: 0.12),
    onErrorContainer: _red,
  ),
  textTheme: _buildTextTheme(),
  cardTheme: const CardThemeData(
    color: _muted,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      side: BorderSide(color: _border, width: 0.5),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      color: _fg,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
  ),
  iconTheme: const IconThemeData(color: _fg),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? _bg : _mutedFg,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? _green : _border,
    ),
    trackOutlineWidth: const WidgetStatePropertyAll(0),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  dividerTheme: const DividerThemeData(color: _border, thickness: 0.5),
  listTileTheme: const ListTileThemeData(iconColor: _mutedFg),
);

final ThemeData lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(),
  textTheme: const TextTheme(),
  switchTheme: SwitchThemeData(
    trackOutlineWidth: const WidgetStatePropertyAll(0.5),
    trackOutlineColor: WidgetStateProperty.all(
      const Color(0xFF808080).withValues(alpha: 0.25),
    ),
  ),
);
