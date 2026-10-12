import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// `ThemeData` de `mobile_app` — delega al sistema de diseño compartido
/// (`LavaderoTheme`) para mantener identidad visual consistente con
/// `admin_web`.
abstract final class AppTheme {
  static ThemeData light() => LavaderoTheme.light();

  static ThemeData dark() => LavaderoTheme.dark();
}
