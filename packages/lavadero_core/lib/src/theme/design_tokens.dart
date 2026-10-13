import 'package:flutter/material.dart';

/// Identidad "Aqua premium" compartida entre `mobile_app` y `admin_web`:
/// azul océano profundo + turquesa brillante sobre superficies claras y
/// aireadas (o grafito azulado en oscuro). Es el ÚNICO archivo del proyecto
/// donde se permite `Color(0x...)`; las pantallas leen el `ColorScheme` del
/// tema o estos tokens con nombre.
abstract final class LavaderoColors {
  // ── Marca ──────────────────────────────────────────────────────────────
  static const Color ocean = Color(0xFF0B5CFF);
  static const Color oceanBright = Color(0xFF5B8CFF);
  static const Color oceanDeep = Color(0xFF07215C);
  static const Color aqua = Color(0xFF13C8D6);
  static const Color aquaBright = Color(0xFF5EE6EE);

  /// Aqua oscurecido para el extremo de los degradados que llevan texto o
  /// íconos blancos encima: 6:1 contra blanco (el `aqua` de marca da ~2:1 y
  /// no pasa WCAG AA).
  static const Color aquaDeep = Color(0xFF0B6B8A);

  /// Texto secundario SÓLIDO sobre los degradados de marca (en vez de blanco
  /// translúcido, que sobre `ocean` cae por debajo de 4.5:1): ≥4.6:1 en todo
  /// el recorrido de [LavaderoGradients.deep]/[LavaderoGradients.brandStrong].
  static const Color onBrandMuted = Color(0xFFEAF1FF);

  /// Alias históricos (usados por pantallas existentes).
  static const Color primary = ocean;
  static const Color primaryDark = oceanBright;
  static const Color secondary = aqua;

  // ── Semánticos ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF0FA97A);
  static const Color warning = Color(0xFFE8900C);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);

  // ── Neutros claros ─────────────────────────────────────────────────────
  static const Color canvas = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDF2F8);
  static const Color surfaceSunken = Color(0xFFE4EBF4);
  static const Color line = Color(0xFFE2E8F1);
  static const Color lineStrong = Color(0xFFC9D4E3);
  static const Color ink = Color(0xFF0B1B32);
  static const Color inkSecondary = Color(0xFF55657E);
  static const Color inkTertiary = Color(0xFF8796AD);
  static const Color oceanContainer = Color(0xFFE4EDFF);
  static const Color onOceanContainer = Color(0xFF062A78);
  static const Color aquaContainer = Color(0xFFDDF8FA);
  static const Color onAquaContainer = Color(0xFF00525A);
  static const Color errorContainer = Color(0xFFFDE8E8);
  static const Color onErrorContainer = Color(0xFF8A1C20);

  // ── Neutros oscuros ────────────────────────────────────────────────────
  static const Color canvasDark = Color(0xFF060D19);
  static const Color surfaceDark = Color(0xFF0D1727);
  static const Color surfaceMutedDark = Color(0xFF132136);
  static const Color surfaceSunkenDark = Color(0xFF1A2A42);
  static const Color lineDark = Color(0xFF1D2C44);
  static const Color lineStrongDark = Color(0xFF2B3D59);
  static const Color inkDark = Color(0xFFE9F0FA);
  static const Color inkSecondaryDark = Color(0xFF9AABC3);
  static const Color inkTertiaryDark = Color(0xFF6B7C96);
  static const Color oceanContainerDark = Color(0xFF0F2A63);
  static const Color onOceanContainerDark = Color(0xFFD6E3FF);
  static const Color aquaContainerDark = Color(0xFF053C44);
  static const Color onAquaContainerDark = Color(0xFFB8F3F7);
  static const Color errorContainerDark = Color(0xFF4A1416);
  static const Color onErrorContainerDark = Color(0xFFFFD9D9);

  // ── Utilitarios ────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color shadow = Color(0xFF0B1B32);
  static const Color shadowDark = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}

/// Degradados de marca. Usarlos con moderación: héroes, CTA principal y
/// la marca; nunca de fondo en listas o formularios.
///
/// Contraste: [brand] termina en el aqua brillante y es SOLO decorativo
/// (barras, logo, halos sin contenido). Si encima va texto o un ícono
/// blanco, usar [brandStrong] o [deep], que terminan en
/// [LavaderoColors.aquaDeep] (blanco ≥5:1 en todo el recorrido; texto
/// secundario con [LavaderoColors.onBrandMuted]).
abstract final class LavaderoGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LavaderoColors.ocean, LavaderoColors.aqua],
  );

  static const LinearGradient brandStrong = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LavaderoColors.ocean, LavaderoColors.aquaDeep],
  );

  static const LinearGradient deep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      LavaderoColors.oceanDeep,
      LavaderoColors.ocean,
      LavaderoColors.aquaDeep,
    ],
    stops: [0, 0.55, 1],
  );
}

