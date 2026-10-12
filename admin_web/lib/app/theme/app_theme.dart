import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// `ThemeData` de `admin_web` — delega al sistema de diseño compartido
/// (`LavaderoTheme`) para mantener identidad visual consistente con
/// `mobile_app`. Punto de extensión si `admin_web` necesita alguna vez
/// diferenciarse (p. ej. densidad más compacta para tablas de escritorio).
abstract final class AppTheme {
  static ThemeData light() => LavaderoTheme.light();

  static ThemeData dark() => LavaderoTheme.dark();
}
