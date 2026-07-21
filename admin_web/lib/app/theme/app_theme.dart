import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// `ThemeData` claro/oscuro (Material 3) de `admin_web`, construido a partir
/// de los mismos design tokens compartidos que `mobile_app` (identidad de
/// marca consistente entre ambas apps).
abstract final class AppTheme {
  static ThemeData light() => _themeFrom(Brightness.light);

  static ThemeData dark() => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LavaderoColors.primary,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
