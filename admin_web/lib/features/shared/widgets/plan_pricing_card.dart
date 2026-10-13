import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// Tarjeta de precio de un [SubscriptionPlan]: nombre, precio mensual, límites y features, con
/// una acción al pie (editar para la plataforma, pagar para el dueño). La variante [destacado]
/// usa el degradado de marca y adapta los colores de la acción para que contraste sobre él.
///
/// Compartida entre `tenant_admin` (catálogo de planes, SUPER_ADMIN) y `subscription` (el dueño
/// elige y paga su plan).
class PlanPricingCard extends StatelessWidget {
  const PlanPricingCard({
    super.key,
    required this.plan,
    this.destacado = false,
    this.etiquetaDestacado = 'Recomendado',
    this.accion,
    this.onTap,
  });

  final SubscriptionPlan plan;
  final bool destacado;
  final String etiquetaDestacado;
  final Widget? accion;
  final VoidCallback? onTap;

  /// Alto del esqueleto de carga de una grilla de planes.
  static const double alturaEsqueleto = 320;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final principal = destacado ? LavaderoColors.white : scheme.onSurface;
    final secundario = destacado
        ? LavaderoColors.onBrandMuted
        : scheme.onSurfaceVariant;
    final acento = destacado ? LavaderoColors.aquaBright : scheme.primary;
    final gratis = plan.precio <= 0;

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.nombre,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(color: principal),
              ),
            ),
            if (destacado)
              GlassPill(
                label: etiquetaDestacado,
                icon: Icons.auto_awesome_rounded,
              ),
          ],
        ),
        const SizedBox(height: LavaderoSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  gratis ? 'Gratis' : Formato.moneda(plan.precio, plan.moneda),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: principal,
                    fontFeatures: LavaderoTypography.tabular,
                  ),
                ),
              ),
            ),
            if (!gratis) ...[
              const SizedBox(width: LavaderoSpacing.xs),
              Text(
                '/ mes',
                style: theme.textTheme.bodyMedium?.copyWith(color: secundario),
              ),
            ],
          ],
        ),
        if (!gratis)
          Text(
            plan.moneda,
            style: theme.textTheme.labelSmall?.copyWith(color: secundario),
          ),
        const SizedBox(height: LavaderoSpacing.md),
        Divider(
          height: LavaderoSizes.hairline,
          color: destacado
              ? LavaderoColors.white.withValues(alpha: 0.2)
              : scheme.outlineVariant,
        ),
        const SizedBox(height: LavaderoSpacing.md),
        _Linea(
          icon: Icons.storefront_outlined,
          texto: plan.maxSucursales == 1
              ? '1 sucursal'
              : 'Hasta ${plan.maxSucursales} sucursales',
          color: principal,
          acento: acento,
        ),
        _Linea(
          icon: Icons.badge_outlined,
          texto: plan.maxEmpleados == 1
              ? '1 empleado'
              : 'Hasta ${plan.maxEmpleados} empleados',
          color: principal,
          acento: acento,
        ),
        for (final feature in plan.features)
          _Linea(
            icon: Icons.check_circle_rounded,
            texto: FeaturePlan.etiqueta(feature),
            color: secundario,
            acento: acento,
          ),
        if (accion != null) ...[
          const Spacer(),
          const SizedBox(height: LavaderoSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: destacado
                ? Theme(
                    data: theme.copyWith(
                      colorScheme: scheme.copyWith(
                        primary: LavaderoColors.white,
                        onPrimary: LavaderoColors.oceanDeep,
                      ),
                    ),
                    child: accion!,
                  )
                : accion!,
          ),
        ],
      ],
    );

    return LavaderoCard(
      onTap: onTap,
      gradient: destacado ? LavaderoGradients.deep : null,
      padding: const EdgeInsets.all(LavaderoSpacing.lg),
      child: contenido,
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({
    required this.icon,
    required this.texto,
    required this.color,
    required this.acento,
  });

  final IconData icon;
  final String texto;
  final Color color;
  final Color acento;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LavaderoSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: LavaderoSizes.iconMd, color: acento),
          const SizedBox(width: LavaderoSpacing.sm + LavaderoSpacing.xxs),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
