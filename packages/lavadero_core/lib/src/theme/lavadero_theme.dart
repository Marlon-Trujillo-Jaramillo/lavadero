import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// `ThemeData` claro/oscuro (Material 3) compartido entre `admin_web` y
/// `mobile_app`, identidad "Aqua premium". El `ColorScheme` se arma a mano
/// (no `fromSeed`): fromSeed derivaba tonos apagados y la UI se veía
/// genérica. Todo componente de Material queda tematizado aquí para que las
/// pantallas no necesiten estilos sueltos.
abstract final class LavaderoTheme {
  static ThemeData light() => _themeFrom(_lightScheme);

  static ThemeData dark() => _themeFrom(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: LavaderoColors.ocean,
    onPrimary: LavaderoColors.white,
    primaryContainer: LavaderoColors.oceanContainer,
    onPrimaryContainer: LavaderoColors.onOceanContainer,
    secondary: LavaderoColors.aqua,
    onSecondary: LavaderoColors.ink,
    secondaryContainer: LavaderoColors.aquaContainer,
    onSecondaryContainer: LavaderoColors.onAquaContainer,
    tertiary: LavaderoColors.success,
    onTertiary: LavaderoColors.white,
    error: LavaderoColors.error,
    onError: LavaderoColors.white,
    errorContainer: LavaderoColors.errorContainer,
    onErrorContainer: LavaderoColors.onErrorContainer,
    surface: LavaderoColors.canvas,
    onSurface: LavaderoColors.ink,
    onSurfaceVariant: LavaderoColors.inkSecondary,
    surfaceContainerLowest: LavaderoColors.surface,
    surfaceContainerLow: LavaderoColors.surface,
    surfaceContainer: LavaderoColors.surfaceMuted,
    surfaceContainerHigh: LavaderoColors.surfaceMuted,
    surfaceContainerHighest: LavaderoColors.surfaceSunken,
    outline: LavaderoColors.lineStrong,
    outlineVariant: LavaderoColors.line,
    shadow: LavaderoColors.shadow,
    scrim: LavaderoColors.shadow,
    inverseSurface: LavaderoColors.ink,
    onInverseSurface: LavaderoColors.inkDark,
    inversePrimary: LavaderoColors.oceanBright,
    surfaceTint: LavaderoColors.transparent,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: LavaderoColors.oceanBright,
    onPrimary: LavaderoColors.white,
    primaryContainer: LavaderoColors.oceanContainerDark,
    onPrimaryContainer: LavaderoColors.onOceanContainerDark,
    secondary: LavaderoColors.aquaBright,
    onSecondary: LavaderoColors.canvasDark,
    secondaryContainer: LavaderoColors.aquaContainerDark,
    onSecondaryContainer: LavaderoColors.onAquaContainerDark,
    tertiary: LavaderoColors.success,
    onTertiary: LavaderoColors.white,
    error: LavaderoColors.error,
    onError: LavaderoColors.white,
    errorContainer: LavaderoColors.errorContainerDark,
    onErrorContainer: LavaderoColors.onErrorContainerDark,
    surface: LavaderoColors.canvasDark,
    onSurface: LavaderoColors.inkDark,
    onSurfaceVariant: LavaderoColors.inkSecondaryDark,
    surfaceContainerLowest: LavaderoColors.canvasDark,
    surfaceContainerLow: LavaderoColors.surfaceDark,
    surfaceContainer: LavaderoColors.surfaceMutedDark,
    surfaceContainerHigh: LavaderoColors.surfaceMutedDark,
    surfaceContainerHighest: LavaderoColors.surfaceSunkenDark,
    outline: LavaderoColors.lineStrongDark,
    outlineVariant: LavaderoColors.lineDark,
    shadow: LavaderoColors.shadowDark,
    scrim: LavaderoColors.shadowDark,
    inverseSurface: LavaderoColors.inkDark,
    onInverseSurface: LavaderoColors.ink,
    inversePrimary: LavaderoColors.ocean,
    surfaceTint: LavaderoColors.transparent,
  );

  static ThemeData _themeFrom(ColorScheme scheme) {
    final brightness = scheme.brightness;
    final textTheme = LavaderoTypography.apply(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final radiusSm = BorderRadius.circular(LavaderoRadii.sm);
    final radiusMd = BorderRadius.circular(LavaderoRadii.md);
    final radiusLg = BorderRadius.circular(LavaderoRadii.lg);
    final radiusXl = BorderRadius.circular(LavaderoRadii.xl);
    const controlPadding = EdgeInsets.symmetric(
      horizontal: LavaderoSpacing.lg,
      vertical: LavaderoSpacing.md,
    );
    const minControl = Size(64, LavaderoSizes.controlHeight);
    final cardColor = scheme.surfaceContainerLow;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: LavaderoTypography.fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: LavaderoColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLg,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: LavaderoColors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleSpacing: LavaderoSpacing.md,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minControl,
          padding: controlPadding,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: minControl,
          padding: controlPadding,
          textStyle: textTheme.labelLarge,
          backgroundColor: cardColor,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: radiusMd,
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minControl,
          padding: controlPadding,
          textStyle: textTheme.labelLarge,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Sin el gris de hover/foco de Material sobre el relleno blanco: el
        // estado lo comunica el borde (y el foco, el borde de color).
        hoverColor: LavaderoColors.transparent,
        focusColor: LavaderoColors.transparent,
        fillColor: brightness == Brightness.light
            ? LavaderoColors.surface
            : scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LavaderoSpacing.md,
          vertical: LavaderoSpacing.md,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LavaderoRadii.full),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: cardColor,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: LavaderoSpacing.sm,
          vertical: LavaderoSpacing.xs,
        ),
        labelStyle: textTheme.labelLarge,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LavaderoSpacing.md,
        ),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: LavaderoSpacing.lg,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: LavaderoColors.transparent,
        titleTextStyle: textTheme.titleLarge,
        shape: RoundedRectangleBorder(borderRadius: radiusXl),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: LavaderoColors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(LavaderoRadii.xl),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: LavaderoColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: radiusSm,
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: LavaderoColors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? LavaderoColors.white
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.all(LavaderoColors.transparent),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: LavaderoColors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: radiusMd),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textTheme.labelSmall?.copyWith(
            letterSpacing: 0.2,
            color: s.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: LavaderoSizes.iconLg,
            color: s.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: radiusMd),
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: LavaderoColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusXl),
        headerHeadlineStyle: textTheme.headlineSmall,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: radiusXl),
      ),
    );
  }
}
