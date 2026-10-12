import 'package:flutter/material.dart';

/// Paleta de marca compartida entre `mobile_app` y `admin_web`. Cada app
/// construye su propio `ThemeData` (claro/oscuro, Material 3) en
/// `app/theme/`, pero ambas parten de estos mismos valores para mantener
/// identidad visual consistente.
abstract final class LavaderoColors {
  static const Color primary = Color(0xFF00695C); // verde-azulado "agua"
  static const Color primaryDark = Color(0xFF4DB6AC);
  static const Color secondary = Color(0xFF0277BD);
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
}

/// Espaciado base (múltiplos de 4dp) para paddings/gaps consistentes.
abstract final class LavaderoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Radios de borde estándar.
abstract final class LavaderoRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  /// Redondeo total — pills/badges/chips.
  static const double full = 999;
}

/// Jerarquía tipográfica compartida. Se aplica sobre el `TextTheme` que
/// genera Material 3 a partir del `ColorScheme` (mantiene los colores
/// correctos por brightness), solo ajustando peso/tracking para que la UI
/// no se sienta "plana" con los pesos por defecto.
abstract final class LavaderoTypography {
  static TextTheme apply(TextTheme base) {
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.35),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
