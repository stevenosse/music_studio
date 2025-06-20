import 'package:flutter/material.dart';

// Light theme inspired by professional DAW interfaces
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2C7BE5),         // Bright blue for primary actions
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFD6E6FF),
  onPrimaryContainer: Color(0xFF0A2E5C),
  secondary: Color(0xFF00B8D4),       // Teal accent for secondary elements
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFCFF8FF),
  onSecondaryContainer: Color(0xFF00363D),
  tertiary: Color(0xFFFF6B6B),        // Coral for tertiary elements
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFDADA),
  onTertiaryContainer: Color(0xFF410002),
  error: Color(0xFFE53935),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  outline: Color(0xFF79747E),
  surface: Color(0xFFF5F7FA),         // Light gray background
  onSurface: Color(0xFF1F2933),       // Dark text on light background
  surfaceContainerHighest: Color(0xFFE4E7EB), // For container backgrounds
  onSurfaceVariant: Color(0xFF49454F),
  inverseSurface: Color(0xFF2D3748),
  onInverseSurface: Color(0xFFF5F7FA),
  inversePrimary: Color(0xFF90CAF9),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF2C7BE5),
  outlineVariant: Color(0xFFCAC4D0),
  scrim: Color(0xFF000000),
);

// Dark theme inspired by professional DAW interfaces like Ableton, FL Studio
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF3699FF),         // Bright blue for primary actions
  onPrimary: Color(0xFF003060),
  primaryContainer: Color(0xFF004B9A),
  onPrimaryContainer: Color(0xFFD1E4FF),
  secondary: Color(0xFF00E5FF),       // Bright cyan for secondary elements
  onSecondary: Color(0xFF003641),
  secondaryContainer: Color(0xFF004E5D),
  onSecondaryContainer: Color(0xFFA4F5FF),
  tertiary: Color(0xFFFF5252),        // Red accent for tertiary elements
  onTertiary: Color(0xFF690005),
  tertiaryContainer: Color(0xFF93000A),
  onTertiaryContainer: Color(0xFFFFDAD6),
  error: Color(0xFFFF5252),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  outline: Color(0xFF8A8D93),
  surface: Color(0xFF1E1E2D),         // Very dark blue-gray for main background
  onSurface: Color(0xFFE6E8EC),       // Light text on dark background
  surfaceContainerHighest: Color(0xFF2D2D3F), // Slightly lighter for container backgrounds
  onSurfaceVariant: Color(0xFFCAC4D0),
  inverseSurface: Color(0xFFE6E8EC),
  onInverseSurface: Color(0xFF1E1E2D),
  inversePrimary: Color(0xFF3699FF),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF3699FF),
  outlineVariant: Color(0xFF49454F),
  scrim: Color(0xFF000000),
);
