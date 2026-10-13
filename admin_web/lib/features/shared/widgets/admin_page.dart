import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// Marco común de las secciones del panel: padding [LavaderoSpacing.xl],
/// contenido centrado y acotado a [LavaderoSizes.contentMaxWidth], una barra
/// de herramientas opcional (filtros a la izquierda, acciones a la derecha) y
/// un cuerpo que ocupa el alto restante (el cuerpo decide si scrollea).
///
/// El título de la sección NO va aquí: lo pinta la barra superior del shell.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.body, this.toolbar, this.banner});

  final Widget body;

  /// Normalmente un [PageToolbar].
  final Widget? toolbar;

  /// Aviso entre la barra y el cuerpo (p. ej. un `ErrorBanner` de una acción).
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LavaderoSpacing.xl,
        LavaderoSpacing.lg,
        LavaderoSpacing.xl,
        0,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: LavaderoSizes.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (toolbar != null) ...[
                toolbar!,
                const SizedBox(height: LavaderoSpacing.lg),
              ],
              if (banner != null) ...[
                banner!,
                const SizedBox(height: LavaderoSpacing.md),
              ],
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de herramientas de una sección: [leading] (filtros, buscador,
/// resumen) a la izquierda y [actions] (acción principal) a la derecha. En
/// angosto, las acciones bajan debajo del contenido.
class PageToolbar extends StatelessWidget {
  const PageToolbar({super.key, this.leading, this.actions = const []});

  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final actionRow = Wrap(
      spacing: LavaderoSpacing.sm,
      runSpacing: LavaderoSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < LavaderoBreakpoints.compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ?leading,
              if (leading != null && actions.isNotEmpty)
                const SizedBox(height: LavaderoSpacing.md),
              if (actions.isNotEmpty) actionRow,
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: leading ?? const SizedBox.shrink(),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: LavaderoSpacing.md),
              actionRow,
            ],
          ],
        );
      },
    );
  }
}

/// Texto de resumen para la izquierda de un [PageToolbar]: una cifra
/// destacada y su contexto ("12 empleados · 3 sin sucursal").
class ToolbarSummary extends StatelessWidget {
  const ToolbarSummary({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: LavaderoTypography.tabular,
            ),
          ),
          TextSpan(
            text: '  $label',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grilla adaptable: tantas columnas como quepan con [minItemWidth] (hasta
/// [maxColumns]) y, por fila, todas las tarjetas con el mismo alto. Cada
/// tarjeta entra escalonada con [FadeSlideIn]. No scrollea por sí misma.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.maxColumns = 4,
    this.spacing = LavaderoSpacing.md,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas =
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor()
                .clamp(1, maxColumns);
        final filas = <Widget>[];
        for (var inicio = 0; inicio < children.length; inicio += columnas) {
          final celdas = <Widget>[];
          for (var c = 0; c < columnas; c++) {
            final i = inicio + c;
            if (c > 0) celdas.add(SizedBox(width: spacing));
            celdas.add(
              Expanded(
                child: i < children.length
                    ? FadeSlideIn(index: i, child: children[i])
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (filas.isNotEmpty) filas.add(SizedBox(height: spacing));
          filas.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: celdas,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: filas,
        );
      },
    );
  }
}

/// Esqueleto de carga para pantallas en grilla de tarjetas.
class CardGridSkeleton extends StatelessWidget {
  const CardGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 180,
    this.minItemWidth = 300,
  });

  final int itemCount;
  final double itemHeight;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ResponsiveGrid(
          minItemWidth: minItemWidth,
          children: [
            for (var i = 0; i < itemCount; i++)
              Skeleton(height: itemHeight, radius: LavaderoRadii.lg),
          ],
        ),
      ),
    );
  }
}
