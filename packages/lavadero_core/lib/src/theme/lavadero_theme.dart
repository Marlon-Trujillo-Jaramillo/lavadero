import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// `ThemeData` claro/oscuro (Material 3) compartido entre `admin_web` y
/// `mobile_app`. Antes cada app construía su propio `ThemeData` casi
/// idéntico usando solo los defaults de `ColorScheme.fromSeed` (sin
/// component theming) — de ahí la sensación de UI "plana"/cuadrada. Este
/// builder centraliza forma (radios), tipografía y densidad para que ambas
/// apps compartan una identidad visual real, no solo una paleta.
abstract final class LavaderoTheme {
  static ThemeData light() => _themeFrom(Brightness.light);

  static ThemeData dark() => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LavaderoColors.primary,
      brightness: brightness,
    );
    final textTheme = LavaderoTypography.apply(
      ThemeData(brightness: brightness).textTheme,
    );
    final radiusMd = BorderRadius.circular(LavaderoRadii.md);
    final radiusLg = BorderRadius.circular(LavaderoRadii.lg);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: LavaderoSpacing.lg,
            vertical: LavaderoSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: LavaderoSpacing.lg,
            vertical: LavaderoSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: LavaderoSpacing.lg,
            vertical: LavaderoSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LavaderoSpacing.md,
          vertical: LavaderoSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LavaderoRadii.full),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: LavaderoSpacing.sm,
          vertical: LavaderoSpacing.xs,
        ),
        labelStyle: textTheme.labelLarge,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: LavaderoSpacing.lg,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorShape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorShape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
    );
  }
}