/// Sombras difusas (no la elevación dura de Material): dan profundidad sin
/// ensuciar. En oscuro casi no se ven; ahí la separación la da el borde.
abstract final class LavaderoShadows {
  static List<BoxShadow> soft(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.light
          ? LavaderoColors.shadow.withValues(alpha: 0.06)
          : LavaderoColors.shadowDark.withValues(alpha: 0.30),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: brightness == Brightness.light
          ? LavaderoColors.shadow.withValues(alpha: 0.04)
          : LavaderoColors.shadowDark.withValues(alpha: 0.20),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.32),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Espaciado base (múltiplos de 4dp) para paddings/gaps consistentes.
abstract final class LavaderoSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;

  /// 12: entre `sm` y `md` (antes se escribía `sm + xs` por todos lados).
  static const double smd = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Radios de borde estándar.
abstract final class LavaderoRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;

  /// Redondeo total — pills/badges/chips.
  static const double full = 999;
}

/// Tamaños con nombre (anchos máximos, alturas de control, íconos) para no
/// repartir números mágicos por las pantallas.
abstract final class LavaderoSizes {
  static const double controlHeight = 52;
  static const double controlHeightSm = 40;

  /// Área táctil mínima (Material/WCAG 2.5.8): ningún control tocable en
  /// móvil por debajo de esto, aunque se vea más compacto.
  static const double minTapTarget = 48;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double dialogWidth = 440;
  static const double formMaxWidth = 420;
  static const double contentMaxWidth = 1200;
  static const double sidebarWidth = 248;
  static const double sidebarCollapsedWidth = 76;

  /// Grosor de líneas divisorias explícitas (`Divider(height: hairline)`).
  static const double hairline = 1;

  /// Trazo de los spinners chicos en línea (ver `InlineSpinner`).
  static const double spinnerStroke = 2;

  /// Halo del ícono de `EmptyState` y su ancho máximo de texto.
  static const double emptyStateIcon = 88;
  static const double emptyStateMaxWidth = 360;

  /// Alto mínimo de un `EmptyState` embebido en una lista/tarjeta.
  static const double emptyStateMinHeight = 280;

  /// Alto de la cabecera de marca de `AuthLayout` en móvil.
  static const double authHeaderHeight = 220;

  /// Logo: rail compacto / barra lateral / auth / héroes / splash.
  static const double logoSm = 34;
  static const double logoMd = 40;
  static const double logoLg = 56;
  static const double logoXl = 72;

  /// Esqueletos de carga del resumen de ventas (dashboard y reportes).
  static const double skeletonKpiHeight = 150;
  static const double skeletonKpiWidth = 260;
  static const double skeletonPanelHeight = 240;
}

/// Anchos a partir de los cuales cambia el layout.
abstract final class LavaderoBreakpoints {
  /// Barras de herramientas y filas que bajan sus acciones debajo.
  static const double compact = 720;

  /// `AuthLayout`: panel de marca + formulario lado a lado.
  static const double authWide = 900;

  /// KPIs del resumen de ventas: 2 columnas desde aquí, 4 desde [kpis4].
  static const double kpis2 = 560;
  static const double kpis4 = 1000;

  /// Shell de `admin_web`: barra lateral completa (debajo, rail de íconos).
  static const double shellWide = 1100;
}

/// Duraciones y curvas: movimiento corto y con desaceleración, nunca rebotes.
abstract final class LavaderoMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 45);

  /// Un recorrido del brillo de los esqueletos de carga.
  static const Duration shimmer = Duration(milliseconds: 1400);
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
}

/// Jerarquía tipográfica sobre Plus Jakarta Sans (empaquetada en
/// `lavadero_core/assets/fonts`, OFL). Titulares compactos y pesados,
/// cuerpo con aire; las cifras usan dígitos tabulares para que montos y
/// horas no "bailen" al cambiar.
abstract final class LavaderoTypography {
  static const String fontFamily = 'packages/lavadero_core/PlusJakartaSans';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextTheme apply(TextTheme base) {
    TextStyle? tight(TextStyle? s, FontWeight w, double tracking) =>
        s?.copyWith(fontWeight: w, letterSpacing: tracking, height: 1.15);

    return base
        .copyWith(
          displayLarge: tight(base.displayLarge, FontWeight.w800, -1.5),
          displayMedium: tight(base.displayMedium, FontWeight.w800, -1.2),
          displaySmall: tight(base.displaySmall, FontWeight.w800, -0.9),
          headlineLarge: tight(base.headlineLarge, FontWeight.w800, -0.8),
          headlineMedium: tight(base.headlineMedium, FontWeight.w700, -0.6),
          headlineSmall: tight(base.headlineSmall, FontWeight.w700, -0.4),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
          bodySmall: base.bodySmall?.copyWith(height: 1.45),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        )
        .apply(fontFamily: fontFamily);
  }
}
